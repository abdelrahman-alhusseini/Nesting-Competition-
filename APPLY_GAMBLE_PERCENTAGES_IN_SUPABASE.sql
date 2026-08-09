-- Adds configurable +4 / -6 probabilities for the even-number gamble.
-- Safe to run on an existing V13 database.

alter table public.game_settings
  add column if not exists gamble_plus_four_chance numeric(5,4) not null default 0.50,
  add column if not exists gamble_minus_six_chance numeric(5,4) not null default 0.50;

alter table public.game_settings
  drop constraint if exists game_settings_gamble_plus_four_chance_check,
  drop constraint if exists game_settings_gamble_minus_six_chance_check;

alter table public.game_settings
  add constraint game_settings_gamble_plus_four_chance_check
    check (gamble_plus_four_chance between 0 and 1),
  add constraint game_settings_gamble_minus_six_chance_check
    check (gamble_minus_six_chance between 0 and 1);

create or replace function public.resolve_even_card(
  p_card_draw_id uuid,
  p_gamble boolean
)
returns table (
  card_draw_id uuid,
  title text,
  description text,
  tone text,
  points integer,
  number integer,
  can_gamble boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_draw public.card_draws%rowtype;
  v_points integer;
  v_title text;
  v_description text;
  v_tone text;
  v_gamble_plus numeric := 0.50;
  v_gamble_minus numeric := 0.50;
  v_gamble_total numeric := 1.00;
begin
  select * into v_draw
  from public.card_draws
  where id = p_card_draw_id
  for update;

  if not found then raise exception 'Card draw not found'; end if;
  if v_draw.agent_id <> (select auth.uid()) then raise exception 'This card does not belong to you'; end if;
  if v_draw.status <> 'pending_choice' or not v_draw.can_gamble then
    raise exception 'This card is not waiting for an even-number choice';
  end if;

  select gamble_plus_four_chance, gamble_minus_six_chance
  into v_gamble_plus, v_gamble_minus
  from public.game_settings
  where competition_id = v_draw.competition_id;

  v_gamble_total := coalesce(v_gamble_plus, 0.50) + coalesce(v_gamble_minus, 0.50);
  if v_gamble_total <= 0 then
    v_gamble_plus := 0.50;
    v_gamble_total := 1.00;
  end if;

  if not p_gamble then
    v_points := 1;
    v_title := '+1 Point';
    v_description := 'You kept the guaranteed point.';
    v_tone := 'positive';
  elsif random() < (coalesce(v_gamble_plus, 0.50) / v_gamble_total) then
    v_points := 4;
    v_title := '+4 Points';
    v_description := 'The gamble paid off.';
    v_tone := 'positive';
  else
    v_points := -6;
    v_title := '-6 Points';
    v_description := 'The gamble did not go your way.';
    v_tone := 'negative';
  end if;

  update public.card_draws
  set title = v_title,
      description = v_description,
      tone = v_tone,
      points_delta = v_points,
      can_gamble = false,
      status = 'applied',
      resolved_at = now()
  where id = v_draw.id;

  insert into public.score_transactions (
    competition_id, agent_id, delta, reason, source_type, source_id, actor_id
  ) values (
    v_draw.competition_id,
    v_draw.agent_id,
    v_points,
    v_title,
    'card_draw',
    v_draw.id,
    v_draw.agent_id
  );

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_draw.competition_id,
    v_draw.agent_id,
    'even_card_resolved',
    format('A player resolved an even-number card and received %s.', v_title),
    true,
    jsonb_build_object('card_draw_id', v_draw.id, 'points', v_points, 'gambled', p_gamble)
  );

  return query select v_draw.id, v_title, v_description, v_tone, v_points, v_draw.card_number, false;
end;
$$;

grant execute on function public.resolve_even_card(uuid, boolean) to authenticated;
