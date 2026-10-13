-- ============================================================
-- Modiin4u — Migration 00083
-- Open jobs readable by a visitor who is not signed in
--
-- The website's job pages (13 Oct) read open jobs as a visitor. `jobs_read`
-- already lets anyone see an active job that has not expired, but Postgres
-- checks every SELECT policy on the table, and `jobs_applicant_read` /
-- `jobs_business_active_read` call `applied_to_job()`, which `anon` was not
-- allowed to run — so the whole read failed ("permission denied for function
-- applied_to_job") instead of returning the open jobs.
--
-- The function answers only "has the signed-in user applied to this job?"
-- (false with no user), like owns_business() and business_is_active(), which
-- anon already runs. Nothing else changes: what a visitor sees is still
-- `jobs_read`'s open jobs. Safe to run more than once.
-- ============================================================

grant execute on function public.applied_to_job(uuid) to anon;
