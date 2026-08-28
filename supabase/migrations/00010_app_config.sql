-- ============================================================
-- Modiin4u Control Center — Migration 00010
-- Home Builder, Feature Flags, App Config, Search
-- ============================================================

-- ─── Home Builder Blocks ───
create table home_blocks (
  id              uuid primary key default gen_random_uuid(),
  block_type      block_type not null,
  title           text,
  config          jsonb not null default '{}',  -- items_count, source, audience, etc.
  sort_order      int not null default 0,
  is_active       boolean not null default true,

  -- Targeting
  neighborhoods   uuid[],           -- null = all
  audience        text,             -- 'all', 'new', 'returning'
  start_at        timestamptz,
  end_at          timestamptz,

  -- Versioning
  version         int not null default 1,
  published       boolean not null default false,
  published_at    timestamptz,
  published_by    uuid references admin_users(id),

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger home_blocks_updated_at before update on home_blocks
  for each row execute function update_updated_at();

-- ─── Feature Flags ───
create table feature_flags (
  id           uuid primary key default gen_random_uuid(),
  key          text not null unique,      -- 'AI_SEARCH', 'REAL_ESTATE', 'STEPS'
  label        text not null,
  description  text,
  is_enabled   boolean not null default false,
  rollout_pct  int not null default 100,  -- 0-100
  platforms    text[] default '{}',       -- ['ios','android','web'] or empty = all
  config       jsonb default '{}',
  updated_by   uuid references admin_users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger feature_flags_updated_at before update on feature_flags
  for each row execute function update_updated_at();

-- ─── Remote Config (text/content overrides without app update) ───
create table remote_config (
  id           uuid primary key default gen_random_uuid(),
  key          text not null unique,      -- 'HOME_HEADLINE', 'EMPTY_STATE_SEARCH', 'ONBOARDING_CTA'
  value        text not null,
  description  text,
  updated_by   uuid references admin_users(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create trigger remote_config_updated_at before update on remote_config
  for each row execute function update_updated_at();

-- ─── App Settings ───
create table app_settings (
  id              uuid primary key default gen_random_uuid(),
  key             text not null unique,
  value           jsonb not null,
  updated_by      uuid references admin_users(id),
  updated_at      timestamptz not null default now()
);

-- ─── SEO Redirects ───
create table redirects (
  id           uuid primary key default gen_random_uuid(),
  old_path     text not null unique,
  new_path     text not null,
  status_code  int not null default 301,  -- 301 or 302
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

-- ─── Search Synonyms ───
create table search_synonyms (
  id           uuid primary key default gen_random_uuid(),
  term         text not null,
  synonyms     text[] not null,   -- 'סושי' => ['יפני','sushi']
  created_at   timestamptz not null default now()
);

-- ─── Deep Links ───
create table deep_links (
  id           uuid primary key default gen_random_uuid(),
  entity_type  text not null,
  entity_id    uuid not null,
  path         text not null unique,     -- '/business/pizza-frago'
  app_uri      text not null,            -- 'modiin4u://business/b1'
  created_at   timestamptz not null default now()
);
