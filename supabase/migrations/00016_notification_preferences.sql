-- ============================================================
-- Modiin4u — Migration 00016
-- Notification preferences and device registration
--
-- The settings screen offers four notification topics and they were held in
-- the widget, so they were forgotten the moment the screen closed. There was
-- also nowhere to record a device, so a push campaign had no one to send to.
--
-- `profiles` already carries `push_enabled`, `location_enabled` and
-- `health_enabled`; this adds the per-topic choices beside them.
--
-- Booleans rather than one jsonb column, so `push_campaigns.audience_filter`
-- can narrow an audience with an ordinary indexed WHERE.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Per-topic preferences ───

alter table public.profiles
  add column if not exists notify_news         boolean not null default true,
  add column if not exists notify_deals        boolean not null default true,
  add column if not exists notify_neighborhood boolean not null default true,
  add column if not exists notify_realestate   boolean not null default false;

comment on column public.profiles.notify_news is
  'Local news and municipal updates.';
comment on column public.profiles.notify_deals is
  'New offers from businesses.';
comment on column public.profiles.notify_neighborhood is
  'Events and updates for the neighbourhood on the profile.';
comment on column public.profiles.notify_realestate is
  'Property matches. Off by default — there is no property table yet.';

-- Narrowing an audience reads these together with the master switch.
create index if not exists idx_profiles_push_audience
  on public.profiles (push_enabled, neighborhood_id)
  where push_enabled = true;

-- ─── 2. Devices to deliver to ───
--
-- One row per installation, not per person: someone with a phone and a tablet
-- gets both. The token is what Firebase or APNs hands back, and it changes on
-- reinstall, so it is the key rather than the device.

create table if not exists public.device_tokens (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references public.profiles(id) on delete cascade,
  token       text not null unique,
  platform    text not null,           -- 'ios' | 'android' | 'web'
  app_version text,
  is_active   boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create index if not exists idx_device_tokens_profile
  on public.device_tokens (profile_id) where is_active = true;

-- ─── 3. Who may touch a device row ───
--
-- Someone manages their own devices; an administrator reads them all, because
-- sending a campaign means reading the tokens to send to.

alter table public.device_tokens enable row level security;

drop policy if exists "device_tokens_own" on public.device_tokens;
create policy "device_tokens_own"
  on public.device_tokens for all
  using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

drop policy if exists "device_tokens_admin_read" on public.device_tokens;
create policy "device_tokens_admin_read"
  on public.device_tokens for select
  using (is_admin());
