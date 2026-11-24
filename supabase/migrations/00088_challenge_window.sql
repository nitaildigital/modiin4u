-- ============================================================
-- Modiin4u — Migration 00088
-- A step competition counts only its own hours, and the most steps wins
--
-- Until now a competition added up `daily_steps` for every whole day from
-- its start date to its end date (00058), so the morning before it opened
-- and the evening after it closed counted, and nothing stopped a phone
-- sending a day from outside it. The winner was the first to reach the
-- goal, named the moment it happened. Decided 24 Nov 2026 (Harshit): the
-- competition counts only between its start and end times, the winner is
-- whoever has the most steps when it ends — the client's own words for the
-- monthly competition were "the most steps wins" (5 Oct, point 15).
--
-- Daily counting stays as it was: `daily_steps`, the daily goal, the week
-- and month, the 7-day leaderboards and the step groups all keep reading
-- it. A competition now keeps its own figures beside it:
--
--   * `challenge_steps` — per competition, per person, per date, the steps
--     (and the distance where the phone measures it) taken inside the
--     competition's hours on that date. The phone works the hours out and
--     sends them; residents never write the table directly.
--   * `record_challenge_steps` — the only way in. It refuses a competition
--     that has not started, one that was switched off, and one that ended
--     more than two hours ago (time for the last phones to send what they
--     counted before the end), and any date outside the competition. Each
--     date keeps its highest figure, so sending the same day again, from
--     a reinstall or a second phone, can never add to it. A date is also
--     bounded by the competition's hours that date (12,000 steps an hour)
--     and by the person's own saved day.
--   * `challenge_leaderboard_people` / `_neighborhoods` — the rankings while
--     a competition runs, counted the way its winner is chosen.
--   * `challenge_participant_counts`, `end_challenge_now` — the panel's
--     participant count and its "End now", admins only.
--   * `settle_challenge_winners` — every ten minutes, a competition that
--     ended more than two hours ago and has no winner gets one: the most
--     steps in total, or with "goal in a single day" the best single day.
--     A tie goes to whoever reached that figure first. Only people counted
--     in the leaderboards can win (step sharing on, not blocked). The two
--     notifications of 00060 go out as before.
--
-- The phone can be trusted no further than before: it reports what its
-- sensor counted. The database can only bound the dates, the time of
-- sending and the size of a day.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. The figures ───

create table if not exists public.challenge_steps (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  date         date not null,
  steps        int  not null default 0 check (steps between 0 and 100000),
  metres       real check (metres is null or metres >= 0),
  updated_at   timestamptz not null default now(),
  primary key (challenge_id, profile_id, date)
);

comment on table public.challenge_steps is
  'Steps inside a competition''s hours, per person per date (00088). Written only by record_challenge_steps.';

alter table public.challenge_steps enable row level security;

-- A resident reads their own figures; an admin reads everyone's. Nobody
-- writes directly. `(select …)` so each is worked out once per query, not
-- once per row.
drop policy if exists challenge_steps_read_own on public.challenge_steps;
create policy challenge_steps_read_own on public.challenge_steps
  for select using (profile_id = (select auth.uid()) or (select is_admin()));

-- Since 30 Oct a new table has no API access until it is granted.
grant select on public.challenge_steps to authenticated;
grant all on public.challenge_steps to service_role;

-- ─── 2. Sending them ───

create or replace function public.record_challenge_steps(
  p_challenge uuid,
  p_days jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  c record;
  first_day date;
  last_day date;
  d jsonb;
  day date;
  n int;
  m real;
  from_t timestamptz;
  to_t timestamptz;
  cap int;
  daily int;
begin
  if uid is null then
    raise exception 'not signed in';
  end if;
  -- A competition is at most a few months of dates; anything longer is not
  -- the app.
  if jsonb_array_length(coalesce(p_days, '[]'::jsonb)) > 120 then
    raise exception 'too many dates';
  end if;

  select * into c from challenges where id = p_challenge;
  -- Not started, switched off, or past the two hours after its end: the
  -- figures stop where the competition did.
  if c.id is null
     or c.challenge_type <> 'steps'
     or not c.is_active
     or now() < c.start_at
     or now() > c.end_at + interval '2 hours' then
    return;
  end if;

  first_day := (c.start_at at time zone 'Asia/Jerusalem')::date;
  last_day  := least((c.end_at at time zone 'Asia/Jerusalem')::date, step_today());

  for d in select * from jsonb_array_elements(coalesce(p_days, '[]'::jsonb)) loop
    day := (d->>'date')::date;
    continue when day is null or day < first_day or day > last_day;
    n := least(greatest(coalesce((d->>'steps')::int, 0), 0), 100000);
    m := nullif(greatest(coalesce((d->>'metres')::real, 0), 0), 0);
    continue when n = 0;

    -- What a person could walk on that date inside the competition: its
    -- hours that date, at 12,000 steps an hour (a runner's cadence), and
    -- no more than the whole day they saved, when it is saved. The phone
    -- reports the count; this only bounds it.
    from_t := greatest(c.start_at, (day::timestamp at time zone 'Asia/Jerusalem'));
    to_t := least(c.end_at, now(), ((day + 1)::timestamp at time zone 'Asia/Jerusalem'));
    continue when to_t <= from_t;
    cap := ceil(extract(epoch from (to_t - from_t)) / 3600.0 * 12000)::int;
    select steps into daily from daily_steps where profile_id = uid and date = day;
    n := least(n, cap, coalesce(daily, n));
    continue when n = 0;

    insert into challenge_steps (challenge_id, profile_id, date, steps, metres)
    values (c.id, uid, day, n, m)
    on conflict (challenge_id, profile_id, date) do update
      set steps = excluded.steps,
          metres = coalesce(excluded.metres, challenge_steps.metres),
          -- Moves only when the figure grows: a tie is decided by who
          -- reached it first.
          updated_at = now()
      -- Only a higher figure is written: a repeat costs no row version.
      where excluded.steps > challenge_steps.steps;
  end loop;
end;
$$;

revoke all on function public.record_challenge_steps(uuid, jsonb) from public, anon;
grant execute on function public.record_challenge_steps(uuid, jsonb) to authenticated;

-- ─── 3. The rankings ───
--
-- What a person scores: the total, or with "goal in a single day" their best
-- day. One function for both the rankings and the winner, so the table the
-- residents watch is the one the winner comes from.

create or replace function public.challenge_scores(p_challenge uuid)
returns table (
  profile_id  uuid,
  score       bigint,
  reached_at  timestamptz
)
language sql
security definer
set search_path = public
stable
as $$
  -- When it was reached: the last rise of the total, or with "goal in a
  -- single day" when the best day got there.
  select
    s.profile_id,
    case when c.goal_per_day then max(s.steps) else sum(s.steps) end::bigint,
    case when c.goal_per_day
      then (array_agg(s.updated_at order by s.steps desc, s.updated_at asc))[1]
      else max(s.updated_at)
    end
  from challenge_steps s
  join challenges c on c.id = s.challenge_id
  join profiles p on p.id = s.profile_id
  where s.challenge_id = p_challenge
    -- Only the competition's dates as they are now: if its times were
    -- changed, figures from dates it no longer covers do not count.
    and s.date between (c.start_at at time zone 'Asia/Jerusalem')::date
                   and (c.end_at at time zone 'Asia/Jerusalem')::date
    and p.health_enabled
    and not p.is_banned
  group by s.profile_id, c.goal_per_day
  having sum(s.steps) > 0;
$$;

revoke all on function public.challenge_scores(uuid) from public, anon, authenticated;

-- The same columns as steps_leaderboard_people (00043), so the app reads
-- both the same way.
create or replace function public.challenge_leaderboard_people(
  p_challenge uuid,
  limit_count int default 20
)
returns table (
  profile_id  uuid,
  full_name   text,
  avatar_url  text,
  total_steps bigint,
  rank        bigint
)
language sql
security definer
set search_path = public
stable
as $$
  select
    p.id,
    p.full_name,
    p.avatar_url,
    sc.score,
    rank() over (order by sc.score desc)
  from challenge_scores(p_challenge) sc
  join profiles p on p.id = sc.profile_id
  order by sc.score desc, sc.reached_at asc
  limit limit_count;
$$;

create or replace function public.challenge_leaderboard_neighborhoods(
  p_challenge uuid,
  limit_count int default 20
)
returns table (
  neighborhood_id uuid,
  name            text,
  total_steps     bigint,
  member_count    bigint,
  rank            bigint
)
language sql
security definer
set search_path = public
stable
as $$
  select
    n.id,
    n.name,
    sum(sc.score)::bigint,
    count(*)::bigint,
    rank() over (order by sum(sc.score) desc)
  from challenge_scores(p_challenge) sc
  join profiles p on p.id = sc.profile_id
  join neighborhoods n on n.id = p.neighborhood_id
  group by n.id, n.name
  order by 3 desc
  limit limit_count;
$$;

revoke all on function public.challenge_leaderboard_people(uuid, int) from public, anon;
revoke all on function public.challenge_leaderboard_neighborhoods(uuid, int) from public, anon;
grant execute on function public.challenge_leaderboard_people(uuid, int) to authenticated;
grant execute on function public.challenge_leaderboard_neighborhoods(uuid, int) to authenticated;

-- ─── 4. The panel ───

-- How many people have figures in each competition, for the panel's list:
-- counted in the database, so it is right however many rows there are.
create or replace function public.challenge_participant_counts()
returns table (challenge_id uuid, participants bigint)
language plpgsql
security definer
set search_path = public
stable
as $$
begin
  if not is_admin() then
    raise exception 'not allowed';
  end if;
  return query
    select s.challenge_id, count(distinct s.profile_id)::bigint
      from challenge_steps s
     group by s.challenge_id;
end;
$$;

-- "End now": the end becomes this moment by the database's clock, not by
-- the admin's computer's.
create or replace function public.end_challenge_now(p_challenge uuid)
returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  ended timestamptz;
begin
  if not is_admin() then
    raise exception 'not allowed';
  end if;
  update challenges set end_at = now()
   where id = p_challenge and is_active and start_at <= now() and end_at > now()
  returning end_at into ended;
  return ended;
end;
$$;

revoke all on function public.challenge_participant_counts() from public, anon;
revoke all on function public.end_challenge_now(uuid) from public, anon;
grant execute on function public.challenge_participant_counts() to authenticated;
grant execute on function public.end_challenge_now(uuid) to authenticated;

-- ─── 5. The winner, once it has ended ───

-- The old rule named the first to reach the goal on every save of a day.
drop trigger if exists daily_steps_award_winner on public.daily_steps;
drop function if exists public.award_challenge_winner();

create or replace function public.settle_challenge_winners()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  c record;
  w record;
  won int;
  v_name text;
  v_prize text;
  v_prize_en text;
begin
  for c in
    select * from challenges
     where is_active
       and winner_id is null
       and challenge_type = 'steps'
       and end_at + interval '2 hours' <= now()
       -- Only competitions run under this rule have figures here; an older
       -- one that ended without a winner is not given one after the fact.
       and exists (select 1 from challenge_steps s where s.challenge_id = challenges.id)
  loop
    select sc.profile_id, sc.score, p.full_name into w
      from challenge_scores(c.id) sc
      join profiles p on p.id = sc.profile_id
     order by sc.score desc, sc.reached_at asc
     limit 1;
    continue when w.profile_id is null;

    v_name := coalesce(nullif(trim(w.full_name), ''), 'תושב/ת');
    update challenges
       set winner_id = w.profile_id, winner_name = v_name,
           won_at = now(), won_steps = w.score
     where id = c.id and winner_id is null;
    get diagnostics won = row_count;
    continue when won = 0;

    v_prize := nullif(trim(c.prize), '');
    v_prize_en := coalesce(nullif(trim(c.prize_en), ''), v_prize);

    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      '🏆 זכית בתחרות!',
      c.name || coalesce(' · הפרס שלך: ' || v_prize, ''),
      '🏆 You won the competition!',
      c.name || coalesce(' · Your prize: ' || v_prize_en, ''),
      '/steps', 'scheduled', now(), 'person',
      jsonb_build_object('profile_ids', jsonb_build_array(w.profile_id)),
      'challenge_win', c.id
    ), (
      'יש זוכה בתחרות',
      v_name || ' זכה/תה ב' || c.name || coalesce(' · ' || v_prize, ''),
      'The competition has a winner',
      v_name || ' won ' || c.name || coalesce(' · ' || v_prize_en, ''),
      '/steps', 'scheduled', now(), 'all_but',
      jsonb_build_object('profile_ids', jsonb_build_array(w.profile_id)),
      'challenge_result', c.id
    );
  end loop;
end;
$$;

revoke all on function public.settle_challenge_winners() from public, anon, authenticated;

-- Every ten minutes; scheduled again under the same name on a re-run.
select cron.unschedule('settle-challenge-winners')
 where exists (select 1 from cron.job where jobname = 'settle-challenge-winners');
select cron.schedule('settle-challenge-winners', '*/10 * * * *',
  $job$ select public.settle_challenge_winners(); $job$);
