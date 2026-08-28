-- ============================================================
-- Modiin4u Control Center — Migration 00006
-- Events
-- ============================================================

create table events (
  id                uuid primary key default gen_random_uuid(),
  organizer_id      uuid references profiles(id) on delete set null,
  business_id       uuid references businesses(id) on delete set null,

  -- Content
  title             text not null,
  slug              text not null unique,
  short_description text,
  full_description  text,

  -- Media
  image_url         text,
  og_image          text,

  -- Time
  start_date        date not null,
  start_time        time,
  end_date          date,
  end_time          time,
  is_all_day        boolean not null default false,
  is_recurring      boolean not null default false,
  recurrence_rule   text,           -- iCal RRULE

  -- Location
  venue_name        text,
  address           text,
  latitude          double precision,
  longitude         double precision,
  waze_url          text,
  is_online         boolean not null default false,
  online_url        text,

  -- Ticketing
  is_free           boolean not null default true,
  price             numeric(10,2),
  ticket_url        text,
  is_sold_out       boolean not null default false,
  max_attendees     int,

  -- Status & promotion
  status            event_status not null default 'draft',
  is_featured       boolean not null default false,
  is_sponsored      boolean not null default false,
  target_audience   text,           -- 'families', 'kids', 'adults', etc.

  -- SEO
  seo_title         text,
  meta_description  text,
  meta_keywords     text,
  canonical_url     text,
  og_title          text,
  og_description    text,
  noindex           boolean not null default false,

  -- Stats
  view_count        int not null default 0,
  rsvp_count        int not null default 0,
  calendar_adds     int not null default 0,
  share_count       int not null default 0,

  -- Timestamps
  published_at      timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create trigger events_updated_at before update on events
  for each row execute function update_updated_at();

create index idx_events_status on events(status);
create index idx_events_start on events(start_date);
create index idx_events_business on events(business_id);

-- ─── Event Attendees / RSVP ───
create table event_attendees (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid not null references events(id) on delete cascade,
  profile_id  uuid not null references profiles(id) on delete cascade,
  status      text not null default 'going',  -- 'going', 'interested', 'cancelled'
  created_at  timestamptz not null default now(),
  unique (event_id, profile_id)
);
