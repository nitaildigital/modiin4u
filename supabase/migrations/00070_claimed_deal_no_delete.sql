-- ============================================================
-- Modiin4u — Migration 00070
-- A deal someone has claimed cannot be deleted by its business
--
-- Found testing on the phones, 7 Oct: a business owner deleted a deal a
-- resident had claimed, and the resident's voucher went with it (claims
-- cascade). 00069 meant to refuse that with `offers_owner_delete`, but an
-- older policy, `offers_modify_admin` (for all commands, the owner or an
-- admin), already let an owner delete anything of theirs — and Postgres
-- allows an action when any permissive policy allows it.
--
-- A restrictive policy is checked on top of every permissive one, so it
-- holds whatever else allows the delete. The panel is not held by it: an
-- administrator may still remove a deal (and is warned in the panel).
--
-- Safe to run more than once.
-- ============================================================

drop policy if exists offers_no_delete_claimed on public.offers;
create policy offers_no_delete_claimed on public.offers
  as restrictive
  for delete to authenticated
  using (is_admin() or not public.offer_has_claims(id));
