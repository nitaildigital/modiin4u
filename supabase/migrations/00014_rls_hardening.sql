-- ============================================================
-- Modiin4u — Migration 00014
-- Row Level Security hardening
--
-- 36 of the 50 public tables accepted writes from the anon key, which ships
-- inside every published build. `admin_users` was among them, so anyone
-- holding that key could have made themselves an administrator and inherited
-- rights over the tables that were already protected.
--
-- This turns row level security on everywhere and states, per table, who may
-- read and who may write. It is written to be safe to run more than once.
-- ============================================================

-- ─── 1. Row level security on every public table ───
--
-- Only the ones we own. An extension brings its own tables into `public` —
-- PostGIS puts `spatial_ref_sys` there — and they belong to the extension,
-- not to us: altering one fails, and it holds reference data with nothing
-- private in it anyway.

do $$
declare t record;
begin
  for t in
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind = 'r'
      and pg_catalog.pg_get_userbyid(c.relowner) = current_user
      and not exists (
        select 1 from pg_depend d
        where d.objid = c.oid and d.deptype = 'e'
      )
  loop
    execute format('alter table public.%I enable row level security', t.relname);
  end loop;
end $$;

-- ─── 2. Helpers ───
-- Re-declared so this migration stands on its own if 00013 never ran.

create or replace function is_admin()
returns boolean as $$
  select exists (
    select 1 from admin_users
    where profile_id = auth.uid() and is_active = true
  );
$$ language sql security definer stable;

-- ─── 3. Public read, admin write ───
-- Content the app shows to everyone, signed in or not.

do $$
declare
  t text;
  public_read text[] := array[
    'categories', 'neighborhoods', 'tags', 'media',
    'entity_categories', 'entity_tags', 'entity_media',
    'business_hours', 'business_attribute_defs', 'business_attribute_values',
    'home_blocks', 'ad_placements', 'app_settings', 'remote_config',
    'feature_flags', 'search_synonyms', 'redirects', 'deep_links',
    'point_rules', 'games', 'challenges'
  ];
begin
  foreach t in array public_read loop
    if to_regclass('public.' || t) is null then continue; end if;

    execute format('drop policy if exists %I on public.%I', t || '_read_all', t);
    execute format(
      'create policy %I on public.%I for select using (true)',
      t || '_read_all', t);

    execute format('drop policy if exists %I on public.%I', t || '_write_admin', t);
    execute format(
      'create policy %I on public.%I for all using (is_admin()) with check (is_admin())',
      t || '_write_admin', t);
  end loop;
end $$;

-- ─── 4. Published content ───
-- Readable when published; only administrators may change it.

drop policy if exists businesses_read_active on public.businesses;
create policy businesses_read_active on public.businesses
  for select using (status = 'active' or owner_id = auth.uid() or is_admin());

drop policy if exists businesses_write_admin on public.businesses;
create policy businesses_write_admin on public.businesses
  for all using (owner_id = auth.uid() or is_admin())
  with check (owner_id = auth.uid() or is_admin());

drop policy if exists articles_read_published on public.articles;
create policy articles_read_published on public.articles
  for select using (status = 'published' or is_admin());

drop policy if exists articles_write_admin on public.articles;
create policy articles_write_admin on public.articles
  for all using (is_admin()) with check (is_admin());

drop policy if exists events_read_published on public.events;
create policy events_read_published on public.events
  for select using (status = 'published' or is_admin());

drop policy if exists events_write_admin on public.events;
create policy events_write_admin on public.events
  for all using (is_admin()) with check (is_admin());

drop policy if exists offers_read_active on public.offers;
create policy offers_read_active on public.offers
  for select using (status = 'active' or is_admin());

drop policy if exists offers_write_admin on public.offers;
create policy offers_write_admin on public.offers
  for all using (is_admin()) with check (is_admin());

-- ─── 5. What a signed-in resident owns ───
-- Read what is public, write only your own rows.

do $$
declare
  t text;
  owned text[][] := array[
    ['favorites', 'profile_id'],
    ['event_attendees', 'profile_id'],
    ['daily_steps', 'profile_id'],
    ['offer_claims', 'profile_id'],
    ['challenge_participants', 'profile_id'],
    ['game_sessions', 'profile_id'],
    ['reports', 'reporter_id']
  ];
  i int;
  col text;
begin
  for i in 1 .. array_length(owned, 1) loop
    t := owned[i][1];
    col := owned[i][2];
    if to_regclass('public.' || t) is null then continue; end if;

    execute format('drop policy if exists %I on public.%I', t || '_own', t);
    execute format(
      'create policy %I on public.%I for all using (%I = auth.uid() or is_admin()) '
      'with check (%I = auth.uid())',
      t || '_own', t, col, col);
  end loop;
end $$;

-- Reviews and comments: everyone reads what is approved, residents write
-- their own, administrators moderate.

drop policy if exists reviews_read_approved on public.reviews;
create policy reviews_read_approved on public.reviews
  for select using (status = 'approved' or author_id = auth.uid() or is_admin());

drop policy if exists reviews_write_own on public.reviews;
create policy reviews_write_own on public.reviews
  for all using (author_id = auth.uid() or is_admin())
  with check (author_id = auth.uid());

drop policy if exists comments_read_approved on public.comments;
create policy comments_read_approved on public.comments
  for select using (status = 'approved' or author_id = auth.uid() or is_admin());

drop policy if exists comments_write_own on public.comments;
create policy comments_write_own on public.comments
  for all using (author_id = auth.uid() or is_admin())
  with check (author_id = auth.uid());

-- ─── 6. Your own profile ───

drop policy if exists profiles_read_own on public.profiles;
create policy profiles_read_own on public.profiles
  for select using (id = auth.uid() or is_admin());

drop policy if exists profiles_write_own on public.profiles;
create policy profiles_write_own on public.profiles
  for all using (id = auth.uid() or is_admin())
  with check (id = auth.uid());

-- ─── 7. Administration and money ───
-- No policy at all means no access except through the service role, which is
-- what the server uses. Administrators reach these through the panel, which
-- signs in as a real user, so they get an explicit policy.

do $$
declare
  t text;
  admin_only text[] := array[
    'admin_users', 'admin_roles', 'admin_role_permissions',
    'admin_notifications', 'audit_logs', 'trash',
    'entity_versions', 'article_versions', 'article_businesses',
    'campaigns', 'commercial_agreements', 'revenue_transactions',
    'payments', 'subscriptions', 'point_transactions',
    'push_campaigns', 'push_automations'
  ];
begin
  foreach t in array admin_only loop
    if to_regclass('public.' || t) is null then continue; end if;

    execute format('drop policy if exists %I on public.%I', t || '_admin_only', t);
    execute format(
      'create policy %I on public.%I for all using (is_admin()) with check (is_admin())',
      t || '_admin_only', t);
  end loop;
end $$;
