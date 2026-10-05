-- ============================================================
-- Modiin4u — Migration 00050
-- An administrator's role holds in the database, not only in the panel
--
-- The client asked to limit roles (2 Oct). Since 5 Oct the panel shows each
-- administrator only the sections their role may view
-- (`admin_role_permissions`). But the tables' rules (00014) let any active
-- administrator write any of them, so a content editor could still change a
-- business, a deal or the revenue by calling the database directly.
--
-- This adds one restrictive rule per write (insert, update, delete) on each
-- table the panel manages: an administrator may write it only if their role
-- has that module and action — create, edit, delete — in
-- `admin_role_permissions`. Restrictive rules are added to the existing
-- ones, never in place of them, so nothing anyone could do before becomes
-- possible; it only narrows what a limited role can do.
--
-- Who is not touched:
--   * the main admin (`super_admin`) — always allowed, whatever the rows say,
--     so the client can never lock himself out;
--   * residents and visitors — the rule asks nothing of someone who is not an
--     administrator; their own rules (00014, 00032) still apply;
--   * the service role (our scripts and server functions) and functions that
--     run as their owner (the push triggers, the business statistics) — row
--     rules do not apply to them.
--
-- Left out on purpose: tables residents also write (profiles, listings,
-- reviews, comments, reports, favourites, claims, RSVPs, steps, step groups),
-- where a restrictive rule would stop an administrator using the app as a
-- resident; and the team tables, already main-admin-only (00042). The audit
-- log stays writable by every administrator: each action records itself.
--
-- Soft removal in the panel (archive, hide, cancel) is an update, so it
-- needs 'edit'. Safe to run more than once.
-- ============================================================

-- ─── May this administrator do this? ───
--
-- True for anyone who is not an active administrator (the table's own rules
-- decide for them), for the main admin, and for a role holding the right.
create or replace function public.admin_may(p_module text, p_action text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select
    not exists (
      select 1 from admin_users
       where profile_id = auth.uid() and is_active
    )
    or exists (
      select 1
        from admin_users au
        join admin_roles r on r.id = au.role_id
       where au.profile_id = auth.uid()
         and au.is_active
         and r.name = 'super_admin'
    )
    or exists (
      select 1
        from admin_users au
        join admin_role_permissions p on p.role_id = au.role_id
       where au.profile_id = auth.uid()
         and au.is_active
         and p.allowed
         and p.module = p_module
         and p.action = p_action
    );
$$;

revoke all on function public.admin_may(text, text) from public;
grant execute on function public.admin_may(text, text) to anon, authenticated;

-- ─── One rule per table and write ───
--
-- table → the module whose rights govern it, the same grouping the panel's
-- sections use (admin_dashboard_screen.dart, `_sectionModules`).
do $$
declare
  rec record;
  modules text;
  cond text;
begin
  for rec in
    select * from (values
      ('articles',               'articles'),
      ('site_pages',             'articles'),
      ('events',                 'events'),
      ('businesses',             'businesses'),
      ('business_hours',         'businesses'),
      ('business_menu_items',    'businesses'),
      ('parking_lots',           'businesses'),
      ('municipal_places',       'businesses'),
      ('real_estate_agents',     'businesses'),
      ('categories',             'categories'),
      ('tags',                   'categories'),
      ('neighborhoods',          'categories'),
      ('media',                  'media'),
      ('offers',                 'offers'),
      ('commercial_agreements',  'revenue'),
      ('revenue_transactions',   'revenue'),
      ('payments',               'revenue'),
      ('subscriptions',          'revenue'),
      ('campaigns',              'campaigns'),
      ('ad_placements',          'campaigns'),
      ('push_campaigns',         'push'),
      ('challenges',             'settings'),
      ('home_blocks',            'settings'),
      ('feature_flags',          'settings'),
      ('remote_config',          'settings'),
      ('app_settings',           'settings'),
      -- Links a content editor and a business editor both make: tagging an
      -- article, filing a business, attaching a photograph.
      ('entity_categories',      'categories|articles|businesses|events'),
      ('entity_tags',            'categories|articles|businesses|events'),
      ('entity_media',           'media|articles|businesses|events')
    ) as t(tbl, mods)
  loop
    if to_regclass('public.' || rec.tbl) is null then
      continue;
    end if;

    foreach modules in array array['create', 'edit', 'delete'] loop
      select string_agg(format('public.admin_may(%L, %L)', m, modules), ' or ')
        into cond
        from unnest(string_to_array(rec.mods, '|')) as m;

      execute format('drop policy if exists %I on public.%I',
                     rec.tbl || '_role_' || modules, rec.tbl);

      if modules = 'create' then
        execute format(
          'create policy %I on public.%I as restrictive for insert to authenticated with check (%s)',
          rec.tbl || '_role_' || modules, rec.tbl, cond);
      elsif modules = 'edit' then
        execute format(
          'create policy %I on public.%I as restrictive for update to authenticated using (%s) with check (%s)',
          rec.tbl || '_role_' || modules, rec.tbl, cond, cond);
      else
        execute format(
          'create policy %I on public.%I as restrictive for delete to authenticated using (%s)',
          rec.tbl || '_role_' || modules, rec.tbl, cond);
      end if;
    end loop;
  end loop;
end $$;
