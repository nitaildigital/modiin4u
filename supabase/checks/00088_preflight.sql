-- ============================================================
-- Modiin4u — read-only check before applying migration 00088
--
-- One SELECT, so it changes nothing and the Supabase SQL Editor shows all
-- of it in one table (the editor shows only the last statement's result and
-- does not take psql's backslash commands). Also runs with psql:
--
--     psql "$SUPABASE_DB_URL" -f supabase/checks/00088_preflight.sql
--
-- Each row: what is checked, what production has, what 00088 needs, and
-- ok = whether they agree. Every row should say ok = true before 00088 is
-- applied; a false one is to be looked at, not worked around.
-- ============================================================

with
cols as (
  select table_name, column_name, data_type
    from information_schema.columns
   where table_schema = 'public'
),
fns as (
  select p.proname
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public'
),
chk(n, section, item, actual, expected, ok) as (
  -- 1. Competitions, in any state: none running, ideally none at all.
  select 1, 'competitions', 'all competitions',
         (select count(*)::text from public.challenges), '0 (or none running)',
         (select count(*) = 0 from public.challenges)
         or not exists (select 1 from public.challenges
                         where is_active and start_at <= now() and end_at >= now())
  union all
  select 2, 'competitions', 'running now',
         (select count(*)::text from public.challenges where is_active and start_at <= now() and end_at >= now()),
         '0', (select count(*) = 0 from public.challenges where is_active and start_at <= now() and end_at >= now())
  union all
  select 3, 'competitions', 'upcoming',
         (select count(*)::text from public.challenges where is_active and start_at > now()),
         '0', (select count(*) = 0 from public.challenges where is_active and start_at > now())
  union all
  select 4, 'competitions', 'every competition (id · name · active · start → end · winner)',
         coalesce((select string_agg(id || ' · ' || name || ' · ' || is_active || ' · ' || start_at || ' → ' || end_at
                                     || ' · ' || coalesce(winner_name, '-'), E'\n' order by start_at)
                     from public.challenges), 'none'),
         'none', not exists (select 1 from public.challenges)
  union all
  select 5, 'competitions', 'challenge_participants rows',
         (select count(*)::text from public.challenge_participants), 'any (unused)', true
  union all
  select 6, 'competitions', 'competition notifications in push_campaigns',
         (select count(*)::text from public.push_campaigns where source_type like 'challenge%'), 'any', true

  -- 2. Daily steps: untouched by 00088, shown for the record.
  union all
  select 7, 'daily steps', 'rows · people · first → last date',
         (select count(*) || ' · ' || count(distinct profile_id) || ' · ' || coalesce(min(date)::text, '-') || ' → ' || coalesce(max(date)::text, '-')
            from public.daily_steps), 'any', true
  union all
  select 8, 'daily steps', 'people with step sharing on',
         (select count(*)::text from public.profiles where health_enabled), 'any', true

  -- 3. What 00088 removes must be there, what it adds must not.
  union all
  select 9, 'removed by 00088', 'trigger daily_steps_award_winner',
         (select count(*)::text from pg_trigger where tgname = 'daily_steps_award_winner' and not tgisinternal),
         '1', (select count(*) = 1 from pg_trigger where tgname = 'daily_steps_award_winner' and not tgisinternal)
  union all
  select 10, 'removed by 00088', 'function award_challenge_winner',
         (select count(*)::text from fns where proname = 'award_challenge_winner'), '1',
         (select count(*) = 1 from fns where proname = 'award_challenge_winner')
  union all
  select 11, 'added by 00088', 'table challenge_steps',
         coalesce(to_regclass('public.challenge_steps')::text, 'absent'), 'absent',
         to_regclass('public.challenge_steps') is null
  union all
  select 12, 'added by 00088', 'its functions',
         coalesce((select string_agg(proname, ', ') from fns
                    where proname in ('record_challenge_steps', 'challenge_scores', 'challenge_leaderboard_people',
                                      'challenge_leaderboard_neighborhoods', 'settle_challenge_winners')), 'absent'),
         'absent',
         not exists (select 1 from fns where proname in ('record_challenge_steps', 'challenge_scores',
                     'challenge_leaderboard_people', 'challenge_leaderboard_neighborhoods', 'settle_challenge_winners'))

  -- 4. What 00088 relies on, as it uses it.
  union all
  select 13, 'relies on', 'pg_cron installed',
         coalesce((select extversion from pg_extension where extname = 'pg_cron'), 'absent'), 'a version',
         exists (select 1 from pg_extension where extname = 'pg_cron')
  union all
  select 14, 'relies on', 'cron job settle-challenge-winners not yet there',
         (select count(*)::text from cron.job where jobname = 'settle-challenge-winners'), '0',
         (select count(*) = 0 from cron.job where jobname = 'settle-challenge-winners')
  union all
  select 15, 'relies on', 'functions is_admin, step_today',
         (select string_agg(proname, ', ' order by proname) from fns where proname in ('is_admin', 'step_today')),
         'is_admin, step_today',
         (select count(distinct proname) = 2 from fns where proname in ('is_admin', 'step_today'))
  union all
  select 16, 'relies on', 'challenges columns',
         (select string_agg(column_name || ':' || data_type, ', ' order by column_name) from cols
           where table_name = 'challenges' and column_name in ('id', 'name', 'challenge_type', 'goal', 'goal_per_day',
                 'is_active', 'start_at', 'end_at', 'prize', 'prize_en', 'winner_id', 'winner_name', 'won_at', 'won_steps')),
         '14 columns',
         (select count(*) = 14 from cols where table_name = 'challenges' and column_name in ('id', 'name', 'challenge_type',
                 'goal', 'goal_per_day', 'is_active', 'start_at', 'end_at', 'prize', 'prize_en', 'winner_id',
                 'winner_name', 'won_at', 'won_steps'))
  union all
  select 17, 'relies on', 'profiles columns',
         (select string_agg(column_name, ', ' order by column_name) from cols
           where table_name = 'profiles' and column_name in ('id', 'full_name', 'avatar_url', 'health_enabled',
                 'is_banned', 'neighborhood_id')),
         '6 columns',
         (select count(*) = 6 from cols where table_name = 'profiles' and column_name in ('id', 'full_name',
                 'avatar_url', 'health_enabled', 'is_banned', 'neighborhood_id'))
  union all
  select 18, 'relies on', 'neighborhoods columns id, name',
         (select string_agg(column_name, ', ' order by column_name) from cols
           where table_name = 'neighborhoods' and column_name in ('id', 'name')),
         'id, name',
         (select count(*) = 2 from cols where table_name = 'neighborhoods' and column_name in ('id', 'name'))
  union all
  select 19, 'relies on', 'push_campaigns columns the winner insert writes',
         (select string_agg(column_name, ', ' order by column_name) from cols
           where table_name = 'push_campaigns' and column_name in ('title', 'body', 'title_en', 'body_en', 'deep_link',
                 'status', 'scheduled_at', 'audience_type', 'audience_filter', 'source_type', 'source_id')),
         '11 columns',
         (select count(*) = 11 from cols where table_name = 'push_campaigns' and column_name in ('title', 'body',
                 'title_en', 'body_en', 'deep_link', 'status', 'scheduled_at', 'audience_type', 'audience_filter',
                 'source_type', 'source_id'))
  union all
  select 20, 'relies on', 'push_campaigns NOT NULL columns without a default the insert leaves out',
         coalesce((select string_agg(c.column_name, ', ') from information_schema.columns c
                    where c.table_schema = 'public' and c.table_name = 'push_campaigns'
                      and c.is_nullable = 'NO' and c.column_default is null
                      and c.column_name not in ('title', 'body', 'title_en', 'body_en', 'deep_link', 'status',
                          'scheduled_at', 'audience_type', 'audience_filter', 'source_type', 'source_id')), 'none'),
         'none',
         not exists (select 1 from information_schema.columns c
                      where c.table_schema = 'public' and c.table_name = 'push_campaigns'
                        and c.is_nullable = 'NO' and c.column_default is null
                        and c.column_name not in ('title', 'body', 'title_en', 'body_en', 'deep_link', 'status',
                            'scheduled_at', 'audience_type', 'audience_filter', 'source_type', 'source_id'))
  union all
  select 21, 'relies on', 'push_status has scheduled',
         (select string_agg(e.enumlabel, ', ' order by e.enumsortorder) from pg_enum e
            join pg_type t on t.oid = e.enumtypid where t.typname = 'push_status'),
         'includes scheduled',
         exists (select 1 from pg_enum e join pg_type t on t.oid = e.enumtypid
                  where t.typname = 'push_status' and e.enumlabel = 'scheduled')
  union all
  select 22, 'relies on', 'roles anon, authenticated, service_role',
         (select string_agg(rolname, ', ' order by rolname) from pg_roles
           where rolname in ('anon', 'authenticated', 'service_role')),
         'anon, authenticated, service_role',
         (select count(*) = 3 from pg_roles where rolname in ('anon', 'authenticated', 'service_role'))
  union all
  select 23, 'relies on', 'migrations before it (00087 marker: articles.banners)',
         (select count(*)::text from cols where table_name = 'articles' and column_name = 'banners'), '1',
         (select count(*) = 1 from cols where table_name = 'articles' and column_name = 'banners')

  -- 5. The panel's update gate, for the rollout.
  union all
  select 24, 'update gate', 'app_settings now',
         coalesce((select string_agg(key || ' = ' || value::text, E'\n' order by key) from public.app_settings
                    where key in ('min_build_android', 'min_build_ios', 'force_update_android',
                                  'force_update_ios', 'store_url_android', 'store_url_ios')), 'none'),
         'for the record', true
)
select section, item, actual, expected, ok from chk order by n;
