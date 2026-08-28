-- ============================================================
-- Modiin4u Control Center — Migration 00005
-- Articles / CMS
-- ============================================================

create table articles (
  id                uuid primary key default gen_random_uuid(),
  author_id         uuid references profiles(id) on delete set null,

  -- Content
  title             text not null,
  subtitle          text,
  slug              text not null unique,
  body              text not null,    -- rich text / HTML
  excerpt           text,

  -- Media
  featured_image    text,
  mobile_image      text,
  og_image          text,

  -- Classification
  source            text,
  credit            text,

  -- Flags
  status            article_status not null default 'draft',
  is_breaking       boolean not null default false,
  is_featured       boolean not null default false,
  is_pinned         boolean not null default false,
  is_sponsored      boolean not null default false,
  is_members_only   boolean not null default false,
  push_worthy       boolean not null default false,

  -- SEO
  seo_title         text,
  meta_description  text,
  meta_keywords     text,
  canonical_url     text,
  og_title          text,
  og_description    text,
  focus_keyword     text,
  secondary_keywords text,
  schema_type       text default 'Article',
  noindex           boolean not null default false,
  nofollow          boolean not null default false,

  -- Stats
  view_count        int not null default 0,
  unique_views      int not null default 0,
  share_count       int not null default 0,
  save_count        int not null default 0,

  -- Scheduling
  published_at      timestamptz,
  scheduled_at      timestamptz,    -- future publish
  updated_at        timestamptz not null default now(),
  created_at        timestamptz not null default now()
);

create trigger articles_updated_at before update on articles
  for each row execute function update_updated_at();

create index idx_articles_status on articles(status);
create index idx_articles_published on articles(published_at desc);

-- ─── Article ↔ Business relation ───
create table article_businesses (
  article_id   uuid not null references articles(id) on delete cascade,
  business_id  uuid not null references businesses(id) on delete cascade,
  primary key (article_id, business_id)
);

-- ─── Article Version History ───
create table article_versions (
  id          uuid primary key default gen_random_uuid(),
  article_id  uuid not null references articles(id) on delete cascade,
  version     int not null,
  title       text not null,
  body        text not null,
  changed_by  uuid references profiles(id),
  created_at  timestamptz not null default now(),
  unique (article_id, version)
);
