-- ============================================================
-- Modiin4u Control Center — Migration 00007
-- Reviews, Comments, Reports, Offers
-- ============================================================

-- ─── Reviews (for businesses) ───
create table reviews (
  id            uuid primary key default gen_random_uuid(),
  business_id   uuid not null references businesses(id) on delete cascade,
  author_id     uuid not null references profiles(id) on delete cascade,
  rating        smallint not null check (rating between 1 and 5),
  title         text,
  body          text,
  is_verified   boolean not null default false,  -- verified resident
  status        moderation_status not null default 'pending',
  report_count  int not null default 0,

  -- Admin
  admin_response text,
  responded_by   uuid references profiles(id),
  responded_at   timestamptz,

  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create trigger reviews_updated_at before update on reviews
  for each row execute function update_updated_at();

create index idx_reviews_business on reviews(business_id);
create index idx_reviews_status on reviews(status);

-- ─── Comments (polymorphic: on articles, events, businesses) ───
create table comments (
  id            uuid primary key default gen_random_uuid(),
  entity_type   text not null,     -- 'article', 'event', 'business'
  entity_id     uuid not null,
  author_id     uuid not null references profiles(id) on delete cascade,
  parent_id     uuid references comments(id) on delete cascade,  -- threaded
  body          text not null,
  status        moderation_status not null default 'pending',
  report_count  int not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create trigger comments_updated_at before update on comments
  for each row execute function update_updated_at();

create index idx_comments_entity on comments(entity_type, entity_id);

-- ─── Reports (moderation queue) ───
create table reports (
  id             uuid primary key default gen_random_uuid(),
  reporter_id    uuid not null references profiles(id) on delete cascade,
  entity_type    text not null,     -- 'review', 'comment', 'business', 'user'
  entity_id      uuid not null,
  reason         report_reason not null,
  details        text,
  status         text not null default 'open',  -- 'open', 'reviewed', 'resolved', 'dismissed'
  resolved_by    uuid references profiles(id),
  resolved_at    timestamptz,
  resolution     text,
  created_at     timestamptz not null default now()
);

create index idx_reports_status on reports(status);

-- ─── Offers / Coupons ───
create table offers (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references businesses(id) on delete cascade,
  name            text not null,
  description     text,
  terms           text,
  image_url       text,
  code            text,
  status          offer_status not null default 'draft',

  -- Availability
  start_at        timestamptz,
  end_at          timestamptz,
  max_claims      int,
  max_per_user    int not null default 1,
  points_required int not null default 0,
  is_featured     boolean not null default false,

  -- Targeting
  neighborhoods   uuid[],           -- null = all
  audience        text,             -- 'all', 'verified', 'new_users'

  -- Stats
  view_count      int not null default 0,
  claim_count     int not null default 0,
  redeem_count    int not null default 0,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger offers_updated_at before update on offers
  for each row execute function update_updated_at();

-- ─── Offer Claims ───
create table offer_claims (
  id          uuid primary key default gen_random_uuid(),
  offer_id    uuid not null references offers(id) on delete cascade,
  profile_id  uuid not null references profiles(id) on delete cascade,
  redeemed    boolean not null default false,
  redeemed_at timestamptz,
  created_at  timestamptz not null default now(),
  unique (offer_id, profile_id)  -- one claim per user (unless max_per_user > 1, handled in app logic)
);

-- ─── User Favorites (polymorphic) ───
create table favorites (
  id          uuid primary key default gen_random_uuid(),
  profile_id  uuid not null references profiles(id) on delete cascade,
  entity_type text not null,     -- 'business', 'article', 'event'
  entity_id   uuid not null,
  created_at  timestamptz not null default now(),
  unique (profile_id, entity_type, entity_id)
);
