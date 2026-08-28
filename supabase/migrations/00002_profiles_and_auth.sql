-- ============================================================
-- Modiin4u Control Center — Migration 00002
-- Profiles, Admin Users, Roles & Permissions
-- ============================================================

-- ─── Neighborhoods (referenced by profiles & businesses) ───
create table neighborhoods (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  slug        text not null unique,
  description text,
  image_url   text,
  color       text,        -- hex for map/UI
  icon        text,
  polygon     jsonb,       -- GeoJSON for area boundaries
  is_active   boolean not null default true,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ─── User Profiles (extends auth.users) ───
create table profiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  full_name         text not null,
  phone             text,
  email             text,
  avatar_url        text,
  neighborhood_id   uuid references neighborhoods(id),
  is_verified       boolean not null default false,
  is_banned         boolean not null default false,
  ban_reason        text,
  points            int not null default 0,
  level             int not null default 1,
  push_enabled      boolean not null default false,
  location_enabled  boolean not null default false,
  health_enabled    boolean not null default false,
  device_os         text,       -- ios / android / web
  app_version       text,
  last_login_at     timestamptz,
  last_activity_at  timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

-- ─── Admin Roles ───
create table admin_roles (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,        -- 'super_admin', 'editor', 'sales', etc.
  label       text not null,               -- 'מנהל ראשי', 'עורך תוכן'
  description text,
  is_system   boolean not null default false,  -- built-in roles can't be deleted
  created_at  timestamptz not null default now()
);

-- ─── Role Permissions (granular per-action) ───
create table admin_role_permissions (
  id          uuid primary key default gen_random_uuid(),
  role_id     uuid not null references admin_roles(id) on delete cascade,
  module      text not null,   -- 'businesses', 'articles', 'revenue', etc.
  action      text not null,   -- 'view', 'create', 'edit', 'delete', 'export'
  allowed     boolean not null default true,
  unique (role_id, module, action)
);

-- ─── Admin Users ───
create table admin_users (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references profiles(id) on delete cascade,
  role_id     uuid not null references admin_roles(id),
  is_active   boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (profile_id)
);

-- ─── Triggers: auto-update updated_at ───
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at before update on profiles
  for each row execute function update_updated_at();

create trigger neighborhoods_updated_at before update on neighborhoods
  for each row execute function update_updated_at();

create trigger admin_users_updated_at before update on admin_users
  for each row execute function update_updated_at();
