-- ============================================================
-- Modiin4u — Migration 00045
-- Push notifications: devices, automatic sends, the bell, opens
--
-- What the client was promised (2 Oct): anyone who installs the app or
-- allows notifications on the website receives them, with no account; each
-- device picks its topics, its neighbourhood and its language; each new
-- article, event or business is sent automatically to the people who chose
-- that topic, unless the panel's "send a notification" box was cleared;
-- deals and the rest stay manual; the panel shows how many it went to and
-- how many opened it; the bell keeps what was sent. Later the same day: a
-- resident is told when someone replies in a review conversation they are
-- part of (00039's replies).
--
-- 00016 put the topic switches on `profiles` and the tokens in
-- `device_tokens` keyed to a profile, so a device without an account had
-- nowhere to be recorded. A device is the unit here instead.
--
-- The sending itself is the `push-dispatch` Edge Function
-- (supabase/functions/push-dispatch), called once a minute by pg_cron while
-- a campaign is due. Its secret is in the vault as `push_dispatch_secret`;
-- tool/setup_push.py puts it there and in the function's environment.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Devices ───
--
-- One row per installation or browser. The token Firebase hands back is the
-- key: it changes on reinstall, and whoever holds it is the device, so the
-- app writes its own row through `register_push_device` without signing in.
-- Residents cannot read this table at all.

create table if not exists public.push_devices (
  id                  uuid primary key default gen_random_uuid(),
  token               text not null unique,
  platform            text not null check (platform in ('android', 'ios', 'web')),
  locale              text not null default 'he' check (locale in ('he', 'en')),
  -- The app's own master switch. Off, nothing is sent whatever the topics say.
  enabled             boolean not null default true,
  notify_news         boolean not null default true,
  notify_events       boolean not null default true,
  notify_businesses   boolean not null default true,
  notify_deals        boolean not null default true,
  notify_realestate   boolean not null default false,
  notify_neighborhood boolean not null default true,
  -- Replies in a review conversation this person is part of.
  notify_replies      boolean not null default true,
  neighborhood_id     uuid references public.neighborhoods(id) on delete set null,
  -- Who is signed in on this device, if anyone — only so a reply can reach
  -- the person it concerns. Set from the session, never from the caller,
  -- and cleared when they sign out (the app registers again).
  profile_id          uuid references public.profiles(id) on delete set null,
  app_version         text,
  -- False once Firebase says the token is gone (the app was uninstalled or
  -- the browser revoked permission). Registering again sets it back.
  is_active           boolean not null default true,
  last_seen_at        timestamptz not null default now(),
  created_at          timestamptz not null default now()
);

comment on table public.push_devices is
  'One row per app installation or browser that allowed notifications. '
  'Written only through register_push_device().';

create index if not exists idx_push_devices_sendable
  on public.push_devices (neighborhood_id)
  where enabled and is_active;

create index if not exists idx_push_devices_profile
  on public.push_devices (profile_id)
  where profile_id is not null;

alter table public.push_devices enable row level security;

drop policy if exists "push_devices_admin_read" on public.push_devices;
create policy "push_devices_admin_read"
  on public.push_devices for select
  using (is_admin());

-- 00016's table was never written to — nothing registered a token — and its
-- rows needed a profile, which the promise above rules out. Dropped only
-- while it is still empty, so a re-run can never take real rows with it.
do $$
begin
  if to_regclass('public.device_tokens') is not null
     and not exists (select 1 from public.device_tokens) then
    drop table public.device_tokens;
  end if;
end $$;

create or replace function public.register_push_device(
  p_token           text,
  p_platform        text,
  p_locale          text,
  p_enabled         boolean,
  p_news            boolean,
  p_events          boolean,
  p_businesses      boolean,
  p_deals           boolean,
  p_realestate      boolean,
  p_neighborhood    boolean,
  p_neighborhood_id uuid,
  p_app_version     text,
  p_replies         boolean default true
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_token is null or length(p_token) not between 20 and 4096 then
    raise exception 'not a device token' using errcode = '22023';
  end if;

  insert into push_devices as d (
    token, platform, locale, enabled,
    notify_news, notify_events, notify_businesses, notify_deals,
    notify_realestate, notify_neighborhood, neighborhood_id, app_version,
    notify_replies, profile_id
  ) values (
    p_token, p_platform, coalesce(p_locale, 'he'), coalesce(p_enabled, true),
    coalesce(p_news, true), coalesce(p_events, true),
    coalesce(p_businesses, true), coalesce(p_deals, true),
    coalesce(p_realestate, false), coalesce(p_neighborhood, true),
    p_neighborhood_id, p_app_version,
    coalesce(p_replies, true), auth.uid()
  )
  on conflict (token) do update set
    platform            = excluded.platform,
    locale              = excluded.locale,
    enabled             = excluded.enabled,
    notify_news         = excluded.notify_news,
    notify_events       = excluded.notify_events,
    notify_businesses   = excluded.notify_businesses,
    notify_deals        = excluded.notify_deals,
    notify_realestate   = excluded.notify_realestate,
    notify_neighborhood = excluded.notify_neighborhood,
    neighborhood_id     = excluded.neighborhood_id,
    app_version         = excluded.app_version,
    notify_replies      = excluded.notify_replies,
    profile_id          = excluded.profile_id,
    is_active           = true,
    last_seen_at        = now();
end;
$$;

grant execute on function public.register_push_device(
  text, text, text, boolean, boolean, boolean, boolean, boolean, boolean,
  boolean, uuid, text, boolean
) to anon, authenticated;

-- ─── 2. Campaigns: English, where they came from, failures ───

alter table public.push_campaigns
  add column if not exists title_en     text,
  add column if not exists body_en      text,
  -- Set on the automatic ones: 'article' | 'event' | 'business' and its id.
  add column if not exists source_type  text,
  add column if not exists source_id    uuid,
  add column if not exists failed_count int not null default 0;

comment on column public.push_campaigns.title_en is
  'Optional. A device set to English gets this; without it, the Hebrew.';
comment on column public.push_campaigns.sent_count is
  'Devices Firebase accepted the message for. Not proof it was seen.';

create index if not exists idx_push_campaigns_due
  on public.push_campaigns (scheduled_at)
  where status = 'scheduled';

create index if not exists idx_push_campaigns_sent
  on public.push_campaigns (sent_at desc)
  where status = 'sent';

-- Who a campaign is for, in one place: the sender, the bell and the panel's
-- estimate all ask this. `audience_type`:
--   all           everyone
--   topic         {"topic": news|events|businesses|deals|realestate}
--   neighborhood  {"neighborhood_id": …}, for devices that chose that
--                 neighbourhood and kept its updates on
--   profiles      {"profile_ids": [...]}, the devices those people are signed
--                 in on and that kept replies on — a reply notification;
--                 not in the panel
--   device        {"device_id": …}, one device — for testing, not in the panel
-- The device's master switch and token state are the sender's to check; the
-- bell shows history whatever they are.
create or replace function public.push_matches(c public.push_campaigns, d public.push_devices)
returns boolean
language sql
immutable
as $$
  select case c.audience_type
    when 'all' then true
    when 'topic' then case c.audience_filter ->> 'topic'
      when 'news'       then d.notify_news
      when 'events'     then d.notify_events
      when 'businesses' then d.notify_businesses
      when 'deals'      then d.notify_deals
      when 'realestate' then d.notify_realestate
      else false
    end
    when 'neighborhood' then d.notify_neighborhood
      and d.neighborhood_id::text = c.audience_filter ->> 'neighborhood_id'
    when 'profiles' then d.notify_replies and d.profile_id is not null
      and c.audience_filter -> 'profile_ids' ? d.profile_id::text
    when 'device' then d.id::text = c.audience_filter ->> 'device_id'
    else false
  end;
$$;

-- ─── 3. The sender's side (service role only) ───

-- Takes the campaigns that are due and marks them `sending`, so two runs
-- that overlap never send one twice. One stuck in `sending` for half an hour
-- means a run died part-way; it is marked failed rather than sent again,
-- because some devices may already have it.
create or replace function public.push_claim_due(p_limit int default 5)
returns setof public.push_campaigns
language plpgsql
security definer
set search_path = public
as $$
begin
  update push_campaigns
     set status = 'failed'
   where status = 'sending'
     and updated_at < now() - interval '30 minutes';

  -- "New article" six hours late is not news. Should the sender be down —
  -- or not yet deployed when this migration is run — automatic campaigns
  -- would otherwise pile up and all go out together the day it starts.
  -- Manual ones were timed by the client and still go.
  update push_campaigns
     set status = 'failed'
   where status = 'scheduled'
     and source_type is not null
     and scheduled_at < now() - interval '6 hours';

  return query
  update push_campaigns c
     set status = 'sending'
   where c.id in (
     select id from push_campaigns
      where status = 'scheduled' and scheduled_at <= now()
      order by scheduled_at
      limit p_limit
      for update skip locked
   )
  returning c.*;
end;
$$;

-- The devices one campaign goes to, a page at a time (by id, after p_after).
create or replace function public.push_recipients(
  p_campaign uuid,
  p_after    uuid default null,
  p_limit    int default 1000
)
returns table (id uuid, token text, platform text, locale text)
language sql
stable
security definer
set search_path = public
as $$
  select d.id, d.token, d.platform, d.locale
    from push_devices d, push_campaigns c
   where c.id = p_campaign
     and d.enabled and d.is_active
     and push_matches(c, d)
     and (p_after is null or d.id > p_after)
   order by d.id
   limit p_limit;
$$;

revoke execute on function public.push_claim_due(int) from public, anon, authenticated;
revoke execute on function public.push_recipients(uuid, uuid, int) from public, anon, authenticated;

-- How many devices a campaign would reach now — the panel's estimate while
-- composing. Administrators only.
create or replace function public.push_audience_size(
  p_audience_type   text,
  p_audience_filter jsonb
)
returns int
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  c push_campaigns;
  n int;
begin
  if not is_admin() then
    raise exception 'administrators only' using errcode = '42501';
  end if;
  c.audience_type := p_audience_type;
  c.audience_filter := p_audience_filter;
  select count(*) into n
    from push_devices d
   where d.enabled and d.is_active and push_matches(c, d);
  return n;
end;
$$;

grant execute on function public.push_audience_size(text, jsonb) to authenticated;

-- ─── 4. Opens, and later conversions ───
--
-- One row per device per campaign per kind, so a notification opened twice
-- counts once. 'open' is the only kind written today; 'call', 'directions'
-- and 'website' are ready for when the client confirms that is what he
-- means by a conversion.

create table if not exists public.push_events (
  id          uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.push_campaigns(id) on delete cascade,
  device_id   uuid references public.push_devices(id) on delete set null,
  kind        text not null check (kind in ('open', 'call', 'directions', 'website')),
  created_at  timestamptz not null default now(),
  unique (campaign_id, device_id, kind)
);

create index if not exists idx_push_events_campaign
  on public.push_events (campaign_id, kind);

alter table public.push_events enable row level security;

drop policy if exists "push_events_admin_read" on public.push_events;
create policy "push_events_admin_read"
  on public.push_events for select
  using (is_admin());

create or replace function public.record_push_event(
  p_campaign uuid,
  p_token    text,
  p_kind     text default 'open'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_device uuid;
  v_added  int;
begin
  -- Only a campaign that went out can be opened; anything else is noise.
  if not exists (select 1 from push_campaigns where id = p_campaign and status = 'sent') then
    return;
  end if;
  -- Without a known device there is nothing to count it once against, so it
  -- is not counted rather than counted every time.
  select id into v_device from push_devices where token = p_token;
  if v_device is null then
    return;
  end if;

  insert into push_events (campaign_id, device_id, kind)
  values (p_campaign, v_device, p_kind)
  on conflict (campaign_id, device_id, kind) do nothing;
  get diagnostics v_added = row_count;

  if v_added > 0 then
    if p_kind = 'open' then
      update push_campaigns set opened_count = opened_count + 1 where id = p_campaign;
    else
      update push_campaigns set click_count = click_count + 1 where id = p_campaign;
    end if;
  end if;
end;
$$;

grant execute on function public.record_push_event(uuid, text, text) to anon, authenticated;

-- ─── 5. The bell ───
--
-- What was sent in the last 60 days, newest first. Given a device, only what
-- that device's choices match; without one (a browser that has not allowed
-- notifications), what went to everyone or to a topic — never one
-- neighbourhood's, nor a test.

create or replace function public.push_feed(p_token text default null, p_limit int default 50)
returns table (
  id uuid, title text, body text, title_en text, body_en text,
  image_url text, deep_link text, sent_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.title, c.body, c.title_en, c.body_en, c.image_url, c.deep_link, c.sent_at
    from push_campaigns c
   where c.status = 'sent'
     and c.sent_at > now() - interval '60 days'
     and case
           when exists (select 1 from push_devices where token = p_token) then
             exists (select 1 from push_devices d where d.token = p_token and push_matches(c, d))
           else c.audience_type in ('all', 'topic')
         end
   order by c.sent_at desc
   limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

grant execute on function public.push_feed(text, int) to anon, authenticated;

-- ─── 6. Automatic sends when an article, event or business goes live ───
--
-- Each gets a "send a notification" box, on by default for new rows. Rows
-- already in the database get it off — they went live before notifications
-- existed, and an archived one put back must not announce itself as new —
-- except drafts (and events or businesses waiting for review), which have
-- never been out and are new when they are published. That is decided once,
-- when the column is added, so a re-run never undoes a box the client set.
--
-- Going live queues a campaign five minutes ahead, so a slip of the hand
-- can still be cancelled from the panel. Until it goes out, it follows the
-- row: a changed title changes its text, and clearing the box or taking the
-- row down cancels it. Once sent, the row keeps its campaign and is never
-- announced again.

do $$
declare
  t text;
begin
  foreach t in array array['articles', 'events', 'businesses'] loop
    if not exists (
      select 1 from information_schema.columns
       where table_schema = 'public' and table_name = t
         and column_name = 'notify_on_publish'
    ) then
      execute format(
        'alter table public.%I add column notify_on_publish boolean not null default false', t);
      execute format(
        'update public.%I set notify_on_publish = true where status::text in (''draft'', ''pending'')', t);
    end if;
    execute format(
      'alter table public.%I alter column notify_on_publish set default true', t);
    execute format(
      'alter table public.%I add column if not exists push_campaign_id uuid references public.push_campaigns(id) on delete set null', t);
  end loop;
end $$;

create or replace function public.queue_publish_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  kind      text := tg_argv[0];            -- 'article' | 'event' | 'business'
  r         jsonb := to_jsonb(new);
  live      boolean;
  pending   push_campaigns;
  v_title   text;
  v_body    text;
  v_title_en text;
  v_image   text;
  v_link    text;
  v_topic   text;
  v_id      uuid;
begin
  live := case kind
    when 'business' then r ->> 'status' = 'active' and r ->> 'closed_at' is null
    when 'event' then r ->> 'status' = 'published'
      -- An event that is already over is not news.
      and (r ->> 'start_date')::date >= (now() at time zone 'Asia/Jerusalem')::date
    else r ->> 'status' = 'published'
  end;

  if new.push_campaign_id is not null then
    select * into pending from push_campaigns
     where id = new.push_campaign_id and status = 'scheduled';
  end if;

  -- Wording around the item, in each language; the item's own name stays as
  -- it was written, which is Hebrew.
  case kind
    when 'article' then
      v_title := 'כתבה חדשה';  v_title_en := 'New article';
      v_body  := r ->> 'title';
      v_image := coalesce(r ->> 'featured_image', r ->> 'mobile_image');
      v_link  := '/article/' || new.id;
      v_topic := 'news';
    when 'event' then
      v_title := 'אירוע חדש';  v_title_en := 'New event';
      v_body  := (r ->> 'title') || ' · ' || to_char((r ->> 'start_date')::date, 'DD.MM');
      v_image := r ->> 'image_url';
      v_link  := '/event/' || new.id;
      v_topic := 'events';
    else
      v_title := 'עסק חדש בעיר';  v_title_en := 'New in town';
      v_body  := r ->> 'name';
      v_image := r ->> 'cover_url';
      v_link  := '/business/' || new.id;
      v_topic := 'businesses';
  end case;

  if pending.id is not null then
    if not live or not new.notify_on_publish then
      update push_campaigns set status = 'cancelled' where id = pending.id;
      new.push_campaign_id := null;
    else
      update push_campaigns
         set title = v_title, body = v_body, title_en = v_title_en,
             body_en = v_body, image_url = v_image
       where id = pending.id;
    end if;
    return new;
  end if;

  -- A campaign that was sent, or that the panel cancelled by hand, stays
  -- the row's: neither is queued again.
  if new.push_campaign_id is not null or not live or not new.notify_on_publish then
    return new;
  end if;

  insert into push_campaigns (
    title, body, title_en, body_en, image_url, deep_link,
    status, scheduled_at, audience_type, audience_filter,
    source_type, source_id
  ) values (
    v_title, v_body, v_title_en, v_body, v_image, v_link,
    'scheduled', now() + interval '5 minutes', 'topic',
    jsonb_build_object('topic', v_topic),
    kind, new.id
  )
  returning id into v_id;

  new.push_campaign_id := v_id;
  return new;
end;
$$;

drop trigger if exists articles_queue_push on public.articles;
create trigger articles_queue_push
  before insert or update on public.articles
  for each row execute function public.queue_publish_push('article');

drop trigger if exists events_queue_push on public.events;
create trigger events_queue_push
  before insert or update on public.events
  for each row execute function public.queue_publish_push('event');

drop trigger if exists businesses_queue_push on public.businesses;
create trigger businesses_queue_push
  before insert or update on public.businesses
  for each row execute function public.queue_publish_push('business');

-- ─── 6b. A reply in a review conversation ───
--
-- When a reply is approved (00039: replies wait for the panel, as reviews
-- do), the people in that conversation hear of it: the review's author —
-- "a new reply to your review" — and everyone else who has an approved reply
-- there — "a new reply in a conversation you're in". Never the person who
-- wrote it. Each goes only to devices that person is signed in on, so it is
-- in no one else's bell. Sent at once: approving it was the deliberate step.

create or replace function public.queue_reply_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_review   reviews;
  v_text     text;
  v_link     text;
  v_others   jsonb;
begin
  if new.entity_type <> 'review' or new.status <> 'approved' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.status = 'approved' then
    return new;
  end if;

  select * into v_review from reviews where id = new.entity_id;
  if v_review.id is null then
    return new;
  end if;

  v_text := coalesce(nullif(trim(new.author_name), ''), 'תושב/ת') || ': ' ||
    case when length(new.body) > 120 then left(new.body, 117) || '…' else new.body end;
  v_link := '/business/' || v_review.business_id;

  if v_review.author_id <> new.author_id then
    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'תגובה חדשה לביקורת שלך', v_text, 'New reply to your review', v_text, v_link,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', jsonb_build_array(v_review.author_id)),
      'reply', new.id
    );
  end if;

  select jsonb_agg(distinct c.author_id) into v_others
    from comments c
   where c.entity_type = 'review'
     and c.entity_id = v_review.id
     and c.status = 'approved'
     and c.id <> new.id
     and c.author_id <> new.author_id
     and c.author_id <> v_review.author_id;

  if v_others is not null then
    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'תגובה חדשה בשיחה', v_text, 'New reply in a conversation you''re in', v_text, v_link,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', v_others),
      'reply', new.id
    );
  end if;

  return new;
end;
$$;

drop trigger if exists comments_queue_reply_push on public.comments;
create trigger comments_queue_reply_push
  after insert or update of status on public.comments
  for each row execute function public.queue_reply_push();

-- ─── 7. Once a minute, while something is due ───
--
-- The job asks the database first and calls the function only when a
-- campaign is due, so a quiet minute costs nothing.

create extension if not exists pg_net;
create extension if not exists pg_cron;

select cron.unschedule('push-dispatch')
 where exists (select 1 from cron.job where jobname = 'push-dispatch');

select cron.schedule(
  'push-dispatch',
  '* * * * *',
  $job$
    select net.http_post(
      url     := 'https://zbtgietqoxkglfxfocrb.supabase.co/functions/v1/push-dispatch',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-dispatch-secret', (
          select decrypted_secret from vault.decrypted_secrets
           where name = 'push_dispatch_secret'
        )
      ),
      body    := '{}'::jsonb,
      timeout_milliseconds := 5000
    )
    where exists (
      select 1 from public.push_campaigns
       where status = 'scheduled' and scheduled_at <= now()
    );
  $job$
);
