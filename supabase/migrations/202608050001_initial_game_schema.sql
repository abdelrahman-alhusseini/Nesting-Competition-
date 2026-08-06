-- Michael & Son Nesting Champions
-- Initial Supabase schema, server-side game rules, RLS, audit history, and admin RPCs.

create extension if not exists pgcrypto;
create extension if not exists citext;

create type public.app_role as enum ('agent', 'admin');
create type public.competition_status as enum ('active', 'ended');
create type public.booking_type as enum (
  'normal',
  'cross_sell',
  'remodeling_cross_sell',
  'due_inspection',
  'restoration'
);
create type public.booking_status as enum ('pending', 'approved', 'rejected', 'reversed');
create type public.pending_draw_status as enum ('pending', 'drawn', 'expired', 'cancelled');
create type public.card_draw_status as enum (
  'pending_choice',
  'applied',
  'awaiting_storage',
  'stored',
  'discarded',
  'reversed'
);
create type public.special_card_status as enum ('active', 'used', 'expired', 'discarded', 'reversed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext not null unique,
  display_name text not null,
  role public.app_role not null default 'agent',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.competitions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  status public.competition_status not null default 'active',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create unique index one_active_competition
  on public.competitions ((status))
  where status = 'active';

insert into public.competitions (name, status)
values ('Nesting Champions', 'active');

create table public.competition_members (
  competition_id uuid not null references public.competitions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  score integer not null default 0,
  score_reached_at timestamptz not null default now(),
  joined_at timestamptz not null default now(),
  is_active boolean not null default true,
  primary key (competition_id, user_id)
);

create table public.game_settings (
  competition_id uuid primary key references public.competitions(id) on delete cascade,
  max_pending_draws integer not null default 3 check (max_pending_draws between 1 and 20),
  max_saved_special_cards integer not null default 1 check (max_saved_special_cards between 1 and 5),
  special_expiry_bookings integer not null default 5 check (special_expiry_bookings between 1 and 50),
  normal_special_chance numeric(5,4) not null default 0.05,
  cross_sell_special_chance numeric(5,4) not null default 0.50,
  remodeling_special_chance numeric(5,4) not null default 1.00,
  due_inspection_special_chance numeric(5,4) not null default 0.25,
  restoration_special_chance numeric(5,4) not null default 0.15,
  number_pool_chance numeric(5,4) not null default 0.60,
  plus_two_chance numeric(5,4) not null default 0.12,
  plus_four_chance numeric(5,4) not null default 0.07,
  reverse_chance numeric(5,4) not null default 0.10,
  skip_chance numeric(5,4) not null default 0.11,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

insert into public.game_settings (competition_id)
select id from public.competitions where status = 'active';

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  agent_id uuid not null references public.profiles(id) on delete cascade,
  job_url text not null,
  normalized_url text not null,
  job_id text,
  booking_type public.booking_type not null,
  status public.booking_status not null default 'pending',
  submitted_at timestamptz not null default now(),
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  rejection_reason text,
  reversed_at timestamptz,
  reversed_by uuid references public.profiles(id)
);

create unique index bookings_unique_normalized_url on public.bookings(normalized_url);
create unique index bookings_unique_job_id on public.bookings(job_id) where job_id is not null;
create index bookings_agent_id_idx on public.bookings(agent_id);
create index bookings_status_idx on public.bookings(status);

create table public.pending_draws (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  agent_id uuid not null references public.profiles(id) on delete cascade,
  booking_id uuid unique references public.bookings(id) on delete set null,
  booking_type public.booking_type not null,
  status public.pending_draw_status not null default 'pending',
  is_manual boolean not null default false,
  manual_reason text,
  granted_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  drawn_at timestamptz,
  expired_at timestamptz,
  cancelled_at timestamptz
);

create index pending_draws_agent_status_idx
  on public.pending_draws(agent_id, status, created_at);

create table public.card_draws (
  id uuid primary key default gen_random_uuid(),
  pending_draw_id uuid unique references public.pending_draws(id) on delete set null,
  competition_id uuid not null references public.competitions(id) on delete cascade,
  agent_id uuid not null references public.profiles(id) on delete cascade,
  booking_type public.booking_type not null,
  card_code text not null,
  title text not null,
  description text not null,
  tone text not null check (tone in ('positive', 'negative', 'neutral', 'special')),
  card_number integer,
  points_delta integer not null default 0,
  can_gamble boolean not null default false,
  is_special boolean not null default false,
  status public.card_draw_status not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  reversed_at timestamptz
);

create index card_draws_agent_idx on public.card_draws(agent_id, created_at desc);

create table public.saved_special_cards (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  card_draw_id uuid not null unique references public.card_draws(id) on delete cascade,
  card_code text not null,
  metadata jsonb not null default '{}'::jsonb,
  bookings_remaining integer not null default 5,
  status public.special_card_status not null default 'active',
  created_at timestamptz not null default now(),
  used_at timestamptz,
  expired_at timestamptz,
  discarded_at timestamptz,
  reversed_at timestamptz
);

create unique index one_active_special_card_per_user
  on public.saved_special_cards(competition_id, owner_id)
  where status = 'active';

create table public.score_transactions (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  agent_id uuid not null references public.profiles(id) on delete cascade,
  delta integer not null,
  reason text not null,
  source_type text not null,
  source_id uuid,
  actor_id uuid references public.profiles(id),
  reversed_from uuid references public.score_transactions(id),
  reversed_at timestamptz,
  created_at timestamptz not null default now()
);

create index score_transactions_agent_idx
  on public.score_transactions(agent_id, created_at desc);
create index score_transactions_source_idx
  on public.score_transactions(source_type, source_id);

create table public.special_card_actions (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid not null references public.competitions(id) on delete cascade,
  saved_card_id uuid not null references public.saved_special_cards(id),
  actor_id uuid not null references public.profiles(id),
  target_id uuid references public.profiles(id),
  action_type text not null,
  points_transferred integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  reversed_at timestamptz
);

create table public.activity_events (
  id uuid primary key default gen_random_uuid(),
  competition_id uuid references public.competitions(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  target_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  message text not null,
  is_public boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index activity_events_created_at_idx on public.activity_events(created_at desc);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_created_at_idx on public.audit_logs(created_at desc);

-- Shared helpers ------------------------------------------------------------

create or replace function public.active_competition_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select id from public.competitions where status = 'active' limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'
      and is_active = true
  );
$$;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

create trigger game_settings_touch_updated_at
before update on public.game_settings
for each row execute function public.touch_updated_at();

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_display_name text;
  v_competition_id uuid;
begin
  v_username := lower(coalesce(nullif(new.raw_user_meta_data->>'username', ''), split_part(new.email, '@', 1)));
  v_display_name := coalesce(nullif(new.raw_user_meta_data->>'display_name', ''), v_username);

  insert into public.profiles (id, username, display_name)
  values (new.id, v_username, v_display_name)
  on conflict (id) do nothing;

  v_competition_id := public.active_competition_id();
  if v_competition_id is not null then
    insert into public.competition_members (competition_id, user_id)
    values (v_competition_id, new.id)
    on conflict do nothing;
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

create or replace function public.apply_score_transaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.competition_members
  set score = score + new.delta,
      score_reached_at = now()
  where competition_id = new.competition_id
    and user_id = new.agent_id;
  return new;
end;
$$;

create trigger score_transaction_applied
  after insert on public.score_transactions
  for each row execute function public.apply_score_transaction();

-- Read models ---------------------------------------------------------------

create or replace view public.leaderboard
with (security_invoker = true)
as
with ranked as (
  select
    cm.user_id,
    p.username,
    p.display_name,
    cm.score,
    cm.score_reached_at,
    row_number() over (
      order by cm.score desc, cm.score_reached_at asc, cm.joined_at asc
    )::integer as rank
  from public.competition_members cm
  join public.profiles p on p.id = cm.user_id
  join public.competitions c on c.id = cm.competition_id
  where c.status = 'active'
    and cm.is_active = true
    and p.is_active = true
    and p.role = 'agent'
)
select
  user_id,
  username,
  display_name,
  score,
  rank,
  case
    when rank = 1 then 'Nesting Champion'
    when rank = 2 then 'Booking Master'
    when rank = 3 then 'Sales Expert'
    when rank <= 5 then 'Booking Pro'
    when rank <= 10 then 'Rising Agent'
    else 'Rookie'
  end as title
from ranked;

create or replace function public.get_my_profile()
returns table (
  id uuid,
  username citext,
  display_name text,
  role public.app_role,
  is_active boolean,
  score integer,
  title text
)
language sql
stable
security definer
set search_path = public
as $$
  select
    p.id,
    p.username,
    p.display_name,
    p.role,
    p.is_active,
    coalesce(l.score, cm.score, 0) as score,
    coalesce(l.title, case when p.role = 'admin' then 'Administrator' else 'Rookie' end) as title
  from public.profiles p
  left join public.competition_members cm
    on cm.user_id = p.id and cm.competition_id = public.active_competition_id()
  left join public.leaderboard l on l.user_id = p.id
  where p.id = (select auth.uid());
$$;

create or replace function public.get_admin_stats()
returns table (
  total_bookings bigint,
  approved bigint,
  pending bigint,
  rejected bigint,
  total_users bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;

  return query
  select
    count(*)::bigint,
    count(*) filter (where b.status = 'approved')::bigint,
    count(*) filter (where b.status = 'pending')::bigint,
    count(*) filter (where b.status = 'rejected')::bigint,
    (select count(*)::bigint from public.profiles where role = 'agent')
  from public.bookings b;
end;
$$;

-- Booking and draw helpers --------------------------------------------------

create or replace function public.expire_oldest_pending_draws(
  p_agent_id uuid,
  p_competition_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max integer;
  v_over integer;
  v_expired record;
begin
  select max_pending_draws into v_max
  from public.game_settings
  where competition_id = p_competition_id;

  select greatest(count(*)::integer - coalesce(v_max, 3), 0)
  into v_over
  from public.pending_draws
  where agent_id = p_agent_id
    and competition_id = p_competition_id
    and status = 'pending';

  for v_expired in
    select id
    from public.pending_draws
    where agent_id = p_agent_id
      and competition_id = p_competition_id
      and status = 'pending'
    order by created_at asc
    limit v_over
    for update
  loop
    update public.pending_draws
    set status = 'expired', expired_at = now()
    where id = v_expired.id;

    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      p_competition_id,
      p_agent_id,
      'pending_draw_expired',
      'A player''s oldest pending draw expired after reaching the three-draw limit.',
      true,
      jsonb_build_object('pending_draw_id', v_expired.id)
    );
  end loop;
end;
$$;

create or replace function public.decrement_saved_card_expiry(
  p_agent_id uuid,
  p_competition_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card public.saved_special_cards%rowtype;
begin
  select * into v_card
  from public.saved_special_cards
  where owner_id = p_agent_id
    and competition_id = p_competition_id
    and status = 'active'
  for update;

  if not found then
    return;
  end if;

  if v_card.bookings_remaining <= 1 then
    update public.saved_special_cards
    set bookings_remaining = 0,
        status = 'expired',
        expired_at = now()
    where id = v_card.id;

    insert into public.activity_events (
      competition_id, actor_id, event_type, message, is_public, metadata
    ) values (
      p_competition_id,
      p_agent_id,
      'special_card_expired',
      'A saved special card expired after five additional approved bookings.',
      true,
      jsonb_build_object('saved_card_id', v_card.id, 'card_code', v_card.card_code)
    );
  else
    update public.saved_special_cards
    set bookings_remaining = bookings_remaining - 1
    where id = v_card.id;
  end if;
end;
$$;

create or replace function public.submit_booking(
  p_job_url text,
  p_booking_type text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_competition_id uuid := public.active_competition_id();
  v_normalized text;
  v_match text[];
  v_job_id text;
  v_booking_type public.booking_type;
  v_booking_id uuid;
begin
  if v_user_id is null then
    raise exception 'You must be signed in';
  end if;

  if not exists (
    select 1 from public.profiles
    where id = v_user_id and role = 'agent' and is_active = true
  ) then
    raise exception 'Only active agents can submit bookings';
  end if;

  if v_competition_id is null then
    raise exception 'No active competition';
  end if;

  if p_job_url is null or position('go.servicetitan.com' in lower(p_job_url)) = 0 then
    raise exception 'Enter a valid ServiceTitan job URL';
  end if;

  v_match := regexp_match(lower(trim(p_job_url)), '/job/(index|node)/([0-9]+)');
  if v_match is null then
    raise exception 'The ServiceTitan URL does not contain a valid job number';
  end if;
  v_job_id := v_match[2];
  v_normalized := lower(regexp_replace(trim(p_job_url), '/+$', ''));

  begin
    v_booking_type := p_booking_type::public.booking_type;
  exception when invalid_text_representation then
    raise exception 'Invalid booking type';
  end;

  insert into public.bookings (
    competition_id, agent_id, job_url, normalized_url, job_id, booking_type
  ) values (
    v_competition_id, v_user_id, trim(p_job_url), v_normalized, v_job_id, v_booking_type
  )
  returning id into v_booking_id;

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_competition_id,
    v_user_id,
    'booking_submitted',
    'A booking was submitted for admin validation.',
    true,
    jsonb_build_object('booking_id', v_booking_id, 'booking_type', v_booking_type, 'job_id', v_job_id)
  );

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    v_user_id,
    'booking_submitted',
    'booking',
    v_booking_id,
    jsonb_build_object('booking_type', v_booking_type, 'job_id', v_job_id)
  );

  return v_booking_id;
exception
  when unique_violation then
    raise exception 'This ServiceTitan booking has already been submitted';
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

  if not found then
    raise exception 'Booking not found';
  end if;
  if v_booking.status <> 'pending' then
    raise exception 'This booking has already been reviewed';
  end if;

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

    insert into public.pending_draws (
      competition_id, agent_id, booking_id, booking_type, granted_by
    ) values (
      v_booking.competition_id,
      v_booking.agent_id,
      v_booking.id,
      v_type,
      (select auth.uid())
    );

    perform public.expire_oldest_pending_draws(v_booking.agent_id, v_booking.competition_id);

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
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;
  if not exists (select 1 from public.profiles where id = p_agent_id and role = 'agent' and is_active = true) then
    raise exception 'Agent not found or inactive';
  end if;

  v_type := p_booking_type::public.booking_type;

  insert into public.pending_draws (
    competition_id, agent_id, booking_type, is_manual, manual_reason, granted_by
  ) values (
    v_competition_id,
    p_agent_id,
    v_type,
    true,
    nullif(trim(p_reason), ''),
    (select auth.uid())
  ) returning id into v_draw_id;

  perform public.expire_oldest_pending_draws(p_agent_id, v_competition_id);

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_competition_id,
    p_agent_id,
    'manual_draw_granted',
    'An admin manually granted a card draw.',
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

create or replace function public.admin_adjust_points(
  p_agent_id uuid,
  p_amount integer,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_competition_id uuid := public.active_competition_id();
  v_transaction_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;
  if p_amount = 0 then
    raise exception 'Point adjustment cannot be zero';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'A reason is required';
  end if;

  insert into public.score_transactions (
    competition_id, agent_id, delta, reason, source_type, actor_id
  ) values (
    v_competition_id,
    p_agent_id,
    p_amount,
    trim(p_reason),
    'admin_adjustment',
    (select auth.uid())
  ) returning id into v_transaction_id;

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_competition_id,
    p_agent_id,
    'points_adjusted',
    format('An admin adjusted a player''s score by %s points.', p_amount),
    true,
    jsonb_build_object('amount', p_amount, 'reason', p_reason)
  );

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    (select auth.uid()),
    'points_adjusted',
    'score_transaction',
    v_transaction_id,
    jsonb_build_object('agent_id', p_agent_id, 'amount', p_amount, 'reason', p_reason)
  );

  return v_transaction_id;
end;
$$;

create or replace function public.admin_set_user_active(
  p_user_id uuid,
  p_is_active boolean
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required';
  end if;
  if p_user_id = (select auth.uid()) and not p_is_active then
    raise exception 'You cannot deactivate your own admin account';
  end if;

  update public.profiles set is_active = p_is_active where id = p_user_id;
  update public.competition_members
  set is_active = p_is_active
  where user_id = p_user_id and competition_id = public.active_competition_id();

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    (select auth.uid()),
    case when p_is_active then 'user_activated' else 'user_deactivated' end,
    'profile',
    p_user_id,
    jsonb_build_object('is_active', p_is_active)
  );
end;
$$;

-- Server-side card generation prevents users from choosing their own results.
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
        v_title := 'Move Another Player 2 Ranks';
        v_description := 'Choose a player and move them up or down two positions.';
      else
        v_card_code := 'shield';
        v_title := 'Shield';
        v_description := 'Block the next special-card attack against you.';
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
        v_description := 'Keep +1 or take the 50/50 risk for +4 or -6.';
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

  if not p_gamble then
    v_points := 1;
    v_title := '+1 Point';
    v_description := 'You kept the guaranteed point.';
    v_tone := 'positive';
  elsif random() < 0.5 then
    v_points := 4;
    v_title := '+4 Points';
    v_description := 'The 50/50 risk paid off.';
    v_tone := 'positive';
  else
    v_points := -6;
    v_title := '-6 Points';
    v_description := 'The 50/50 risk did not go your way.';
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

create or replace function public.save_special_card(
  p_card_draw_id uuid,
  p_replace_existing boolean
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_draw public.card_draws%rowtype;
  v_existing public.saved_special_cards%rowtype;
  v_expiry integer;
  v_saved_id uuid;
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

  select * into v_existing
  from public.saved_special_cards
  where competition_id = v_draw.competition_id
    and owner_id = v_draw.agent_id
    and status = 'active'
  for update;

  if found and not p_replace_existing then
    update public.card_draws set status = 'discarded', resolved_at = now() where id = v_draw.id;
    return v_existing.id;
  end if;

  if found then
    update public.saved_special_cards
    set status = 'discarded', discarded_at = now()
    where id = v_existing.id;
  end if;

  select special_expiry_bookings into v_expiry
  from public.game_settings
  where competition_id = v_draw.competition_id;

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

  update public.card_draws set status = 'stored', resolved_at = now() where id = v_draw.id;

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

create or replace function public.reverse_booking(
  p_booking_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings%rowtype;
  v_transaction public.score_transactions%rowtype;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if nullif(trim(p_reason), '') is null then raise exception 'A reversal reason is required'; end if;

  select * into v_booking from public.bookings where id = p_booking_id for update;
  if not found then raise exception 'Booking not found'; end if;
  if v_booking.status <> 'approved' then raise exception 'Only approved bookings can be reversed'; end if;

  update public.bookings
  set status = 'reversed', reversed_at = now(), reversed_by = (select auth.uid())
  where id = v_booking.id;

  update public.pending_draws
  set status = 'cancelled', cancelled_at = now()
  where booking_id = v_booking.id and status = 'pending';

  for v_transaction in
    select st.*
    from public.score_transactions st
    join public.card_draws cd on cd.id = st.source_id and st.source_type = 'card_draw'
    join public.pending_draws pd on pd.id = cd.pending_draw_id
    where pd.booking_id = v_booking.id
      and st.reversed_at is null
  loop
    insert into public.score_transactions (
      competition_id, agent_id, delta, reason, source_type, source_id, actor_id, reversed_from
    ) values (
      v_transaction.competition_id,
      v_transaction.agent_id,
      -v_transaction.delta,
      'Booking reversal: ' || trim(p_reason),
      'booking_reversal',
      v_booking.id,
      (select auth.uid()),
      v_transaction.id
    );

    update public.score_transactions set reversed_at = now() where id = v_transaction.id;
  end loop;

  update public.card_draws cd
  set status = 'reversed', reversed_at = now()
  from public.pending_draws pd
  where cd.pending_draw_id = pd.id and pd.booking_id = v_booking.id;

  update public.saved_special_cards sc
  set status = 'reversed', reversed_at = now()
  from public.card_draws cd
  join public.pending_draws pd on pd.id = cd.pending_draw_id
  where sc.card_draw_id = cd.id and pd.booking_id = v_booking.id and sc.status = 'active';

  insert into public.activity_events (
    competition_id, actor_id, event_type, message, is_public, metadata
  ) values (
    v_booking.competition_id,
    v_booking.agent_id,
    'booking_reversed',
    'An approved booking and all linked effects were reversed by an admin.',
    true,
    jsonb_build_object('booking_id', v_booking.id, 'reason', p_reason)
  );

  insert into public.audit_logs (actor_id, action, entity_type, entity_id, details)
  values (
    (select auth.uid()),
    'booking_reversed',
    'booking',
    v_booking.id,
    jsonb_build_object('agent_id', v_booking.agent_id, 'reason', p_reason)
  );
end;
$$;

-- RLS ----------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.competitions enable row level security;
alter table public.competition_members enable row level security;
alter table public.game_settings enable row level security;
alter table public.bookings enable row level security;
alter table public.pending_draws enable row level security;
alter table public.card_draws enable row level security;
alter table public.saved_special_cards enable row level security;
alter table public.score_transactions enable row level security;
alter table public.special_card_actions enable row level security;
alter table public.activity_events enable row level security;
alter table public.audit_logs enable row level security;

create policy profiles_read_authenticated
on public.profiles for select to authenticated
using (true);

create policy competitions_read_authenticated
on public.competitions for select to authenticated
using (true);

create policy members_read_authenticated
on public.competition_members for select to authenticated
using (true);

create policy settings_read_authenticated
on public.game_settings for select to authenticated
using (true);

create policy settings_admin_update
on public.game_settings for update to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

create policy bookings_read_own_or_admin
on public.bookings for select to authenticated
using (agent_id = (select auth.uid()) or (select public.is_admin()));

create policy pending_draws_read_own_or_admin
on public.pending_draws for select to authenticated
using (agent_id = (select auth.uid()) or (select public.is_admin()));

create policy card_draws_read_own_or_admin
on public.card_draws for select to authenticated
using (agent_id = (select auth.uid()) or (select public.is_admin()));

create policy saved_cards_read_own_or_admin
on public.saved_special_cards for select to authenticated
using (owner_id = (select auth.uid()) or (select public.is_admin()));

create policy score_transactions_read_own_or_admin
on public.score_transactions for select to authenticated
using (agent_id = (select auth.uid()) or (select public.is_admin()));

create policy special_actions_read_authenticated
on public.special_card_actions for select to authenticated
using (true);

create policy activity_read_public_or_admin
on public.activity_events for select to authenticated
using (is_public = true or (select public.is_admin()));

create policy audit_admin_read
on public.audit_logs for select to authenticated
using ((select public.is_admin()));

-- Only RPCs/security-definer functions perform writes from the web client.
revoke insert, update, delete on all tables in schema public from anon, authenticated;
revoke execute on all functions in schema public from public, anon;
grant usage on schema public to authenticated, service_role;
grant select on all tables in schema public to authenticated;
grant update on public.game_settings to authenticated;
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;
grant execute on all functions in schema public to service_role;

grant execute on function public.get_my_profile() to authenticated;
grant execute on function public.get_admin_stats() to authenticated;
grant execute on function public.submit_booking(text, text) to authenticated;
grant execute on function public.review_booking(uuid, boolean, text, text) to authenticated;
grant execute on function public.manual_grant_draw(uuid, text, text) to authenticated;
grant execute on function public.admin_adjust_points(uuid, integer, text) to authenticated;
grant execute on function public.admin_set_user_active(uuid, boolean) to authenticated;
grant execute on function public.draw_card(uuid) to authenticated;
grant execute on function public.resolve_even_card(uuid, boolean) to authenticated;
grant execute on function public.save_special_card(uuid, boolean) to authenticated;
grant execute on function public.reverse_booking(uuid, text) to authenticated;

revoke execute on function public.expire_oldest_pending_draws(uuid, uuid) from public, anon, authenticated;
revoke execute on function public.decrement_saved_card_expiry(uuid, uuid) from public, anon, authenticated;
revoke execute on function public.apply_score_transaction() from public, anon, authenticated;
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;

-- Realtime tables used by the live dashboard.
alter publication supabase_realtime add table public.bookings;
alter publication supabase_realtime add table public.pending_draws;
alter publication supabase_realtime add table public.activity_events;
alter publication supabase_realtime add table public.competition_members;
