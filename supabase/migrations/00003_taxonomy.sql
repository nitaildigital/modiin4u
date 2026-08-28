-- ============================================================
-- Modiin4u Control Center — Migration 00003
-- Categories, Tags — Unified Taxonomy
-- ============================================================

-- ─── Categories (unified, hierarchical) ───
create table categories (
  id          uuid primary key default gen_random_uuid(),
  parent_id   uuid references categories(id) on delete set null,
  scope       text not null,   -- 'business', 'article', 'event', 'real_estate'
  name        text not null,
  slug        text not null,
  icon        text,
  image_url   text,
  description text,
  sort_order  int not null default 0,
  is_active   boolean not null default true,

  -- SEO
  meta_title       text,
  meta_description text,

  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (scope, slug)
);

create trigger categories_updated_at before update on categories
  for each row execute function update_updated_at();

-- ─── Tags (flat, cross-entity) ───
create table tags (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  slug        text not null unique,
  created_at  timestamptz not null default now()
);

-- ─── Media Library (shared across all entities) ───
create table media (
  id           uuid primary key default gen_random_uuid(),
  file_name    text not null,
  file_path    text not null,        -- storage path
  url          text not null,
  mime_type    text not null,
  size_bytes   bigint,
  width        int,
  height       int,
  alt_text     text,
  folder       text,                 -- virtual folder for organization
  uploaded_by  uuid references profiles(id),
  created_at   timestamptz not null default now()
);

-- ─── Entity-Media junction (polymorphic: any entity can have media) ───
create table entity_media (
  id           uuid primary key default gen_random_uuid(),
  media_id     uuid not null references media(id) on delete cascade,
  entity_type  text not null,        -- 'business', 'article', 'event', etc.
  entity_id    uuid not null,
  role         text not null default 'gallery',  -- 'cover', 'logo', 'gallery', 'og', 'menu', 'document'
  sort_order   int not null default 0,
  created_at   timestamptz not null default now()
);

create index idx_entity_media_entity on entity_media(entity_type, entity_id);

-- ─── Entity-Tag junction ───
create table entity_tags (
  entity_type  text not null,
  entity_id    uuid not null,
  tag_id       uuid not null references tags(id) on delete cascade,
  primary key (entity_type, entity_id, tag_id)
);

-- ─── Entity-Category junction ───
create table entity_categories (
  entity_type  text not null,
  entity_id    uuid not null,
  category_id  uuid not null references categories(id) on delete cascade,
  is_primary   boolean not null default false,
  primary key (entity_type, entity_id, category_id)
);
