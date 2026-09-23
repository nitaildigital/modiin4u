-- ============================================================
-- Modiin4u — Migration 00018
-- Property listings and agents
--
-- The app carries nine real-estate screens and one of the five bottom tabs,
-- and the schema had nothing behind any of it — not an empty table, none at
-- all. So the section could not be put on live data, and the client could not
-- add a property from the admin panel.
--
-- Shaped to what the screens already read: type, rooms, floor, area, price,
-- whether it is for sale or rent, the neighbourhood, and whether an agent is
-- involved. The site's export has four apartments and four agents to load
-- into it.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Kinds of property, and what is being offered ───

do $$ begin
  create type listing_kind as enum ('sale', 'rent');
exception when duplicate_object then null; end $$;

do $$ begin
  create type property_type as enum (
    'apartment', 'penthouse', 'garden', 'duplex', 'villa', 'studio', 'other'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type listing_status as enum (
    'draft', 'pending', 'active', 'sold', 'rented', 'expired', 'removed'
  );
exception when duplicate_object then null; end $$;

-- ─── 2. Agents ───
--
-- An agent is not a business: a listing may come from one, from the resident
-- who lives there, or from neither.

create table if not exists public.real_estate_agents (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  agency        text,
  phone         text,
  whatsapp      text,
  email         text,
  photo_url     text,
  licence_no    text,
  about         text,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ─── 3. Listings ───

create table if not exists public.listings (
  id              uuid primary key default gen_random_uuid(),

  title           text not null,
  slug            text unique,
  description     text,

  kind            listing_kind  not null default 'sale',
  property_type   property_type not null default 'apartment',
  status          listing_status not null default 'draft',

  -- What the cards and the filters read. `rooms` is numeric because half
  -- rooms are normal here — 3.5 is a common listing.
  -- Named as the admin form already names them, so nothing has to be
  -- translated on the way in or out.
  rooms           numeric(3,1),
  bathrooms       int,
  floor           int,
  total_floors    int,
  sqm             int,

  -- Price is whole shekels. `price_per_month` stays null on a sale, and the
  -- card shows one or the other rather than both.
  price           bigint,
  price_per_month bigint,

  address         text,
  neighborhood_id uuid references public.neighborhoods(id) on delete set null,
  latitude        double precision,
  longitude       double precision,

  has_parking     boolean not null default false,
  has_elevator    boolean not null default false,
  has_storage     boolean not null default false,
  has_balcony     boolean not null default false,
  -- ממ"ד. The local word, because that is what a listing here says.
  has_mamad       boolean not null default false,
  is_furnished    boolean not null default false,
  is_accessible   boolean not null default false,
  is_renovated    boolean not null default false,

  cover_url       text,
  gallery         text[] not null default '{}',

  -- Whoever is offering it. All of these may be null: the client can enter a
  -- listing that came in by telephone.
  agent_id        uuid references public.real_estate_agents(id) on delete set null,
  owner_id        uuid references public.profiles(id) on delete set null,
  is_broker       boolean not null default false,
  contact_name    text,
  contact_phone   text,

  available_from  date,
  is_featured     boolean not null default false,
  view_count      int not null default 0,

  published_at    timestamptz,
  expires_at      timestamptz,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- The list is filtered by kind and type and sorted by price, and the map
-- needs the ones that have coordinates.
create index if not exists idx_listings_browse
  on public.listings (kind, property_type, price)
  where status = 'active';

create index if not exists idx_listings_rooms
  on public.listings (rooms, sqm) where status = 'active';

create index if not exists idx_listings_neighborhood
  on public.listings (neighborhood_id) where status = 'active';

create index if not exists idx_listings_located
  on public.listings (latitude, longitude)
  where status = 'active' and latitude is not null;

-- ─── 4. Keeping updated_at honest ───

drop trigger if exists listings_updated_at on public.listings;
create trigger listings_updated_at before update on public.listings
  for each row execute function update_updated_at();

drop trigger if exists real_estate_agents_updated_at on public.real_estate_agents;
create trigger real_estate_agents_updated_at before update on public.real_estate_agents
  for each row execute function update_updated_at();

-- ─── 5. Who may read and write ───
--
-- Anyone reads a published listing. The person who posted it may edit their
-- own — the app has an "add apartment" screen for residents — and an
-- administrator may touch anything.

alter table public.listings enable row level security;
alter table public.real_estate_agents enable row level security;

drop policy if exists "listings_public_read" on public.listings;
create policy "listings_public_read"
  on public.listings for select
  using (status = 'active' or owner_id = auth.uid() or is_admin());

drop policy if exists "listings_owner_write" on public.listings;
create policy "listings_owner_write"
  on public.listings for insert
  with check (
    -- A resident posts their own; an administrator enters one that came in by
    -- telephone and has no owner at all.
    (auth.uid() is not null and owner_id = auth.uid()) or is_admin()
  );

drop policy if exists "listings_owner_update" on public.listings;
create policy "listings_owner_update"
  on public.listings for update
  using (owner_id = auth.uid() or is_admin());

drop policy if exists "listings_owner_delete" on public.listings;
create policy "listings_owner_delete"
  on public.listings for delete
  using (owner_id = auth.uid() or is_admin());

drop policy if exists "agents_public_read" on public.real_estate_agents;
create policy "agents_public_read"
  on public.real_estate_agents for select
  using (is_active = true or is_admin());

drop policy if exists "agents_admin_write" on public.real_estate_agents;
create policy "agents_admin_write"
  on public.real_estate_agents for all
  using (is_admin())
  with check (is_admin());
