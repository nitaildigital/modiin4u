-- ============================================================
-- Modiin4u Control Center — Migration 00004
-- Businesses (core entity + hours + attributes)
-- ============================================================

create table businesses (
  id                uuid primary key default gen_random_uuid(),
  owner_id          uuid references profiles(id) on delete set null,
  neighborhood_id   uuid references neighborhoods(id),

  -- Basic info
  name              text not null,
  slug              text not null unique,
  legal_name        text,
  tax_id            text,          -- ח.פ./עוסק — internal only
  short_description text,
  full_description  text,

  -- Contact
  phone             text,
  whatsapp          text,
  email             text,
  website           text,
  facebook          text,
  instagram         text,
  tiktok            text,

  -- Location
  address           text not null,
  latitude          double precision,
  longitude         double precision,
  google_maps_url   text,
  waze_url          text,

  -- Media (primary refs — full gallery via entity_media)
  logo_url          text,
  cover_url         text,

  -- Ratings
  rating            numeric(2,1) not null default 0,
  review_count      int not null default 0,

  -- Attributes (common flags)
  kosher_level      kosher_level not null default 'none',
  price_level       price_level,
  has_delivery      boolean not null default false,
  has_takeaway      boolean not null default false,
  has_outdoor       boolean not null default false,
  is_accessible     boolean not null default false,
  has_parking       boolean not null default false,
  pet_friendly      boolean not null default false,
  kid_friendly      boolean not null default false,
  has_wifi          boolean not null default false,
  open_on_shabbat   boolean not null default false,

  -- Status & promotion
  status            business_status not null default 'draft',
  is_verified       boolean not null default false,
  is_featured       boolean not null default false,
  is_sponsored      boolean not null default false,
  is_recommended    boolean not null default false,
  featured_start    timestamptz,
  featured_end      timestamptz,

  -- SEO
  meta_title        text,
  meta_description  text,
  meta_keywords     text,
  canonical_url     text,
  og_title          text,
  og_description    text,
  og_image_url      text,
  noindex           boolean not null default false,

  -- CTA
  cta_order_url     text,
  cta_reserve_url   text,
  cta_menu_url      text,

  -- Timestamps
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  approved_at       timestamptz,
  closed_at         timestamptz
);

create trigger businesses_updated_at before update on businesses
  for each row execute function update_updated_at();

create index idx_businesses_status on businesses(status);
create index idx_businesses_neighborhood on businesses(neighborhood_id);
create index idx_businesses_owner on businesses(owner_id);

-- ─── Business Hours ───
create table business_hours (
  id            uuid primary key default gen_random_uuid(),
  business_id   uuid not null references businesses(id) on delete cascade,
  day_of_week   smallint not null check (day_of_week between 0 and 6),  -- 0=Sunday
  open_time     time,
  close_time    time,
  open_time_2   time,    -- split hours
  close_time_2  time,
  is_closed     boolean not null default false,
  is_24h        boolean not null default false,
  note          text,    -- 'ערב חג', 'מיוחד'
  unique (business_id, day_of_week)
);

-- ─── Dynamic Business Attributes (admin-managed, per category) ───
create table business_attribute_defs (
  id           uuid primary key default gen_random_uuid(),
  category_id  uuid references categories(id) on delete set null,
  name         text not null,       -- 'cuisine_type', 'kashrut_level'
  label        text not null,       -- 'סוג מטבח'
  field_type   text not null default 'text',  -- 'text', 'boolean', 'select', 'multi_select'
  options      jsonb,               -- for select/multi_select: ['אסייתי','איטלקי','ישראלי']
  sort_order   int not null default 0,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

create table business_attribute_values (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references businesses(id) on delete cascade,
  attribute_def_id uuid not null references business_attribute_defs(id) on delete cascade,
  value           text,
  unique (business_id, attribute_def_id)
);
