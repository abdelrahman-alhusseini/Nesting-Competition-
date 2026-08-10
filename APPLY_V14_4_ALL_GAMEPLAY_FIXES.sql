-- V14.3 major gameplay fixes
-- 1) Pending draws no longer get discarded because of a count limit.
--    Every pending draw remains available for 24 hours from creation.
-- 2) Adds one-use Shield protection.
-- 3) Adds a live special-card use RPC with optional target selection.
-- 4) Shield blocks the next targeted special-card attack or negative card/gamble effect.

alter table public.pending_draws
  add column if not exists expires_at timestamptz;

update public.pending_draws
set expires_at = created_at + interval '24 hours'
where expires_at is null;

alter table public.pending_draws
  alter column expires_at set default (now() + interval '24 hours'),
  alter column expires_at set not null;

create index if not exists pending_draws_status_expiry_idx
  on public.pending_draws(status, expires_at);

alter table public.competition_members
  add column if not exists shield_charges integer not null default 0;

alter table public.competition_members
  drop constraint if exists competition_members_shield_charges_check;

alter table public.competition_members
  add constraint competition_members_shield_charges_check
  check (shield_charges >= 0);

create or replace function public.expire_stale_pending_draws(
  p_agent_id uuid,
  p_competition_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expired record;
begin
  for v_expired in
    select id
    from public.pending_draws
    where agent_id = p_agent_id
      and competition_id = p_competition_id
      and status = 'pending'
      and expires_at <= now()
    order by expires_at asc
    for update
  loop
    update public.pending_draws
    set status = 'expired', expired_at = now()
    where id = v_expired.id
      and status = 'pending';

    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      p_competition_id,
      p_agent_id,
      'pending_draw_expired',
      'A pending card draw expired after 24 hours.',
      false,
      jsonb_build_object('pending_draw_id', v_expired.id)
    );
  end loop;
end;
$$;

-- Keep the old helper name safe for any older client/function call, but remove
-- the old count-based discard behavior completely.
create or replace function public.expire_oldest_pending_draws(
  p_agent_id uuid,
  p_competition_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.expire_stale_pending_draws(p_agent_id, p_competition_id);
end;
$$;

create or replace function public.expire_my_pending_draws()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_competition_id uuid := public.active_competition_id();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;
  if v_competition_id is null then
    return;
  end if;
  perform public.expire_stale_pending_draws(v_user_id, v_competition_id);
end;
$$;

create or replace function public.get_my_shield_charges()
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select cm.shield_charges
    from public.competition_members cm
    where cm.user_id = (select auth.uid())
      and cm.competition_id = public.active_competition_id()
    limit 1
  ), 0);
$$;

create or replace function public.consume_shield_if_available(
  p_agent_id uuid,
  p_competition_id uuid,
  p_reason text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_consumed boolean := false;
begin
  update public.competition_members
  set shield_charges = shield_charges - 1
  where competition_id = p_competition_id
    and user_id = p_agent_id
    and shield_charges > 0
  returning true into v_consumed;

  if coalesce(v_consumed, false) then
    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      p_competition_id,
      p_agent_id,
      'shield_triggered',
      'A player''s Shield blocked a negative effect.',
      true,
      jsonb_build_object('reason', coalesce(p_reason, 'negative effect'))
    );
  end if;

  return coalesce(v_consumed, false);
end;
$$;

create or replace function public.review_booking(
  p_booking_id uuid,
  p_approve boolean,
  p_corrected_type text,
  p_rejection_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_type public.booking_type;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  select * into v_booking
  from public.bookings
  where id = p_booking_id
  for update;

  if not found then raise exception 'Booking not found'; end if;
  if v_booking.status <> 'pending' then raise exception 'This booking has already been reviewed'; end if;

  begin
    v_type := p_corrected_type::public.booking_type;
  exception when invalid_text_representation then
    raise exception 'Invalid booking type';
  end;

  if p_approve then
    update public.bookings
    set status = 'approved',
        booking_type = v_type,
        reviewed_by = (select auth.uid()),
        reviewed_at = now(),
        rejection_reason = null
    where id = p_booking_id;

    perform public.decrement_saved_card_expiry(v_booking.agent_id, v_booking.competition_id);
    perform public.expire_stale_pending_draws(v_booking.agent_id, v_booking.competition_id);

    insert into public.pending_draws (
      competition_id, agent_id, booking_id, booking_type, granted_by, expires_at
    ) values (
      v_booking.competition_id,
      v_booking.agent_id,
      v_booking.id,
      v_type,
      (select auth.uid()),
      now() + interval '24 hours'
    );

    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      v_booking.competition_id,
      v_booking.agent_id,
      'booking_approved',
      'A booking was approved and one card draw was granted.',
      true,
      jsonb_build_object('booking_id', v_booking.id, 'booking_type', v_type, 'job_id', v_booking.job_id)
    );
  else
    update public.bookings
    set status = 'rejected',
        booking_type = v_type,
        reviewed_by = (select auth.uid()),
        reviewed_at = now(),
        rejection_reason = coalesce(nullif(trim(p_rejection_reason), ''), 'Rejected by admin')
    where id = p_booking_id;

    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      v_booking.competition_id,
      v_booking.agent_id,
      'booking_rejected',
      'A submitted booking was rejected by an admin.',
      true,
      jsonb_build_object('booking_id', v_booking.id, 'job_id', v_booking.job_id)
    );
  end if;

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    (select auth.uid()),
    case when p_approve then 'booking_approved' else 'booking_rejected' end,
    'booking',
    v_booking.id,
    jsonb_build_object(
      'agent_id', v_booking.agent_id,
      'corrected_type', v_type,
      'rejection_reason', p_rejection_reason
    )
  );
end;
$$;

create or replace function public.manual_grant_draw(
  p_agent_id uuid,
  p_booking_type text,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_competition_id uuid := public.active_competition_id();
  v_type public.booking_type;
  v_draw_id uuid;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if not exists (select 1 from public.profiles where id = p_agent_id and role = 'agent' and is_active = true) then
    raise exception 'Agent not found or inactive';
  end if;

  v_type := p_booking_type::public.booking_type;
  perform public.expire_stale_pending_draws(p_agent_id, v_competition_id);

  insert into public.pending_draws (
    competition_id, agent_id, booking_type, is_manual, manual_reason, granted_by, expires_at
  ) values (
    v_competition_id,
    p_agent_id,
    v_type,
    true,
    nullif(trim(p_reason), ''),
    (select auth.uid()),
    now() + interval '24 hours'
  ) returning id into v_draw_id;

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_competition_id,
    p_agent_id,
    'manual_draw_granted',
    'An admin granted a manual card draw.',
    true,
    jsonb_build_object('pending_draw_id', v_draw_id, 'booking_type', v_type, 'reason', p_reason)
  );

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    (select auth.uid()),
    'manual_draw_granted',
    'pending_draw',
    v_draw_id,
    jsonb_build_object('agent_id', p_agent_id, 'booking_type', v_type, 'reason', p_reason)
  );

  return v_draw_id;
end;
$$;

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
    v_special_pick := floor(random() * 3)::integer;

    if v_pending.booking_type = 'remodeling_cross_sell' then
      if v_special_pick = 0 then
        v_card_code := 'transfer_5_points';
        v_title := 'Transfer 5 Points';
        v_description := 'Take five points from one selected agent and add them to your score.';
      elsif v_special_pick = 1 then
        v_card_code := 'rank_swap_5_limit';
        v_title := 'Rank Swap';
        v_description := 'Swap with a player no more than five ranks above you.';
      else
        v_card_code := 'double_promotion';
        v_title := 'Double Promotion';
        v_description := 'Move yourself up exactly two leaderboard positions.';
      end if;
    else
      if v_special_pick = 0 then
        v_card_code := 'move_self_up_2';
        v_title := 'Move Yourself Up 2 Ranks';
        v_description := 'Gain exactly enough points to move up two positions.';
      elsif v_special_pick = 1 then
        v_card_code := 'move_player_2';
        v_title := 'Move Another Player Down 2 Ranks';
        v_description := 'Choose another player and knock them down two leaderboard positions.';
      else
        v_card_code := 'shield';
        v_title := 'Shield';
        v_description := 'Block your next negative card, gamble loss, or special-card attack.';
      end if;
    end if;
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
    jsonb_build_object('title', v_title, 'description', v_description),
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
    jsonb_build_object('card_draw_id', v_card_draw_id, 'card_code', v_card_code, 'points', v_points)
  );

  return query select v_card_draw_id, v_title, v_description, v_tone, v_points, v_number, v_can_gamble;
end;
$$;

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

  if v_points < 0
     and public.consume_shield_if_available(v_draw.agent_id, v_draw.competition_id, v_title) then
    v_points := 0;
    v_title := 'Shield Blocked -6';
    v_description := 'Your active Shield protected you from the gamble loss.';
    v_tone := 'neutral';
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

  if v_points <> 0 then
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
  end if;

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

create or replace function public.use_special_card(
  p_saved_card_id uuid,
  p_target_id uuid default null
)
returns table (
  message text,
  shield_blocked boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_actor_id uuid := (select auth.uid());
  v_card public.saved_special_cards%rowtype;
  v_actor_rank integer;
  v_actor_score integer;
  v_target_rank integer;
  v_target_score integer;
  v_destination_rank integer;
  v_destination_score integer;
  v_total integer;
  v_delta integer;
  v_actor_delta integer;
  v_target_delta integer;
  v_target_name text;
  v_message text;
  v_blocked boolean := false;
  v_points_transferred integer := 0;
begin
  select * into v_card
  from public.saved_special_cards
  where id = p_saved_card_id
  for update;

  if not found then raise exception 'Saved special card not found'; end if;
  if v_card.owner_id <> v_actor_id then raise exception 'This special card does not belong to you'; end if;
  if v_card.status <> 'active' then raise exception 'This special card is no longer active'; end if;

  if v_card.card_code in ('move_player_2', 'transfer_5_points', 'rank_swap_5_limit') then
    if p_target_id is null then raise exception 'Choose a player first'; end if;
    if p_target_id = v_actor_id then raise exception 'Choose another player'; end if;

    select p.display_name into v_target_name
    from public.profiles p
    join public.competition_members cm
      on cm.user_id = p.id and cm.competition_id = v_card.competition_id
    where p.id = p_target_id
      and p.role = 'agent'
      and p.is_active = true
      and cm.is_active = true;

    if not found then raise exception 'Selected player is not available'; end if;
  end if;

  if v_card.card_code = 'shield' then
    if exists (
      select 1 from public.competition_members
      where competition_id = v_card.competition_id
        and user_id = v_actor_id
        and shield_charges > 0
    ) then
      raise exception 'Your Shield is already active';
    end if;

    update public.competition_members
    set shield_charges = 1
    where competition_id = v_card.competition_id
      and user_id = v_actor_id;

    v_message := 'Shield activated. Your next negative card, gamble loss, or special-card attack will be blocked.';

    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      v_card.competition_id,
      v_actor_id,
      'shield_activated',
      'A player activated a Shield.',
      true,
      jsonb_build_object('saved_card_id', v_card.id)
    );

  elsif v_card.card_code in ('move_self_up_2', 'double_promotion') then
    select rank, score into v_actor_rank, v_actor_score
    from public.leaderboard
    where user_id = v_actor_id;

    if v_actor_rank is null then raise exception 'You are not on the leaderboard'; end if;
    if v_actor_rank <= 1 then raise exception 'You are already at the top of the leaderboard'; end if;

    v_destination_rank := greatest(v_actor_rank - 2, 1);
    select score into v_destination_score
    from public.leaderboard
    where rank = v_destination_rank;

    v_delta := greatest(coalesce(v_destination_score, v_actor_score) + 1 - v_actor_score, 1);

    insert into public.score_transactions (
      competition_id, agent_id, delta, reason, source_type, source_id, actor_id
    ) values (
      v_card.competition_id,
      v_actor_id,
      v_delta,
      case when v_card.card_code = 'double_promotion' then 'Double Promotion' else 'Move Yourself Up 2 Ranks' end,
      'special_card',
      v_card.id,
      v_actor_id
    );

    v_message := format('Special card used: you moved from rank #%s toward rank #%s.', v_actor_rank, v_destination_rank);

  elsif v_card.card_code = 'move_player_2' then
    if public.consume_shield_if_available(p_target_id, v_card.competition_id, 'Move Another Player Down 2 Ranks') then
      v_blocked := true;
      v_message := format('%s''s Shield blocked your rank attack.', v_target_name);
    else
      select rank, score into v_target_rank, v_target_score
      from public.leaderboard
      where user_id = p_target_id;

      select count(*)::integer into v_total from public.leaderboard;
      if v_target_rank is null then raise exception 'Selected player is not on the leaderboard'; end if;
      if v_target_rank >= v_total then raise exception 'That player is already at the bottom of the leaderboard'; end if;

      v_destination_rank := least(v_total, v_target_rank + 2);
      select score into v_destination_score
      from public.leaderboard
      where rank = v_destination_rank;

      v_delta := (coalesce(v_destination_score, v_target_score) - 1) - v_target_score;
      if v_delta >= 0 then v_delta := -1; end if;

      insert into public.score_transactions (
        competition_id, agent_id, delta, reason, source_type, source_id, actor_id
      ) values (
        v_card.competition_id,
        p_target_id,
        v_delta,
        'Hit by Move Down 2 Ranks special card',
        'special_card',
        v_card.id,
        v_actor_id
      );

      v_message := format('You used Move Down 2 Ranks on %s.', v_target_name);
    end if;

  elsif v_card.card_code = 'transfer_5_points' then
    if public.consume_shield_if_available(p_target_id, v_card.competition_id, 'Transfer 5 Points') then
      v_blocked := true;
      v_message := format('%s''s Shield blocked your Transfer 5 Points card.', v_target_name);
    else
      insert into public.score_transactions (
        competition_id, agent_id, delta, reason, source_type, source_id, actor_id
      ) values
        (v_card.competition_id, p_target_id, -5, 'Lost 5 points to a Transfer card', 'special_card', v_card.id, v_actor_id),
        (v_card.competition_id, v_actor_id, 5, 'Gained 5 points from a Transfer card', 'special_card', v_card.id, v_actor_id);
      v_points_transferred := 5;
      v_message := format('You took 5 points from %s.', v_target_name);
    end if;

  elsif v_card.card_code = 'rank_swap_5_limit' then
    select rank, score into v_actor_rank, v_actor_score
    from public.leaderboard where user_id = v_actor_id;
    select rank, score into v_target_rank, v_target_score
    from public.leaderboard where user_id = p_target_id;

    if v_actor_rank is null or v_target_rank is null then raise exception 'Both players must be on the leaderboard'; end if;
    if v_target_rank >= v_actor_rank then raise exception 'Choose a player above you'; end if;
    if v_actor_rank - v_target_rank > 5 then raise exception 'Rank Swap can only target someone up to five ranks above you'; end if;
    if v_actor_score = v_target_score then raise exception 'Choose a player with a different score'; end if;

    if public.consume_shield_if_available(p_target_id, v_card.competition_id, 'Rank Swap') then
      v_blocked := true;
      v_message := format('%s''s Shield blocked your Rank Swap.', v_target_name);
    else
      v_actor_delta := v_target_score - v_actor_score;
      v_target_delta := v_actor_score - v_target_score;

      insert into public.score_transactions (
        competition_id, agent_id, delta, reason, source_type, source_id, actor_id
      ) values
        (v_card.competition_id, v_actor_id, v_actor_delta, 'Rank Swap', 'special_card', v_card.id, v_actor_id),
        (v_card.competition_id, p_target_id, v_target_delta, 'Hit by Rank Swap', 'special_card', v_card.id, v_actor_id);

      v_message := format('You swapped leaderboard positions with %s.', v_target_name);
    end if;

  else
    raise exception 'This special card is not supported yet';
  end if;

  update public.saved_special_cards
  set status = 'used', used_at = now()
  where id = v_card.id;

  insert into public.special_card_actions (
    competition_id, saved_card_id, actor_id, target_id, action_type, points_transferred, metadata
  ) values (
    v_card.competition_id,
    v_card.id,
    v_actor_id,
    p_target_id,
    v_card.card_code,
    v_points_transferred,
    jsonb_build_object('shield_blocked', v_blocked, 'message', v_message)
  );

  insert into public.activity_events (
    competition_id, actor_id, target_id, event_type, message, is_public, metadata
  ) values (
    v_card.competition_id,
    v_actor_id,
    p_target_id,
    'special_card_used',
    case
      when v_blocked then 'A player used a special card, but a Shield blocked it.'
      when p_target_id is not null then format('A player used %s on %s.', coalesce(v_card.metadata->>'title', 'a special card'), v_target_name)
      else format('A player used %s.', coalesce(v_card.metadata->>'title', 'a special card'))
    end,
    true,
    jsonb_build_object('saved_card_id', v_card.id, 'card_code', v_card.card_code, 'shield_blocked', v_blocked)
  );

  return query select v_message, v_blocked;
end;
$$;

revoke execute on function public.expire_stale_pending_draws(uuid, uuid) from public, anon, authenticated;
revoke execute on function public.consume_shield_if_available(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.expire_my_pending_draws() to authenticated;
grant execute on function public.get_my_shield_charges() to authenticated;
grant execute on function public.review_booking(uuid, boolean, text, text) to authenticated;
grant execute on function public.manual_grant_draw(uuid, text, text) to authenticated;
grant execute on function public.draw_card(uuid) to authenticated;
grant execute on function public.resolve_even_card(uuid, boolean) to authenticated;
grant execute on function public.use_special_card(uuid, uuid) to authenticated;

notify pgrst, 'reload schema';
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
