-- ============================================================
-- Modiin4u — Migration 00051
-- Business owners: requests, approval, and what an owner may change
--
-- Approved by the client on 5 Oct. His decisions: an owner account is made
-- either by him in the panel, or by the owner, who signs up and asks for
-- their business, which he approves; he keeps full control from the panel;
-- an owner's edits and deals go live at once.
--
-- Already in place: `businesses.owner_id`; the rule that an owner may read
-- and write their own business (00014); and the guard that leaves its
-- status, verification, promotion, rating and owner to the panel (00033).
-- This adds:
--
--   1. `business_owner_requests` — "this business is mine", from a signed-in
--      person, with a phone and a note; the panel approves or rejects it;
--   2. panel functions to approve, reject, assign and remove an owner —
--      removal is reversible (the owner is unset, nothing is deleted);
--   3. an owner's own business's hours, menu, photos and deals — deals live
--      at once, but never featured, never points, never touching the counts;
--   4. photo uploads under `businesses/<business id>/` in the media bucket;
--   5. the business statistics (00048) readable by the business's owner.
--
-- "Owner" is not a stored role: someone is an owner of every business whose
-- `owner_id` is theirs. Safe to run more than once.
-- ============================================================

-- ─── Is this business the caller's? ───
-- 00013 made it with this parameter name, and a function's parameter cannot
-- be renamed in place; it keeps it.
create or replace function public.owns_business(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null and exists (
    select 1 from businesses where id = p_business_id and owner_id = auth.uid()
  );
$$;

revoke all on function public.owns_business(uuid) from public;
grant execute on function public.owns_business(uuid) to anon, authenticated;

-- The same, for a business id written as text — a storage folder name. A
-- folder that is not an id is simply not theirs: casting it would fail the
-- upload of every other folder (`listings/`, `avatars/`) in the bucket.
create or replace function public.owns_business_path(p_folder text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_folder ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
     and public.owns_business(p_folder::uuid);
$$;

revoke all on function public.owns_business_path(text) from public;
grant execute on function public.owns_business_path(text) to authenticated;

-- ─── 1. Requests ───

create table if not exists public.business_owner_requests (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  business_id  uuid not null references public.businesses(id) on delete cascade,
  contact_name text,
  phone        text,
  message      text,
  status       text not null default 'pending'
               check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  reason       text,               -- why it was rejected, shown to the person
  decided_by   uuid references public.profiles(id) on delete set null,
  decided_at   timestamptz,
  created_at   timestamptz not null default now()
);

-- One open request per person and business.
create unique index if not exists business_owner_requests_one_open
  on public.business_owner_requests (profile_id, business_id)
  where status = 'pending';
create index if not exists idx_business_owner_requests_status
  on public.business_owner_requests (status, created_at desc);

alter table public.business_owner_requests enable row level security;

drop policy if exists owner_requests_read on public.business_owner_requests;
create policy owner_requests_read on public.business_owner_requests
  for select using (profile_id = auth.uid() or is_admin());

-- A person asks for themselves only, and only as a new request.
drop policy if exists owner_requests_ask on public.business_owner_requests;
create policy owner_requests_ask on public.business_owner_requests
  for insert to authenticated
  with check (profile_id = auth.uid() and status = 'pending'
              and decided_by is null and decided_at is null and reason is null);

-- They may withdraw their own pending request; deciding is the panel's,
-- through the functions below.
drop policy if exists owner_requests_withdraw on public.business_owner_requests;
create policy owner_requests_withdraw on public.business_owner_requests
  for update to authenticated
  using (profile_id = auth.uid() and status = 'pending')
  with check (profile_id = auth.uid() and status = 'cancelled');

-- ─── 2. The panel's side ───
--
-- Each needs an administrator whose role may edit businesses (00050), and
-- writes the activity log like every panel action.

-- A business that already has another owner is not handed over silently:
-- the panel must ask to replace them (p_replace).
create or replace function public.admin_assign_business_owner(
  p_business uuid,
  p_profile  uuid,
  p_replace  boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_current uuid;
begin
  if not is_admin() or not admin_may('businesses', 'edit') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  select owner_id into v_current from businesses where id = p_business for update;
  if v_current is not null and v_current <> p_profile and not p_replace then
    raise exception 'business-has-owner' using errcode = 'P0001';
  end if;
  update businesses set owner_id = p_profile where id = p_business;
  insert into audit_logs (admin_id, action, entity_type, entity_id, after_data)
  values (auth.uid(), 'update', 'businesses', p_business,
          jsonb_build_object('owner_id', p_profile));
end;
$$;

create or replace function public.admin_remove_business_owner(p_business uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_before uuid;
begin
  if not is_admin() or not admin_may('businesses', 'edit') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  select owner_id into v_before from businesses where id = p_business;
  update businesses set owner_id = null where id = p_business;
  insert into audit_logs (admin_id, action, entity_type, entity_id, before_data, after_data)
  values (auth.uid(), 'update', 'businesses', p_business,
          jsonb_build_object('owner_id', v_before), jsonb_build_object('owner_id', null));
end;
$$;

create or replace function public.admin_decide_owner_request(
  p_request uuid,
  p_approve boolean,
  p_reason  text default null,
  p_replace boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r business_owner_requests;
begin
  if not is_admin() or not admin_may('businesses', 'edit') then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  select * into r from business_owner_requests where id = p_request for update;
  if r.id is null or r.status <> 'pending' then
    raise exception 'request is not pending';
  end if;
  -- Assigning first, so a business that already has an owner stops the
  -- approval before anything is written.
  if p_approve then
    perform admin_assign_business_owner(r.business_id, r.profile_id, p_replace);
  end if;

  update business_owner_requests
     set status = case when p_approve then 'approved' else 'rejected' end,
         reason = case when p_approve then null else nullif(trim(p_reason), '') end,
         decided_by = auth.uid(),
         decided_at = now()
   where id = p_request;

  if p_approve then
    -- Anyone else waiting for the same business is told it went elsewhere.
    update business_owner_requests
       set status = 'rejected', reason = 'assigned to another owner',
           decided_by = auth.uid(), decided_at = now()
     where business_id = r.business_id and status = 'pending' and id <> p_request;
  end if;
end;
$$;

revoke all on function public.admin_assign_business_owner(uuid, uuid, boolean) from public, anon;
revoke all on function public.admin_remove_business_owner(uuid) from public, anon;
revoke all on function public.admin_decide_owner_request(uuid, boolean, text, boolean) from public, anon;
grant execute on function public.admin_assign_business_owner(uuid, uuid, boolean) to authenticated;
grant execute on function public.admin_remove_business_owner(uuid) to authenticated;
grant execute on function public.admin_decide_owner_request(uuid, boolean, text, boolean) to authenticated;

-- ─── 3. What an owner may change on their business ───

-- Hours and menu: their own business's rows.
do $$
declare
  t text;
begin
  foreach t in array array['business_hours', 'business_menu_items'] loop
    if to_regclass('public.' || t) is null then continue; end if;
    execute format('drop policy if exists %I on public.%I', t || '_owner_write', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (public.owns_business(business_id))
         with check (public.owns_business(business_id))',
      t || '_owner_write', t);
  end loop;
end $$;

-- Deals: their own business's, live at once. The rest stays the panel's.
drop policy if exists offers_owner_read on public.offers;
create policy offers_owner_read on public.offers
  for select to authenticated using (public.owns_business(business_id));

-- Add and edit; not delete — a deleted deal takes residents' claims with it,
-- and removal stays reversible: an owner ends a deal by its status.
drop policy if exists offers_owner_write on public.offers;
drop policy if exists offers_owner_insert on public.offers;
create policy offers_owner_insert on public.offers
  for insert to authenticated
  with check (public.owns_business(business_id));

drop policy if exists offers_owner_update on public.offers;
create policy offers_owner_update on public.offers
  for update to authenticated
  using (public.owns_business(business_id))
  with check (public.owns_business(business_id));

create or replace function public.offers_owner_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if is_admin() or current_user not in ('authenticated', 'anon') then
    return coalesce(new, old);
  end if;
  if tg_op = 'INSERT' then
    new.is_featured := false;
    new.points_required := 0;
    new.view_count := 0;
    new.claim_count := 0;
    new.redeem_count := 0;
    return new;
  end if;
  if tg_op = 'UPDATE' and (
       new.is_featured is distinct from old.is_featured
    or new.points_required is distinct from old.points_required
    or new.business_id is distinct from old.business_id
    or new.view_count is distinct from old.view_count
    or new.claim_count is distinct from old.claim_count
    or new.redeem_count is distinct from old.redeem_count) then
    raise exception 'featuring, points, the business and the counts of a deal are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists offers_owner_guard on public.offers;
create trigger offers_owner_guard
  before insert or update on public.offers
  for each row execute function public.offers_owner_guard();

-- A business's notification columns (00045) are the panel's and the
-- trigger's: an owner writing them could queue city-wide pushes at will, or
-- point the row at another campaign. 00033's guard predates them.
create or replace function public.businesses_push_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.notify_on_publish := false;
    new.push_campaign_id := null;
  else
    new.notify_on_publish := old.notify_on_publish;
    new.push_campaign_id := old.push_campaign_id;
  end if;
  return new;
end;
$$;

-- Named to run before 00045's `businesses_queue_push` (triggers run in name
-- order), so the push trigger sees the kept values.
drop trigger if exists businesses_a_push_guard on public.businesses;
create trigger businesses_a_push_guard
  before insert or update on public.businesses
  for each row execute function public.businesses_push_guard();

-- Photos: the media rows they upload, and links from their business to them.
drop policy if exists media_owner_insert on public.media;
create policy media_owner_insert on public.media
  for insert to authenticated with check (uploaded_by = auth.uid());

drop policy if exists entity_media_owner_write on public.entity_media;
create policy entity_media_owner_write on public.entity_media
  for all to authenticated
  using (entity_type = 'business' and public.owns_business(entity_id))
  with check (entity_type = 'business' and public.owns_business(entity_id));

-- ─── 4. Uploading photos: businesses/<business id>/<file> ───
drop policy if exists "media_business_owner_insert" on storage.objects;
create policy "media_business_owner_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'businesses'
    and public.owns_business_path((storage.foldername(name))[2])
  );

drop policy if exists "media_business_owner_update" on storage.objects;
create policy "media_business_owner_update"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'businesses'
    and public.owns_business_path((storage.foldername(name))[2])
  );

drop policy if exists "media_business_owner_delete" on storage.objects;
create policy "media_business_owner_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'businesses'
    and public.owns_business_path((storage.foldername(name))[2])
  );

-- ─── 5. An owner reads their business's statistics ───

create or replace function public.business_stats(
  p_business uuid,
  p_from     date,
  p_to       date,
  p_bucket   text default 'day'
)
returns table (period date, kind text, total bigint, visitors bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (is_admin() or owns_business(p_business)) then
    raise exception 'not allowed';
  end if;
  if p_bucket not in ('day', 'week', 'month') then
    raise exception 'bucket must be day, week or month';
  end if;

  return query
    with local as (
      select e.kind, e.visitor, (e.created_at at time zone 'Asia/Jerusalem')::date as d
        from business_events e
       where e.business_id = p_business
         and e.created_at >= (p_from::timestamp at time zone 'Asia/Jerusalem')
         and e.created_at <  ((p_to + 1)::timestamp at time zone 'Asia/Jerusalem')
    )
    select case p_bucket
             when 'day' then l.d
             when 'week' then l.d - extract(dow from l.d)::int
             else date_trunc('month', l.d)::date
           end as period,
           l.kind,
           count(*) as total,
           count(distinct l.visitor) as visitors
      from local l
     group by 1, 2
     order by 1, 2;
end;
$$;

create or replace function public.business_stats_totals(
  p_business uuid,
  p_from     date,
  p_to       date
)
returns table (kind text, total bigint, visitors bigint)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (is_admin() or owns_business(p_business)) then
    raise exception 'not allowed';
  end if;

  return query
    select e.kind, count(*), count(distinct e.visitor)
      from business_events e
     where e.business_id = p_business
       and e.created_at >= (p_from::timestamp at time zone 'Asia/Jerusalem')
       and e.created_at <  ((p_to + 1)::timestamp at time zone 'Asia/Jerusalem')
     group by e.kind;
end;
$$;
