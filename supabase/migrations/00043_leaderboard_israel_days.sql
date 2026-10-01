-- ============================================================
-- Modiin4u — Migration 00043
-- The step leaderboards count Israel's days
--
-- The two ranking functions (00022) chose their days with `current_date`,
-- which is the server's date, in UTC. The app records each day's steps
-- under the date on a phone in Modi'in, three hours ahead in summer and two
-- in winter, so between midnight and about 3 a.m. the new day's steps were
-- already recorded while the leaderboard still counted from yesterday. The
-- window was also one day too wide: `date >= current_date - 7 days` takes
-- in eight dates.
--
-- Both now take exactly `days` days ending today in Israel, with
-- `step_today()` from 00041, the same "today" the step groups use. Nothing
-- else about them changes: who appears (health switch on, not banned), what
-- is returned, who may call them.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.steps_leaderboard_people(
  days int default 7,
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
    sum(d.steps)::bigint as total_steps,
    rank() over (order by sum(d.steps) desc)
  from public.daily_steps d
  join public.profiles p on p.id = d.profile_id
  where d.date > public.step_today() - days
    and d.date <= public.step_today()
    and p.health_enabled
    and not p.is_banned
  group by p.id, p.full_name, p.avatar_url
  having sum(d.steps) > 0
  order by total_steps desc
  limit limit_count;
$$;

create or replace function public.steps_leaderboard_neighborhoods(
  days int default 7,
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
    sum(d.steps)::bigint,
    count(distinct p.id)::bigint,
    rank() over (order by sum(d.steps) desc)
  from public.daily_steps d
  join public.profiles p on p.id = d.profile_id
  join public.neighborhoods n on n.id = p.neighborhood_id
  where d.date > public.step_today() - days
    and d.date <= public.step_today()
    and p.health_enabled
    and not p.is_banned
  group by n.id, n.name
  having sum(d.steps) > 0
  order by 3 desc
  limit limit_count;
$$;

revoke all on function public.steps_leaderboard_people(int, int) from public, anon;
revoke all on function public.steps_leaderboard_neighborhoods(int, int) from public, anon;
grant execute on function public.steps_leaderboard_people(int, int) to authenticated;
grant execute on function public.steps_leaderboard_neighborhoods(int, int) to authenticated;
