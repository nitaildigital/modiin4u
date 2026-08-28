-- ============================================================
-- Modiin4u Control Center — Migration 00013
-- Row Level Security Policies
-- ============================================================

-- Helper: check if current user is admin
create or replace function is_admin()
returns boolean as $$
  select exists (
    select 1 from admin_users
    where profile_id = auth.uid()
    and is_active = true
  );
$$ language sql security definer stable;

-- Helper: check if current user has specific permission
create or replace function has_permission(p_module text, p_action text)
returns boolean as $$
  select exists (
    select 1 from admin_users au
    join admin_role_permissions arp on arp.role_id = au.role_id
    where au.profile_id = auth.uid()
    and au.is_active = true
    and arp.module = p_module
    and arp.action = p_action
    and arp.allowed = true
  );
$$ language sql security definer stable;

-- Helper: check if current user owns a business
create or replace function owns_business(p_business_id uuid)
returns boolean as $$
  select exists (
    select 1 from businesses
    where id = p_business_id
    and owner_id = auth.uid()
  );
$$ language sql security definer stable;

-- ═══════════════════════════════════════════════
-- PROFILES
-- ═══════════════════════════════════════════════
alter table profiles enable row level security;

create policy "profiles_select_own"
  on profiles for select
  using (id = auth.uid());

create policy "profiles_select_public"
  on profiles for select
  using (true);  -- public profiles (name, avatar, neighborhood)

create policy "profiles_update_own"
  on profiles for update
  using (id = auth.uid());

create policy "profiles_admin_all"
  on profiles for all
  using (is_admin());

-- ═══════════════════════════════════════════════
-- BUSINESSES
-- ═══════════════════════════════════════════════
alter table businesses enable row level security;

create policy "businesses_select_public"
  on businesses for select
  using (status = 'active' or owner_id = auth.uid() or is_admin());

create policy "businesses_insert_admin"
  on businesses for insert
  with check (is_admin());

create policy "businesses_update_owner"
  on businesses for update
  using (owner_id = auth.uid() or is_admin());

create policy "businesses_delete_admin"
  on businesses for delete
  using (is_admin());

-- ═══════════════════════════════════════════════
-- ARTICLES
-- ═══════════════════════════════════════════════
alter table articles enable row level security;

create policy "articles_select_published"
  on articles for select
  using (status = 'published' or is_admin());

create policy "articles_insert_admin"
  on articles for insert
  with check (has_permission('articles', 'create'));

create policy "articles_update_admin"
  on articles for update
  using (has_permission('articles', 'edit'));

create policy "articles_delete_admin"
  on articles for delete
  using (has_permission('articles', 'delete'));

-- ═══════════════════════════════════════════════
-- EVENTS
-- ═══════════════════════════════════════════════
alter table events enable row level security;

create policy "events_select_published"
  on events for select
  using (status in ('published', 'past') or is_admin());

create policy "events_modify_admin"
  on events for all
  using (has_permission('events', 'edit'));

-- ═══════════════════════════════════════════════
-- REVIEWS
-- ═══════════════════════════════════════════════
alter table reviews enable row level security;

create policy "reviews_select_approved"
  on reviews for select
  using (status = 'approved' or author_id = auth.uid() or is_admin());

create policy "reviews_insert_auth"
  on reviews for insert
  with check (auth.uid() is not null and author_id = auth.uid());

create policy "reviews_update_own"
  on reviews for update
  using (author_id = auth.uid() or is_admin());

create policy "reviews_delete_admin"
  on reviews for delete
  using (is_admin());

-- ═══════════════════════════════════════════════
-- OFFERS
-- ═══════════════════════════════════════════════
alter table offers enable row level security;

create policy "offers_select_active"
  on offers for select
  using (status = 'active' or is_admin() or owns_business(business_id));

create policy "offers_modify_admin"
  on offers for all
  using (is_admin() or owns_business(business_id));

-- ═══════════════════════════════════════════════
-- REVENUE / COMMERCIAL (admin-only)
-- ═══════════════════════════════════════════════
alter table commercial_agreements enable row level security;
alter table subscriptions enable row level security;
alter table revenue_transactions enable row level security;
alter table payments enable row level security;

create policy "revenue_admin_only"
  on commercial_agreements for all using (is_admin());

create policy "subscriptions_admin_only"
  on subscriptions for all using (is_admin());

create policy "transactions_admin_only"
  on revenue_transactions for all using (is_admin());

create policy "payments_admin_only"
  on payments for all using (is_admin());

-- ═══════════════════════════════════════════════
-- CAMPAIGNS / PUSH / ADVERTISING (admin-only)
-- ═══════════════════════════════════════════════
alter table campaigns enable row level security;
alter table push_campaigns enable row level security;

create policy "campaigns_admin_only"
  on campaigns for all using (is_admin());

create policy "push_admin_only"
  on push_campaigns for all using (is_admin());

-- ═══════════════════════════════════════════════
-- AUDIT LOG (admin read-only, system write)
-- ═══════════════════════════════════════════════
alter table audit_logs enable row level security;

create policy "audit_admin_read"
  on audit_logs for select
  using (is_admin());

-- ═══════════════════════════════════════════════
-- HOME BLOCKS, FEATURE FLAGS, CONFIG (admin-only)
-- ═══════════════════════════════════════════════
alter table home_blocks enable row level security;
alter table feature_flags enable row level security;
alter table remote_config enable row level security;

create policy "home_blocks_select_public"
  on home_blocks for select
  using (is_active and published);

create policy "home_blocks_admin"
  on home_blocks for all
  using (is_admin());

create policy "feature_flags_select_public"
  on feature_flags for select
  using (true);

create policy "feature_flags_admin"
  on feature_flags for all
  using (is_admin());

create policy "remote_config_select_public"
  on remote_config for select
  using (true);

create policy "remote_config_admin"
  on remote_config for all
  using (is_admin());
