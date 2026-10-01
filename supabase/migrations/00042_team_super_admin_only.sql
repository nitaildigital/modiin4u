-- ============================================================
-- Modiin4u — Migration 00042
-- Only a super admin manages the team
--
-- `admin_roles` holds eight roles — super admin, content editor, business
-- manager, sales, moderator, finance, support, analyst — and none of them
-- limited anything: `admin_users` and `admin_roles` were writable by any
-- active admin (00014's admin-only policy). Today all three admins are super
-- admins, so nobody is exposed; but the first content editor the client adds
-- could open Team and make themselves a super admin, or add whoever they
-- like.
--
-- What each role may do section by section is for the client to decide, and
-- is not attempted here. This closes the one door that matters whatever he
-- decides: every admin still reads the team and the roles (the panel shows
-- them, and `is_admin()` reads the table as its definer, not through these
-- policies), but adding, changing or removing a member, or a role, takes a
-- super admin. The panel's own guards (no demoting yourself, never the last
-- super admin) stay as they are.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.is_super_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from admin_users au
    join admin_roles r on r.id = au.role_id
    where au.profile_id = auth.uid()
      and au.is_active
      and r.name = 'super_admin'
  );
$$;

revoke all on function public.is_super_admin() from public, anon;
grant execute on function public.is_super_admin() to authenticated;

do $$
declare
  t text;
begin
  foreach t in array array['admin_users', 'admin_roles'] loop
    execute format('drop policy if exists %I on public.%I', t || '_admin_only', t);
    execute format('drop policy if exists %I on public.%I', t || '_read', t);
    execute format('drop policy if exists %I on public.%I', t || '_insert', t);
    execute format('drop policy if exists %I on public.%I', t || '_update', t);
    execute format('drop policy if exists %I on public.%I', t || '_delete', t);

    execute format(
      'create policy %I on public.%I for select using (public.is_admin())',
      t || '_read', t);
    execute format(
      'create policy %I on public.%I for insert with check (public.is_super_admin())',
      t || '_insert', t);
    execute format(
      'create policy %I on public.%I for update using (public.is_super_admin()) with check (public.is_super_admin())',
      t || '_update', t);
    execute format(
      'create policy %I on public.%I for delete using (public.is_super_admin())',
      t || '_delete', t);
  end loop;
end $$;
