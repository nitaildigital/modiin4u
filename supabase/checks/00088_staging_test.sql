-- ============================================================
-- Modiin4u — migration 00088 on a real Supabase STAGING project
--
-- NEVER on production. It writes test accounts, competitions and step
-- figures. It refuses to run unless the database has the table
-- public.m4u_staging_marker, which exists only where someone created it by
-- hand on a staging project:
--
--     create table public.m4u_staging_marker (made_at timestamptz default now());
--
-- Staging must have every migration applied, 00088 included. Then, in order:
--
--   part 1 (this file, section A): fixtures and every check that does not
--          need the clock — RLS under Supabase's own roles, the window,
--          rankings, refusals.
--   part 2 (section B, run 10+ minutes later): pg_cron's settlement and the
--          winner's notifications, as the real job did them.
--   part 3 (section C): removes everything this test made.
--
-- With psql:  psql "$STAGING_DB_URL" -v ON_ERROR_STOP=1 -f <file>, running
-- one section at a time (copy it), or paste a section into the staging
-- project's SQL Editor. Each section ends by listing its results.
-- ============================================================


-- ════════════════════════ A. Fixtures and checks ════════════════════════

do $$ begin
  if to_regclass('public.m4u_staging_marker') is null then
    raise exception 'Not a staging database (no public.m4u_staging_marker). Stopped; nothing was written.';
  end if;
  if to_regclass('public.challenge_steps') is null then
    raise exception 'Migration 00088 is not applied here. Stopped; nothing was written.';
  end if;
end $$;

create table if not exists public.m4u_t_results (n serial, label text, ok boolean, detail text);
create or replace function public.m4u_t_check(label text, got text, want text) returns void
language sql as $$
  insert into public.m4u_t_results (label, ok, detail)
  values (label, got is not distinct from want, 'got ' || coalesce(got, '∅') || ' want ' || coalesce(want, '∅'))
$$;
grant all on public.m4u_t_results to authenticated, anon;
grant usage on sequence public.m4u_t_results_n_seq to authenticated, anon;
grant execute on function public.m4u_t_check(text, text, text) to authenticated, anon;

-- Test accounts (their profiles come from handle_new_user).
insert into auth.users (id, instance_id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values
 ('11111111-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm4u-test-dana@example.invalid',   '{"full_name":"TEST Dana"}',   now(), now()),
 ('11111111-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm4u-test-yossi@example.invalid',  '{"full_name":"TEST Yossi"}',  now(), now()),
 ('11111111-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm4u-test-noa@example.invalid',    '{"full_name":"TEST Noa"}',    now(), now()),
 ('11111111-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm4u-test-off@example.invalid',    '{"full_name":"TEST Off"}',    now(), now()),
 ('11111111-0000-4000-8000-000000000009', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm4u-test-admin@example.invalid',  '{"full_name":"TEST Admin"}',  now(), now());
insert into public.neighborhoods (id, name) values
 ('11111111-0000-4000-8000-0000000000a1', 'TEST North'), ('11111111-0000-4000-8000-0000000000a2', 'TEST South');
update public.profiles set health_enabled = true, is_banned = false, neighborhood_id = '11111111-0000-4000-8000-0000000000a1'
 where id in ('11111111-0000-4000-8000-000000000001', '11111111-0000-4000-8000-000000000002');
update public.profiles set health_enabled = true, neighborhood_id = '11111111-0000-4000-8000-0000000000a2'
 where id = '11111111-0000-4000-8000-000000000003';
update public.profiles set health_enabled = false where id = '11111111-0000-4000-8000-000000000004';
insert into public.admin_users (profile_id, role_id)
select '11111111-0000-4000-8000-000000000009', id from public.admin_roles order by created_at limit 1;

-- Competitions, off for notifications so nothing is announced.
insert into public.challenges (id, name, goal, start_at, end_at, is_active, goal_per_day, prize, notify_on_publish) values
 ('11111111-0000-4000-8000-00000000c001', 'TEST running',      50000, now() - interval '1 day',  now() + interval '1 day',   true,  false, 'TEST prize', false),
 ('11111111-0000-4000-8000-00000000c002', 'TEST not started',  50000, now() + interval '1 hour', now() + interval '2 days',  true,  false, null, false),
 ('11111111-0000-4000-8000-00000000c003', 'TEST switched off', 50000, now() - interval '1 day',  now() + interval '1 day',   false, false, null, false),
 ('11111111-0000-4000-8000-00000000c005', 'TEST ended 3h ago', 50000, now() - interval '2 days', now() - interval '3 hours', true,  false, 'TEST bike', false);

-- As Dana, through Supabase's own role and claims.
select set_config('request.jwt.claims', '{"sub":"11111111-0000-4000-8000-000000000001","role":"authenticated"}', false);
select set_config('request.jwt.claim.sub', '11111111-0000-4000-8000-000000000001', false);
set role authenticated;
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c001', jsonb_build_array(jsonb_build_object('date', public.step_today(), 'steps', 5000, 'metres', 3500)));
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c001', jsonb_build_array(jsonb_build_object('date', public.step_today(), 'steps', 4000)));
select public.m4u_t_check('a lower resend keeps the highest', (select steps::text from public.challenge_steps where challenge_id = '11111111-0000-4000-8000-00000000c001'), '5000');
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c001', jsonb_build_array(
  jsonb_build_object('date', public.step_today() - 5, 'steps', 9999), jsonb_build_object('date', public.step_today() + 1, 'steps', 9999)));
select public.m4u_t_check('dates outside the competition refused', (select count(*)::text from public.challenge_steps), '1');
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c002', jsonb_build_array(jsonb_build_object('date', public.step_today(), 'steps', 1000)));
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c003', jsonb_build_array(jsonb_build_object('date', public.step_today(), 'steps', 1000)));
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c005', jsonb_build_array(jsonb_build_object('date', public.step_today() - 1, 'steps', 1000)));
select public.m4u_t_check('not started, switched off, long ended: refused', (select count(*)::text from public.challenge_steps), '1');
do $$ begin
  insert into public.challenge_steps (challenge_id, profile_id, date, steps)
  values ('11111111-0000-4000-8000-00000000c001', auth.uid(), current_date, 99999);
  perform public.m4u_t_check('direct insert refused (grants, RLS)', 'allowed', 'refused');
exception when insufficient_privilege then
  perform public.m4u_t_check('direct insert refused (grants, RLS)', 'refused', 'refused');
end $$;
reset role;

select set_config('request.jwt.claims', '{"sub":"11111111-0000-4000-8000-000000000002","role":"authenticated"}', false);
select set_config('request.jwt.claim.sub', '11111111-0000-4000-8000-000000000002', false);
set role authenticated;
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c001', jsonb_build_array(
  jsonb_build_object('date', public.step_today() - 1, 'steps', 3000), jsonb_build_object('date', public.step_today(), 'steps', 5000)));
select public.m4u_t_check('a resident reads only their own rows', (select count(distinct profile_id)::text from public.challenge_steps), '1');
reset role;

select set_config('request.jwt.claims', '{"sub":"11111111-0000-4000-8000-000000000003","role":"authenticated"}', false);
select set_config('request.jwt.claim.sub', '11111111-0000-4000-8000-000000000003', false);
set role authenticated;
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c001', jsonb_build_array(jsonb_build_object('date', public.step_today(), 'steps', 6000)));
reset role;
select set_config('request.jwt.claims', '{"sub":"11111111-0000-4000-8000-000000000004","role":"authenticated"}', false);
select set_config('request.jwt.claim.sub', '11111111-0000-4000-8000-000000000004', false);
set role authenticated;
select public.record_challenge_steps('11111111-0000-4000-8000-00000000c001', jsonb_build_array(jsonb_build_object('date', public.step_today(), 'steps', 90000)));
reset role;
-- Noa reached 6000 after Dana's 5000 was raised to 6000 below: a tie Dana wins.
update public.challenge_steps set steps = 6000, updated_at = now() - interval '30 minutes'
 where profile_id = '11111111-0000-4000-8000-000000000001';

select set_config('request.jwt.claims', '{"sub":"11111111-0000-4000-8000-000000000009","role":"authenticated"}', false);
select set_config('request.jwt.claim.sub', '11111111-0000-4000-8000-000000000009', false);
set role authenticated;
select public.m4u_t_check('an admin reads every row', (select count(*)::text from public.challenge_steps where challenge_id = '11111111-0000-4000-8000-00000000c001'), '5');
select public.m4u_t_check('people ranking: total, ties by who was first, sharing off left out',
  (select string_agg(full_name || ':' || total_steps, ' ') from public.challenge_leaderboard_people('11111111-0000-4000-8000-00000000c001')),
  'TEST Yossi:8000 TEST Dana:6000 TEST Noa:6000');
select public.m4u_t_check('neighbourhood ranking',
  (select string_agg(name || ':' || total_steps || '/' || member_count, ' ') from public.challenge_leaderboard_neighborhoods('11111111-0000-4000-8000-00000000c001')
    where name like 'TEST %'),
  'TEST North:14000/2 TEST South:6000/1');
reset role;

set role anon;
do $$ begin
  perform * from public.challenge_leaderboard_people('11111111-0000-4000-8000-00000000c001');
  perform public.m4u_t_check('anon cannot call the rankings', 'allowed', 'refused');
exception when insufficient_privilege then
  perform public.m4u_t_check('anon cannot call the rankings', 'refused', 'refused');
end $$;
do $$ begin
  perform public.settle_challenge_winners();
  perform public.m4u_t_check('anon cannot settle winners', 'allowed', 'refused');
exception when insufficient_privilege then
  perform public.m4u_t_check('anon cannot settle winners', 'refused', 'refused');
end $$;
reset role;

-- For part 2: figures of the competition that ended three hours ago, as they
-- would have been sent while it ran. The real cron job names its winner.
insert into public.challenge_steps (challenge_id, profile_id, date, steps, updated_at) values
 ('11111111-0000-4000-8000-00000000c005', '11111111-0000-4000-8000-000000000004', public.step_today() - 1, 40000, now() - interval '5 hours'),
 ('11111111-0000-4000-8000-00000000c005', '11111111-0000-4000-8000-000000000002', public.step_today() - 1, 20000, now() - interval '4 hours'),
 ('11111111-0000-4000-8000-00000000c005', '11111111-0000-4000-8000-000000000001', public.step_today() - 1, 20000, now() - interval '6 hours');

select public.m4u_t_check('the settlement job is scheduled every 10 minutes',
  (select schedule from cron.job where jobname = 'settle-challenge-winners'), '*/10 * * * *');
select public.m4u_t_check('the old first-to-goal trigger is gone',
  (select count(*)::text from pg_trigger where tgname = 'daily_steps_award_winner'), '0');

select (case when ok then 'PASS ' else 'FAIL ' end) || label || case when ok then '' else '  (' || detail || ')' end as result
  from public.m4u_t_results order by n;


-- ═══════════ B. Ten minutes or more later: the real cron run ═══════════
-- (Run on its own.)

-- select public.m4u_t_check('cron named the winner: most steps, tie to the first, sharing off left out',
--   (select winner_name || ':' || won_steps from public.challenges where id = '11111111-0000-4000-8000-00000000c005'),
--   'TEST Dana:20000');
-- select public.m4u_t_check('the running competition has no winner',
--   (select coalesce(winner_name, 'none') from public.challenges where id = '11111111-0000-4000-8000-00000000c001'), 'none');
-- select public.m4u_t_check('the job ran and succeeded',
--   (select status from cron.job_run_details d join cron.job j on j.jobid = d.jobid
--     where j.jobname = 'settle-challenge-winners' order by d.start_time desc limit 1), 'succeeded');
-- select public.m4u_t_check('two notifications: the winner, and everyone else',
--   (select string_agg(source_type || '/' || audience_type, ' ' order by source_type desc)
--      from public.push_campaigns where source_id = '11111111-0000-4000-8000-00000000c005'),
--   'challenge_win/person challenge_result/all_but');
-- -- What the push sender did with them (status sent; sent_count = devices
-- -- registered on staging that match):
-- select title_en, audience_type, status, sent_count, failed_count
--   from public.push_campaigns where source_id = '11111111-0000-4000-8000-00000000c005';
-- select (case when ok then 'PASS ' else 'FAIL ' end) || label || case when ok then '' else '  (' || detail || ')' end as result
--   from public.m4u_t_results order by n;


-- ═══════════════════════ C. Clean up (staging) ═══════════════════════

-- delete from public.push_campaigns where source_id in (select id from public.challenges where name like 'TEST %');
-- delete from public.challenges where id::text like '11111111-0000-4000-8000-%';
-- delete from public.admin_users where profile_id = '11111111-0000-4000-8000-000000000009';
-- delete from public.challenge_steps where profile_id::text like '11111111-0000-4000-8000-%';
-- delete from public.daily_steps where profile_id::text like '11111111-0000-4000-8000-%';
-- delete from public.profiles where id::text like '11111111-0000-4000-8000-%';
-- delete from auth.users where id::text like '11111111-0000-4000-8000-%';
-- delete from public.neighborhoods where id::text like '11111111-0000-4000-8000-%';
-- drop function if exists public.m4u_t_check(text, text, text);
-- drop table if exists public.m4u_t_results;
