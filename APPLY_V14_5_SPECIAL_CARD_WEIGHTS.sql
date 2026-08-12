-- V14.5: weighted special-card rarity by booking type
-- Safe live-database patch for the existing V14.4 schema.
--
-- IMPORTANT:
-- These percentages are conditional on a booking already winning the special-card roll.
-- The existing per-booking-type special chance in public.game_settings is unchanged.
--
-- Move Another Player Down 2 weights requested:
--   Normal:                  3%
--   Cross-Sell:             35%
--   Due Inspection:         12%
--   Restoration:            12%
--   Remodeling Cross-Sell:  80%
--
-- The remaining weight preserves the existing pools as evenly as possible.
-- Remodeling now includes Move Another Player Down 2 in addition to its existing
-- premium cards; its remaining 20% is split across Transfer 5, Rank Swap,
-- and Double Promotion.

create table if not exists public.special_card_weights (
  competition_id uuid not null references public.competitions(id) on delete cascade,
  booking_type public.booking_type not null,
  card_code text not null,
  weight numeric(8,4) not null,
  is_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (competition_id, booking_type, card_code),
  constraint special_card_weights_nonnegative check (weight >= 0),
  constraint special_card_weights_reasonable check (weight <= 100)
);

create index if not exists special_card_weights_lookup_idx
  on public.special_card_weights(competition_id, booking_type, is_enabled);

alter table public.special_card_weights enable row level security;

drop policy if exists special_card_weights_read_authenticated on public.special_card_weights;
create policy special_card_weights_read_authenticated
on public.special_card_weights
for select
to authenticated
using (true);

insert into public.special_card_weights (
  competition_id,
  booking_type,
  card_code,
  weight,
  is_enabled,
  updated_at
)
select
  c.id,
  x.booking_type::public.booking_type,
  x.card_code,
  x.weight,
  true,
  now()
from public.competitions c
cross join (
  values
    ('normal', 'move_self_up_2', 48.5000::numeric),
    ('normal', 'move_player_2',   3.0000::numeric),
    ('normal', 'shield',         48.5000::numeric),
    ('cross_sell', 'move_self_up_2', 32.5000::numeric),
    ('cross_sell', 'move_player_2',  35.0000::numeric),
    ('cross_sell', 'shield',         32.5000::numeric),
    ('due_inspection', 'move_self_up_2', 44.0000::numeric),
    ('due_inspection', 'move_player_2',  12.0000::numeric),
    ('due_inspection', 'shield',         44.0000::numeric),
    ('restoration', 'move_self_up_2', 44.0000::numeric),
    ('restoration', 'move_player_2',  12.0000::numeric),
    ('restoration', 'shield',         44.0000::numeric),
    ('remodeling_cross_sell', 'move_player_2',      80.0000::numeric),
    ('remodeling_cross_sell', 'transfer_5_points',   6.6667::numeric),
    ('remodeling_cross_sell', 'rank_swap_5_limit',   6.6666::numeric),
    ('remodeling_cross_sell', 'double_promotion',    6.6667::numeric)
) as x(booking_type, card_code, weight)
on conflict (competition_id, booking_type, card_code)
do update set
  weight = excluded.weight,
  is_enabled = excluded.is_enabled,
  updated_at = now();

create or replace function public.draw_card(p_pending_draw_id uuid)
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
  v_user_id uuid := (select auth.uid());
  v_pending public.pending_draws%rowtype;
  v_settings public.game_settings%rowtype;
  v_special_chance numeric;
  v_roll numeric;
  v_number integer;
  v_card_code text;
  v_title text;
  v_description text;
  v_tone text;
  v_points integer := 0;
  v_can_gamble boolean := false;
  v_is_special boolean := false;
  v_status public.card_draw_status;
  v_card_draw_id uuid;
  v_special_pick integer;
  v_special_pool_roll numeric;
  v_selected_special_weight numeric;
begin
  select * into v_pending
  from public.pending_draws
  where id = p_pending_draw_id
  for update;

  if not found then raise exception 'Pending draw not found'; end if;
  if v_pending.agent_id <> v_user_id then raise exception 'This draw does not belong to you'; end if;
  if v_pending.status <> 'pending' then raise exception 'This draw is no longer available'; end if;
  if v_pending.expires_at <= now() then raise exception 'This draw expired after 24 hours'; end if;

  select * into v_settings
  from public.game_settings
  where competition_id = v_pending.competition_id;

  v_special_chance := case v_pending.booking_type
    when 'normal' then v_settings.normal_special_chance
    when 'cross_sell' then v_settings.cross_sell_special_chance
    when 'remodeling_cross_sell' then v_settings.remodeling_special_chance
    when 'due_inspection' then v_settings.due_inspection_special_chance
    when 'restoration' then v_settings.restoration_special_chance
  end;

  if random() < v_special_chance then
    v_is_special := true;
    v_tone := 'special';
    v_status := 'awaiting_storage';
    v_special_pool_roll := random();

    with weighted as (
      select
        scw.card_code,
        scw.weight,
        sum(scw.weight) over (order by scw.card_code) as cumulative_weight,
        sum(scw.weight) over () as total_weight
      from public.special_card_weights scw
      where scw.competition_id = v_pending.competition_id
        and scw.booking_type = v_pending.booking_type
        and scw.is_enabled = true
        and scw.weight > 0
    )
    select w.card_code, w.weight
    into v_card_code, v_selected_special_weight
    from weighted w
    where v_special_pool_roll * w.total_weight < w.cumulative_weight
    order by w.cumulative_weight
    limit 1;

    if v_card_code is null then
      v_special_pick := floor(random() * 3)::integer;
      if v_pending.booking_type = 'remodeling_cross_sell' then
        if v_special_pick = 0 then
          v_card_code := 'transfer_5_points';
        elsif v_special_pick = 1 then
          v_card_code := 'rank_swap_5_limit';
        else
          v_card_code := 'double_promotion';
        end if;
      else
        if v_special_pick = 0 then
          v_card_code := 'move_self_up_2';
        elsif v_special_pick = 1 then
          v_card_code := 'move_player_2';
        else
          v_card_code := 'shield';
        end if;
      end if;
    end if;

    case v_card_code
      when 'move_self_up_2' then
        v_title := 'Move Yourself Up 2 Ranks';
        v_description := 'Gain exactly enough points to move up two positions.';
      when 'move_player_2' then
        v_title := 'Move Another Player Down 2 Ranks';
        v_description := 'Choose another player and knock them down two leaderboard positions.';
      when 'shield' then
        v_title := 'Shield';
        v_description := 'Block your next negative card, gamble loss, or special-card attack.';
      when 'transfer_5_points' then
        v_title := 'Transfer 5 Points';
        v_description := 'Take five points from one selected agent and add them to your score.';
      when 'rank_swap_5_limit' then
        v_title := 'Rank Swap';
        v_description := 'Swap with a player no more than five ranks above you.';
      when 'double_promotion' then
        v_title := 'Double Promotion';
        v_description := 'Move yourself up exactly two leaderboard positions.';
      else
        raise exception 'Unsupported special card code: %', v_card_code;
    end case;
  else
    v_roll := random();
    if v_roll < v_settings.number_pool_chance then
      v_number := floor(random() * 10)::integer;
      v_card_code := 'number_' || v_number;
      if v_number = 7 then
        v_title := 'Lucky 7: +3 Points';
        v_description := 'Seven awards three points instead of one.';
        v_tone := 'positive';
        v_points := 3;
        v_status := 'applied';
      elsif mod(v_number, 2) = 0 then
        v_title := 'Even Number: ' || v_number;
        v_description := 'Keep +1 or take the risk for +4 or -6.';
        v_tone := 'neutral';
        v_points := 0;
        v_can_gamble := true;
        v_status := 'pending_choice';
      else
        v_title := 'Number ' || v_number || ': +1 Point';
        v_description := 'A standard number card.';
        v_tone := 'positive';
        v_points := 1;
        v_status := 'applied';
      end if;
    elsif v_roll < v_settings.number_pool_chance + v_settings.plus_two_chance then
      v_card_code := 'plus_2';
      v_title := '+2 Points';
      v_description := 'Two points were awarded.';
      v_tone := 'positive';
      v_points := 2;
      v_status := 'applied';
    elsif v_roll < v_settings.number_pool_chance + v_settings.plus_two_chance + v_settings.plus_four_chance then
      v_card_code := 'plus_4';
      v_title := '+4 Points';
      v_description := 'Four points were awarded.';
      v_tone := 'positive';
      v_points := 4;
      v_status := 'applied';
    elsif v_roll < v_settings.number_pool_chance + v_settings.plus_two_chance + v_settings.plus_four_chance + v_settings.reverse_chance then
      v_card_code := 'reverse';
      v_title := 'Reverse: -1 Point';
      v_description := 'Reverse removes one point.';
      v_tone := 'negative';
      v_points := -1;
      v_status := 'applied';
    else
      v_card_code := 'skip';
      v_title := 'Skip';
      v_description := 'No points were added or removed.';
      v_tone := 'neutral';
      v_points := 0;
      v_status := 'applied';
    end if;
  end if;

  if v_status = 'applied' and v_points < 0
     and public.consume_shield_if_available(v_pending.agent_id, v_pending.competition_id, v_title) then
    v_title := 'Shield Blocked ' || v_title;
    v_description := 'Your active Shield blocked this negative card.';
    v_tone := 'neutral';
    v_points := 0;
  end if;

  insert into public.card_draws (
    pending_draw_id, competition_id, agent_id, booking_type,
    card_code, title, description, tone, card_number,
    points_delta, can_gamble, is_special, status, metadata,
    resolved_at
  ) values (
    v_pending.id, v_pending.competition_id, v_pending.agent_id, v_pending.booking_type,
    v_card_code, v_title, v_description, v_tone, v_number,
    v_points, v_can_gamble, v_is_special, v_status,
    jsonb_build_object(
      'title', v_title,
      'description', v_description,
      'special_pool_roll', case when v_is_special then v_special_pool_roll else null end,
      'special_card_weight', case when v_is_special then v_selected_special_weight else null end
    ),
    case when v_status = 'applied' then now() else null end
  ) returning id into v_card_draw_id;

  update public.pending_draws
  set status = 'drawn', drawn_at = now()
  where id = v_pending.id;

  if v_status = 'applied' and v_points <> 0 then
    insert into public.score_transactions (
      competition_id, agent_id, delta, reason, source_type, source_id, actor_id
    ) values (
      v_pending.competition_id,
      v_pending.agent_id,
      v_points,
      v_title,
      'card_draw',
      v_card_draw_id,
      v_pending.agent_id
    );
  end if;

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_pending.competition_id,
    v_pending.agent_id,
    case when v_is_special then 'special_card_drawn' else 'card_drawn' end,
    case when v_is_special
      then 'A player drew a special card.'
      else format('A player drew %s.', v_title)
    end,
    true,
    jsonb_build_object(
      'card_draw_id', v_card_draw_id,
      'card_code', v_card_code,
      'points', v_points,
      'booking_type', v_pending.booking_type,
      'special_card_weight', case when v_is_special then v_selected_special_weight else null end
    )
  );

  return query select v_card_draw_id, v_title, v_description, v_tone, v_points, v_number, v_can_gamble;
end;
$$;

grant execute on function public.draw_card(uuid) to authenticated;
notify pgrst, 'reload schema';

select
  c.name as competition,
  scw.booking_type,
  scw.card_code,
  scw.weight,
  sum(scw.weight) over (
    partition by scw.competition_id, scw.booking_type
  ) as pool_total
from public.special_card_weights scw
join public.competitions c on c.id = scw.competition_id
where c.status = 'active'
order by scw.booking_type, scw.weight desc, scw.card_code;
