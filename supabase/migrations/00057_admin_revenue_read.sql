-- ============================================================
-- Modiin4u — Migration 00057
-- Only the roles that may see revenue can read it
--
-- 00050 holds each administrator's writes to their role. Reading was left
-- as it was: the revenue tables' rule (00013) is `for all using
-- (is_admin())`, so a moderator or an analyst — whose panel hides Revenue
-- and Agreements and blanks the overview's revenue tab — could still read
-- every agreement, transaction and payment by calling the database
-- directly. Found testing the roles on 6 Oct.
--
-- This adds one restrictive read rule to each: an administrator reads them
-- only when their role may 'view' the 'revenue' module — today the main
-- admin, sales and finance. The panel asks the same question
-- (AdminPermissions.canView('revenue')), so no screen that a role can open
-- loses anything it showed.
--
-- Who is not touched, as in 00050: the main admin (always allowed);
-- residents and visitors (admin_may is true for them, and the tables' own
-- rules already keep them out); the service role and functions that run as
-- their owner.
--
-- Needs 00050 (admin_may). Safe to run more than once.
-- ============================================================

do $$
declare
  t text;
begin
  if to_regprocedure('public.admin_may(text, text)') is null then
    raise exception '00057 needs admin_may() from 00050 — run 00050 first';
  end if;

  foreach t in array array[
    'commercial_agreements', 'revenue_transactions', 'payments', 'subscriptions'
  ] loop
    if to_regclass('public.' || t) is null then
      continue;
    end if;
    execute format('drop policy if exists %I on public.%I', t || '_role_view', t);
    execute format(
      'create policy %I on public.%I as restrictive for select to authenticated '
      'using (public.admin_may(%L, %L))',
      t || '_role_view', t, 'revenue', 'view');
  end loop;
end $$;
