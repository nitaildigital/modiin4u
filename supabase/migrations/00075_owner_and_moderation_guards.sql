-- ============================================================
-- Modiin4u — Migration 00075
-- What a business owner and a resident can no longer do (9 Oct review)
--
--   1. Publish for a business that is not approved. An owner's rights
--      (owns_business) come with the row, pending or closed: the owner of a
--      business still waiting for the panel — or one the client closed —
--      could post a deal or a job, published at once, and a job collects
--      applicants' CVs. Now a deal or a job is written only for an active
--      business, and shown to the public only while its business is active.
--      owns_business itself is unchanged: sign-up uploads the new business's
--      photos through it, before approval.
--   2. Delete a business. `businesses_write_admin` (for all) let an owner
--      delete their own, its reviews, deals and claims going with it; the
--      role check passes for anyone not on the team (admin_may). Removal is
--      the panel's, and reversible (closed_at).
--   3. Rewrite an approved review into something else. The text and the
--      rating could change after approval and stay up; now the review goes
--      back to pending, as a new one does.
--   4. Move or rewrite an approved comment. A comment could be moved under
--      other content (entity_type, entity_id, parent_id) and its text
--      changed after approval. Now where it hangs is fixed, and new text is
--      approved as a new comment would be (replies_need_approval).
--
-- The panel (is_admin) is not affected by any of it. Safe to run more than
-- once.
-- ============================================================

-- ─── 1. Deals and jobs belong to an active business ───
create or replace function public.business_is_active(p_business uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from businesses where id = p_business and status = 'active');
$$;
revoke all on function public.business_is_active(uuid) from public;
grant execute on function public.business_is_active(uuid) to anon, authenticated;

-- Restrictive: on top of the policies that already allow a write.
drop policy if exists offers_business_active_insert on public.offers;
create policy offers_business_active_insert on public.offers
  as restrictive for insert
  with check (is_admin() or business_is_active(business_id));
drop policy if exists offers_business_active_update on public.offers;
create policy offers_business_active_update on public.offers
  as restrictive for update
  using (is_admin() or business_is_active(business_id))
  with check (is_admin() or business_is_active(business_id));

drop policy if exists jobs_business_active_insert on public.jobs;
create policy jobs_business_active_insert on public.jobs
  as restrictive for insert
  with check (is_admin() or business_is_active(business_id));
drop policy if exists jobs_business_active_update on public.jobs;
create policy jobs_business_active_update on public.jobs
  as restrictive for update
  using (is_admin() or business_is_active(business_id))
  with check (is_admin() or business_is_active(business_id));

-- Read: the public sees a deal or a job while its business is active. Its
-- owner and the team see it always; whoever claimed a deal keeps seeing it
-- (their voucher), and whoever applied keeps seeing the job.
drop policy if exists offers_business_active_read on public.offers;
create policy offers_business_active_read on public.offers
  as restrictive for select
  using (
    is_admin()
    or owns_business(business_id)
    or business_is_active(business_id)
    or exists (select 1 from offer_claims c where c.offer_id = offers.id and c.profile_id = auth.uid())
  );
drop policy if exists jobs_business_active_read on public.jobs;
create policy jobs_business_active_read on public.jobs
  as restrictive for select
  using (
    is_admin()
    or owns_business(business_id)
    or business_is_active(business_id)
    or applied_to_job(id)
  );

-- ─── 2. Only the panel deletes a business ───
drop policy if exists businesses_delete_team_only on public.businesses;
create policy businesses_delete_team_only on public.businesses
  as restrictive for delete
  using (is_admin());

-- ─── 3. An edited review is reviewed again ───
create or replace function public.reviews_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.report_count := 0;
    new.is_verified := false;
    new.admin_response := null;
    new.responded_by := null;
    new.responded_at := null;
    return new;
  end if;

  -- author_name and author_avatar_url are copied from the profile by 00029's
  -- triggers, which run as their owner and so are not stopped here.
  if new.status is distinct from old.status
     or new.report_count is distinct from old.report_count
     or new.is_verified is distinct from old.is_verified
     or new.admin_response is distinct from old.admin_response
     or new.responded_by is distinct from old.responded_by
     or new.responded_at is distinct from old.responded_at
     or new.business_id is distinct from old.business_id
     or new.author_name is distinct from old.author_name
     or new.author_avatar_url is distinct from old.author_avatar_url then
    raise exception 'a review''s status, answer, business and author are set by moderation'
      using errcode = '42501';
  end if;

  -- New words or a new rating are a new review: back to the queue (00075).
  if new.body is distinct from old.body
     or new.title is distinct from old.title
     or new.rating is distinct from old.rating then
    new.status := 'pending';
  end if;
  return new;
end;
$$;

-- ─── 4. A comment stays where it was written ───
create or replace function public.comments_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    -- An administrator's comment from the app comes in at the column's
    -- default, 'pending', which left the team's own replies waiting for the
    -- team. The panel sets a status itself when it means another.
    if tg_op = 'INSERT' and is_admin() and new.status = 'pending'
       and new.entity_type in ('review', 'article') then
      new.status := 'approved';
    end if;
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.entity_type in ('review', 'article') and not coalesce(
      (select value = 'true'::jsonb from app_settings
        where key = 'replies_need_approval'),
      false) then
      new.status := 'approved';
    else
      new.status := 'pending';
    end if;
    new.report_count := 0;
    return new;
  end if;

  if new.status is distinct from old.status
     or new.report_count is distinct from old.report_count then
    raise exception 'a comment''s status and report count are set by moderation'
      using errcode = '42501';
  end if;
  -- Where a comment hangs is fixed once written (00075).
  if new.entity_type is distinct from old.entity_type
     or new.entity_id is distinct from old.entity_id
     or new.parent_id is distinct from old.parent_id then
    raise exception 'a comment cannot be moved'
      using errcode = '42501';
  end if;
  -- New words are approved as a new comment would be.
  if new.body is distinct from old.body
     and not (new.entity_type in ('review', 'article') and not coalesce(
       (select value = 'true'::jsonb from app_settings
         where key = 'replies_need_approval'),
       false)) then
    new.status := 'pending';
  end if;
  return new;
end;
$$;
