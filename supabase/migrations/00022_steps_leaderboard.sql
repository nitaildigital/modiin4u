-- ============================================================
-- Modiin4u — Migration 00022
-- Leaderboards for the step counter
--
-- The Step Counter screen showed a weekly bar chart, a neighbourhood table
-- and a city table — all of them written into the app. The city table named
-- three people who do not exist: "Daniel Cohen", "Maya Levi", "Amit May",
-- each with a step count beside their name, on a screen about a real town.
--
-- `daily_steps` is own-rows-only under the policy 00014 sets, which is right:
-- one resident has no business reading another's day. A leaderboard still
-- needs the totals, so it comes from these two functions instead. They are
-- SECURITY DEFINER, and they return only what a leaderboard shows — a name, a
-- rank and a sum — never a row.
--
-- Only people who turned the health-data switch on appear. The switch already
-- exists in Settings and says it is for counting steps and challenges; taking
-- part in a public ranking is what that means, and someone who left it off
-- must not be listed.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. People ───

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
  where d.date >= (current_date - make_interval(days => days))
    and p.health_enabled
    and not p.is_banned
  group by p.id, p.full_name, p.avatar_url
  having sum(d.steps) > 0
  order by total_steps desc
  limit limit_count;
$$;

-- ─── 2. Neighbourhoods ───
--
-- Summed across everyone who has told us where they live and opted in. A
-- neighbourhood with nobody counting steps does not appear at all, rather
-- than appearing at zero.

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
  where d.date >= (current_date - make_interval(days => days))
    and p.health_enabled
    and not p.is_banned
  group by n.id, n.name
  having sum(d.steps) > 0
  order by 3 desc
  limit limit_count;
$$;

-- ─── 3. Who may call them ───
--
-- Signed in only. These are other people's figures, however aggregated, and
-- the anonymous key is readable by anyone who downloads the app.

revoke all on function public.steps_leaderboard_people(int, int) from public, anon;
revoke all on function public.steps_leaderboard_neighborhoods(int, int) from public, anon;

grant execute on function public.steps_leaderboard_people(int, int) to authenticated;
grant execute on function public.steps_leaderboard_neighborhoods(int, int) to authenticated;
