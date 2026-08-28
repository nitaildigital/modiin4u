-- ============================================================
-- Modiin4u Control Center — Migration 00008
-- Advertising: Placements, Campaigns, Push
-- ============================================================

-- ─── Ad Placements (the "slots" in the app) ───
create table ad_placements (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,    -- 'HOME_TOP', 'ARTICLE_INLINE', etc.
  label         text not null,           -- 'ראש עמוד הבית'
  description   text,
  max_banners   int not null default 1,
  allowed_sizes jsonb,                   -- [{"w":728,"h":90}, {"w":320,"h":100}]
  is_active     boolean not null default true,
  sort_order    int not null default 0,
  created_at    timestamptz not null default now()
);

-- ─── Campaigns (banner ads) ───
create table campaigns (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid references businesses(id) on delete set null,
  placement_id    uuid not null references ad_placements(id) on delete cascade,

  -- Info
  name            text not null,
  status          campaign_status not null default 'draft',

  -- Creative
  desktop_image   text,
  mobile_image    text,
  video_url       text,
  destination_url text,
  deep_link       text,

  -- Schedule
  start_at        timestamptz,
  end_at          timestamptz,
  priority        int not null default 0,
  frequency_cap   int,              -- max impressions per user

  -- Targeting
  target_neighborhoods uuid[],
  target_categories    uuid[],
  target_audience      text,        -- 'all', 'new', 'returning'

  -- Stats
  impressions     int not null default 0,
  unique_impressions int not null default 0,
  clicks          int not null default 0,
  conversions     int not null default 0,

  -- Commercial
  salesperson_id  uuid references admin_users(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger campaigns_updated_at before update on campaigns
  for each row execute function update_updated_at();

create index idx_campaigns_status on campaigns(status);
create index idx_campaigns_business on campaigns(business_id);

-- ─── Push Campaigns ───
create table push_campaigns (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid references businesses(id) on delete set null,

  -- Content
  title           text not null,
  body            text not null,
  image_url       text,
  icon_url        text,
  deep_link       text,
  destination_url text,

  -- Schedule
  status          push_status not null default 'draft',
  scheduled_at    timestamptz,
  sent_at         timestamptz,
  expires_at      timestamptz,

  -- Audience
  audience_type   text not null default 'all',  -- 'all', 'neighborhood', 'segment', 'custom'
  audience_filter jsonb,                         -- flexible filter criteria

  -- Stats
  sent_count      int not null default 0,
  delivered_count int not null default 0,
  opened_count    int not null default 0,
  click_count     int not null default 0,

  -- If sponsored
  is_sponsored    boolean not null default false,
  salesperson_id  uuid references admin_users(id),

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger push_campaigns_updated_at before update on push_campaigns
  for each row execute function update_updated_at();

-- ─── Push Automation Rules ───
create table push_automations (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  trigger     text not null,     -- 'event_starting_soon', 'offer_expiring', 'inactive_7d', etc.
  title_template text not null,
  body_template  text not null,
  deep_link   text,
  is_active   boolean not null default true,
  config      jsonb,             -- trigger-specific params
  created_at  timestamptz not null default now()
);
