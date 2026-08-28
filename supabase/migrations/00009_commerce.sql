-- ============================================================
-- Modiin4u Control Center — Migration 00009
-- Commercial Agreements, Subscriptions, Revenue, Payments
-- ============================================================

-- ─── Commercial Agreements (per-product, per-business) ───
create table commercial_agreements (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references businesses(id) on delete cascade,
  type            agreement_type not null,
  name            text not null,         -- 'מנוי Premium', 'באנר ראשי'
  description     text,

  -- Pricing
  price           numeric(10,2) not null,
  vat_included    boolean not null default true,
  discount_pct    numeric(5,2) default 0,
  billing_cycle   billing_cycle not null default 'monthly',

  -- Period
  start_date      date not null,
  end_date        date,
  auto_renew      boolean not null default true,

  -- Status
  status          text not null default 'active',  -- 'active', 'paused', 'cancelled', 'expired'
  cancelled_at    timestamptz,
  cancel_reason   text,

  -- Sales
  salesperson_id  uuid references admin_users(id),
  notes           text,

  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger agreements_updated_at before update on commercial_agreements
  for each row execute function update_updated_at();

create index idx_agreements_business on commercial_agreements(business_id);

-- ─── Subscriptions (recurring business plans) ───
create table subscriptions (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references businesses(id) on delete cascade,
  agreement_id    uuid references commercial_agreements(id) on delete set null,
  plan_name       text not null,
  price           numeric(10,2) not null,
  billing_cycle   billing_cycle not null default 'monthly',
  status          subscription_status not null default 'active',

  -- Dates
  start_date      date not null,
  current_period_start date,
  current_period_end   date,
  next_renewal    date,

  -- Trial
  trial_start     date,
  trial_end       date,

  -- Cancellation
  cancelled_at    timestamptz,
  cancel_reason   text,

  salesperson_id  uuid references admin_users(id),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create trigger subscriptions_updated_at before update on subscriptions
  for each row execute function update_updated_at();

-- ─── Revenue Transactions (every shekel in) ───
create table revenue_transactions (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references businesses(id) on delete cascade,
  agreement_id    uuid references commercial_agreements(id) on delete set null,
  subscription_id uuid references subscriptions(id) on delete set null,
  campaign_id     uuid references campaigns(id) on delete set null,
  push_campaign_id uuid references push_campaigns(id) on delete set null,

  -- Details
  description     text not null,
  amount          numeric(10,2) not null,
  vat_amount      numeric(10,2) default 0,
  net_amount      numeric(10,2),         -- computed: amount - vat
  currency        text not null default 'ILS',

  -- Categorization
  revenue_type    text not null,         -- 'subscription', 'banner', 'push', 'featured', 'sponsored', 'custom'
  period_start    date,
  period_end      date,

  -- Payment
  payment_status  payment_status not null default 'pending',
  paid_at         timestamptz,
  due_date        date,
  invoice_ref     text,

  salesperson_id  uuid references admin_users(id),
  created_at      timestamptz not null default now()
);

create index idx_revenue_business on revenue_transactions(business_id);
create index idx_revenue_status on revenue_transactions(payment_status);
create index idx_revenue_date on revenue_transactions(created_at desc);

-- ─── Payments (actual money received) ───
create table payments (
  id              uuid primary key default gen_random_uuid(),
  business_id     uuid not null references businesses(id) on delete cascade,
  transaction_id  uuid references revenue_transactions(id) on delete set null,

  amount          numeric(10,2) not null,
  method          text,               -- 'credit_card', 'bank_transfer', 'cash', 'check'
  reference       text,               -- payment gateway reference
  notes           text,
  paid_at         timestamptz not null default now(),
  created_at      timestamptz not null default now()
);
