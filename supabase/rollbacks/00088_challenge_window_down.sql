-- ============================================================
-- Modiin4u — rollback of migration 00088 (NOT a migration)
--
-- Kept outside supabase/migrations so tool/run_migrations.py never runs it.
-- Run by hand, in one transaction, only if 00088 has to be undone:
--
--     psql "$DB_URL" -v ON_ERROR_STOP=1 -1 -f supabase/rollbacks/00088_challenge_window_down.sql
--
-- What it does:
--   1. Stops the ten-minute winner job.
--   2. Removes the functions 00088 added. An app build that calls them
--      (the one made with 00088) then gets errors on its competition card
--      and its competition leaderboards while a competition runs — so roll
--      back the app's release with it, or keep the database as it is.
--   3. Puts back the first-to-goal winner exactly as 00060 left it: the
--      function, word for word, and its trigger on daily_steps.
--   4. KEEPS challenge_steps and every row in it. Residents' competition
--      figures are not thrown away by a rollback; with the functions gone
--      nothing writes or reads them. Dropping the table is step 5, commented
--      out, for when it is certain nothing in them is wanted.
--
-- What it does not undo, on purpose: a winner already named by
-- settle_challenge_winners (challenges.winner_*) and the notifications it
-- queued stay — they were announced to residents. With the old trigger
-- back, a competition still running is judged again by the old rule from
-- the next saved day: the first to reach its goal by whole days.
-- ============================================================

-- ─── 1. The job ───
select cron.unschedule('settle-challenge-winners')
 where exists (select 1 from cron.job where jobname = 'settle-challenge-winners');

-- ─── 2. 00088's functions ───
drop function if exists public.settle_challenge_winners();
drop function if exists public.challenge_participant_counts();
drop function if exists public.end_challenge_now(uuid);
drop function if exists public.challenge_leaderboard_people(uuid, int);
drop function if exists public.challenge_leaderboard_neighborhoods(uuid, int);
drop function if exists public.challenge_scores(uuid);
drop function if exists public.record_challenge_steps(uuid, jsonb);

-- ─── 3. The first-to-goal winner, as 00060 defined it ───
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
  won int;
  v_name text;
  v_prize text;
  v_prize_en text;
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

    continue when total < c.goal;

    v_name := coalesce(nullif(trim(p.full_name), ''), 'תושב/ת');
    update challenges
       set winner_id = p.id, winner_name = v_name, won_at = now(), won_steps = total
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
      jsonb_build_object('profile_ids', jsonb_build_array(p.id)),
      'challenge_win', c.id
    ), (
      'יש זוכה בתחרות',
      v_name || ' זכה/תה ב' || c.name || coalesce(' · ' || v_prize, ''),
      'The competition has a winner',
      v_name || ' won ' || c.name || coalesce(' · ' || v_prize_en, ''),
      '/steps', 'scheduled', now(), 'all_but',
      jsonb_build_object('profile_ids', jsonb_build_array(p.id)),
      'challenge_result', c.id
    );
  end loop;

  return new;
end;
$$;

revoke all on function public.award_challenge_winner() from public, anon, authenticated;

drop trigger if exists daily_steps_award_winner on public.daily_steps;
create trigger daily_steps_award_winner
  after insert or update of steps on public.daily_steps
  for each row execute function public.award_challenge_winner();

-- ─── 4. challenge_steps stays, with its rows ───
-- Nobody can write it without record_challenge_steps; residents can still
-- read their own rows and admins all (its policy), which is harmless.

-- ─── 5. Only when its figures are certainly not wanted ───
-- drop table if exists public.challenge_steps;
