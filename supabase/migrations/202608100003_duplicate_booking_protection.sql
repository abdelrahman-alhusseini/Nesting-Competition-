-- V14.4 duplicate-booking hardening
-- Prevents a ServiceTitan job from ever being submitted more than once.
-- Protection is global across agents and competitions and applies regardless
-- of booking status (pending / approved / rejected).
--
-- Safe behavior:
-- * Uses the ServiceTitan numeric job ID as the canonical anti-abuse key.
-- * Also checks a normalized URL as a secondary protection.
-- * Uses a transaction advisory lock to stop simultaneous/double-click races.
-- * Does NOT delete or modify any historical bookings.
-- * If historical duplicates already exist, future duplicates are still blocked.

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
    select 1
    from public.profiles
    where id = v_user_id
      and role = 'agent'
      and is_active = true
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

  -- Normalize casing, trailing slashes, query strings, and fragments.
  -- The numeric job ID remains the primary anti-duplicate key.
  v_normalized := lower(trim(p_job_url));
  v_normalized := split_part(v_normalized, '#', 1);
  v_normalized := split_part(v_normalized, '?', 1);
  v_normalized := regexp_replace(v_normalized, '/+$', '');

  begin
    v_booking_type := p_booking_type::public.booking_type;
  exception when invalid_text_representation then
    raise exception 'Invalid booking type';
  end;

  -- Serialize submissions for the same ServiceTitan job so two rapid requests
  -- cannot both pass the duplicate check before either insert commits.
  perform pg_advisory_xact_lock(hashtextextended('servicetitan-job:' || v_job_id, 0));

  if exists (
    select 1
    from public.bookings b
    where b.job_id = v_job_id
       or lower(regexp_replace(split_part(split_part(trim(b.job_url), '#', 1), '?', 1), '/+$', '')) = v_normalized
  ) then
    raise exception 'This ServiceTitan booking has already been submitted';
  end if;

  insert into public.bookings (
    competition_id,
    agent_id,
    job_url,
    normalized_url,
    job_id,
    booking_type
  ) values (
    v_competition_id,
    v_user_id,
    trim(p_job_url),
    v_normalized,
    v_job_id,
    v_booking_type
  )
  returning id into v_booking_id;

  insert into public.activity_events (
    competition_id,
    actor_id,
    event_type,
    message,
    is_public,
    metadata
  ) values (
    v_competition_id,
    v_user_id,
    'booking_submitted',
    'A booking was submitted for admin validation.',
    true,
    jsonb_build_object(
      'booking_id', v_booking_id,
      'booking_type', v_booking_type,
      'job_id', v_job_id
    )
  );

  insert into public.audit_logs (
    actor_id,
    action,
    entity_type,
    entity_id,
    details
  ) values (
    v_user_id,
    'booking_submitted',
    'booking',
    v_booking_id,
    jsonb_build_object(
      'booking_type', v_booking_type,
      'job_id', v_job_id
    )
  );

  return v_booking_id;
exception
  when unique_violation then
    raise exception 'This ServiceTitan booking has already been submitted';
end;
$$;

-- Keep database-level unique indexes whenever the current historical data
-- permits them. If old duplicate rows already exist, we intentionally keep
-- those rows untouched; the submit_booking function above still blocks every
-- future duplicate.
do $$
begin
  if not exists (
    select job_id
    from public.bookings
    where job_id is not null
    group by job_id
    having count(*) > 1
  ) then
    create unique index if not exists bookings_unique_job_id
      on public.bookings(job_id)
      where job_id is not null;
  end if;
end
$$;

do $$
begin
  if not exists (
    select normalized_url
    from public.bookings
    group by normalized_url
    having count(*) > 1
  ) then
    create unique index if not exists bookings_unique_normalized_url
      on public.bookings(normalized_url);
  end if;
end
$$;

grant execute on function public.submit_booking(text, text) to authenticated;
notify pgrst, 'reload schema';
