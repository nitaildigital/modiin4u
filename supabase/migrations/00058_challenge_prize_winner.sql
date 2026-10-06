-- ============================================================
-- Modiin4u — Migration 00058
-- A step competition has a prize, and the first to reach the goal wins it
--
-- The client asked (5 Oct, points 13–15) for a prize banner managed in the
-- panel and a monthly city competition with a winner. `challenges` had no
-- prize, and when one ended nobody was named: the 5 Oct and 6 Oct tests on
-- the phones found the card simply gone.
--
-- A challenge now carries:
--   * `prize` / `prize_en` — the prize as the client writes it, shown on the
--     banner and in the win message;
--   * `goal_per_day` — the goal counts one day's steps (10,000 in a day) when
--     true, or every day's since the start (the old way) when false;
--   * `winner_id`, `winner_name`, `won_at`, `won_steps` — the winner, set once
--     by the database, never by a form.
--
-- The rule (6 Oct): the first person whose steps reach the goal while the
-- challenge runs wins, one winner per challenge. A trigger on `daily_steps`
-- checks after every save; the update only takes a challenge that has no
-- winner yet, so two people reaching it in the same moment cannot both win.
-- Only someone counted in the leaderboards can win: step counting on, not
-- blocked. The name is copied onto the challenge because profiles are not
-- readable by others.
--
-- Safe to run more than once.
-- ============================================================

alter table public.challenges
  add column if not exists prize text,
  add column if not exists prize_en text,
  add column if not exists goal_per_day boolean not null default false,
  add column if not exists winner_id uuid references public.profiles(id) on delete set null,
  add column if not exists winner_name text,
  add column if not exists won_at timestamptz,
  add column if not exists won_steps int;

create or replace function public.award_challenge_winner()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  p record;
  c record;
  total int;
  first_day date;
  last_day date;
begin
  select id, full_name, health_enabled, is_banned into p
    from profiles where id = new.profile_id;
  if p.id is null or not p.health_enabled or p.is_banned then
    return new;
  end if;

  for c in
    select * from challenges
     where is_active
       and winner_id is null
       and challenge_type = 'steps'
       and start_at <= now() and end_at >= now()
  loop
    first_day := (c.start_at at time zone 'Asia/Jerusalem')::date;
    last_day  := (c.end_at   at time zone 'Asia/Jerusalem')::date;
    continue when new.date < first_day or new.date > last_day;

    if c.goal_per_day then
      total := new.steps;
    else
      select coalesce(sum(steps), 0) into total
        from daily_steps
       where profile_id = new.profile_id
         and date between first_day and last_day;
    end if;

    if total >= c.goal then
      update challenges
         set winner_id = p.id,
             winner_name = coalesce(nullif(trim(p.full_name), ''), 'תושב/ת'),
             won_at = now(),
             won_steps = total
       where id = c.id and winner_id is null;
    end if;
  end loop;

  return new;
end;
$$;

revoke all on function public.award_challenge_winner() from public, anon, authenticated;

drop trigger if exists daily_steps_award_winner on public.daily_steps;
create trigger daily_steps_award_winner
  after insert or update of steps on public.daily_steps
  for each row execute function public.award_challenge_winner();
