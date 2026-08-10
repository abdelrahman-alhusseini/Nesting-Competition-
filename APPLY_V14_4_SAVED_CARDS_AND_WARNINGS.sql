-- V14.4: allow up to 3 saved special cards without discarding a newly drawn card.
-- Existing users keep all currently active cards; the configured maximum is set to 3.

alter table public.game_settings
  alter column max_saved_special_cards set default 3;

update public.game_settings
set max_saved_special_cards = 3
where max_saved_special_cards is distinct from 3;

-- V14.3 inherited the original one-active-card unique index. Remove it so a user
-- can hold multiple active cards, and replace it with a normal lookup index.
drop index if exists public.one_active_special_card_per_user;
create index if not exists saved_special_cards_active_owner_idx
  on public.saved_special_cards(competition_id, owner_id, created_at)
  where status = 'active';

create or replace function public.save_special_card(
  p_card_draw_id uuid,
  p_replace_existing boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_draw public.card_draws%rowtype;
  v_expiry integer;
  v_saved_id uuid;
  v_active_count integer;
  v_max integer := 3;
begin
  select * into v_draw
  from public.card_draws
  where id = p_card_draw_id
  for update;

  if not found then raise exception 'Card draw not found'; end if;
  if v_draw.agent_id <> (select auth.uid()) then raise exception 'This card does not belong to you'; end if;
  if not v_draw.is_special or v_draw.status <> 'awaiting_storage' then
    raise exception 'This special card is not available to save';
  end if;

  select least(coalesce(max_saved_special_cards, 3), 3), special_expiry_bookings
  into v_max, v_expiry
  from public.game_settings
  where competition_id = v_draw.competition_id;

  v_max := greatest(coalesce(v_max, 3), 1);

  select count(*)::integer into v_active_count
  from public.saved_special_cards
  where competition_id = v_draw.competition_id
    and owner_id = v_draw.agent_id
    and status = 'active';

  if v_active_count >= v_max then
    -- IMPORTANT: do not change the card_draw status here. It stays awaiting_storage,
    -- so the user can use a saved card, free a slot, and then save this same draw.
    raise exception 'You already have % saved special cards. Use one before saving this card. Your newly drawn special card is safe and has NOT been discarded.', v_max;
  end if;

  insert into public.saved_special_cards (
    competition_id, owner_id, card_draw_id, card_code, metadata, bookings_remaining
  ) values (
    v_draw.competition_id,
    v_draw.agent_id,
    v_draw.id,
    v_draw.card_code,
    jsonb_build_object('title', v_draw.title, 'description', v_draw.description),
    coalesce(v_expiry, 5)
  ) returning id into v_saved_id;

  update public.card_draws
  set status = 'stored', resolved_at = now()
  where id = v_draw.id;

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_draw.competition_id,
    v_draw.agent_id,
    'special_card_saved',
    'A player saved a special card for later use.',
    true,
    jsonb_build_object('saved_card_id', v_saved_id, 'card_code', v_draw.card_code)
  );

  return v_saved_id;
end;
$$;

grant execute on function public.save_special_card(uuid, boolean) to authenticated;
notify pgrst, 'reload schema';
