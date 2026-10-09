-- ============================================================
-- Modiin4u — Migration 00074
-- Less work for the database per request (9 Oct)
--
-- On 9 Oct the project was restricted and its CPU saturated. The reads
-- and writes that grow worst with use, from a review of the code:
--
--   1. The step leaderboards filter `daily_steps` by date, and the only
--      index starts with the person: every leaderboard read the whole
--      table, which gains a row per walker per day.
--   2. The unread-messages badge (my_conversations) asked for "mine as a
--      resident OR a business of mine" in one condition, which no index
--      answers: every call read every conversation, checking ownership
--      row by row — on each return to the app. Now the two halves, each
--      by its own index (idx_conversations_profile, idx_businesses_owner,
--      idx_conversations_business). Same rows, same columns.
--   3. Lookups made on writes with no index behind them: a chat message
--      looks for its pending notification by source; a comment or review
--      counts the notifications its device opened.
--   4. Every counted article view updates the article row, which ran the
--      notification trigger over the whole row (body included). The
--      trigger now runs only when a column it reads changes.
--   5. pg_cron keeps a row per run — the notification sender runs every
--      minute — and nothing removed them (9,924 rows in a week). A week
--      is kept.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Leaderboards ───
create index if not exists idx_daily_steps_date
  on public.daily_steps (date) include (profile_id, steps);

-- ─── 2. Conversations ───
create or replace function public.my_conversations()
returns table (
  id              uuid,
  business_id     uuid,
  profile_id      uuid,
  as_business     boolean,
  other_name      text,
  other_avatar    text,
  job_title       text,
  last_message    text,
  last_message_at timestamptz,
  unread          int
)
language sql
stable
security definer
set search_path = public
as $$
  with mine as (
    -- As the resident.
    select c.*, false as as_business
      from conversations c
     where c.profile_id = auth.uid()
    union all
    -- As the owner of the business — a conversation with one's own
    -- business as the resident is already above.
    select c.*, true as as_business
      from conversations c
     where c.business_id in (select b.id from businesses b where b.owner_id = auth.uid())
       and c.profile_id is distinct from auth.uid()
  )
  select c.id, c.business_id, c.profile_id,
         c.as_business,
         case when c.as_business then p.full_name else b.name end,
         case when c.as_business then p.avatar_url else b.logo_url end,
         j.title,
         c.last_message, coalesce(c.last_message_at, c.created_at),
         (select count(*)::int from messages m
           where m.conversation_id = c.id
             and m.sender_id is distinct from auth.uid()
             and m.created_at > coalesce(
                   case when c.as_business then c.business_last_read_at
                        else c.resident_last_read_at end,
                   '-infinity'::timestamptz))
    from mine c
    join businesses b on b.id = c.business_id
    left join profiles p on p.id = c.profile_id
    left join jobs j on j.id = c.job_id
   where auth.uid() is not null
   order by coalesce(c.last_message_at, c.created_at) desc;
$$;

revoke all on function public.my_conversations() from public, anon;
grant execute on function public.my_conversations() to authenticated;

-- ─── 3. Lookups on writes ───
create index if not exists idx_push_campaigns_source
  on public.push_campaigns (source_type, source_id);
create index if not exists idx_push_events_device
  on public.push_events (device_id, created_at);

-- ─── 4. The article notification trigger, on the columns it reads ───
-- queue_publish_push('article') reads status, notify_on_publish,
-- push_campaign_id, title, featured_image and mobile_image. A view (the
-- counters) or an SEO edit changes none of them.
drop trigger if exists articles_queue_push on public.articles;
create trigger articles_queue_push
  before insert or update of status, notify_on_publish, push_campaign_id, title, featured_image, mobile_image
  on public.articles
  for each row execute function public.queue_publish_push('article');

-- ─── 5. pg_cron's run history ───
select cron.unschedule('purge-cron-history')
 where exists (select 1 from cron.job where jobname = 'purge-cron-history');
select cron.schedule(
  'purge-cron-history',
  '20 2 * * *',
  $$ delete from cron.job_run_details where end_time < now() - interval '7 days' $$
);
