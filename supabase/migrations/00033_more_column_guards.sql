-- More columns a resident may not write
--
-- 00032 closed this for profiles, comments, reports, steps, challenges and
-- games. The same gap is open on four more tables, whose policies check that
-- the row is the resident's own and nothing about what goes in it:
--   * reviews — an author could post a review already approved (it then
--     counts towards the business's rating), answer it as the business, or
--     move an approved review to another business;
--   * listings — an owner could publish straight to the directory, feature
--     their own listing, or edit a live listing without it being reviewed
--     again (`listings_owner_update` has no WITH CHECK at all);
--   * businesses — `businesses_write_admin` lets an owner insert and update
--     their business, so an owner could verify, feature, sponsor or activate
--     it, or set its own rating;
--   * offer_claims — a claimant could mark their own claim redeemed.
--
-- Same approach and the same `is_resident_write()` helper as 00032:
-- administrators, the service role and the database's own SECURITY DEFINER
-- functions (the rating rollup from 00025, the review author copy from 00029)
-- pass untouched. For a resident, a new row gets the defaults and an update
-- that changes a guarded column is refused.
--
-- What the app writes, and so what stays open:
--   * reviews — business_id, author_id, rating, body on insert;
--   * listings — a draft or a pending listing (Add Apartment, Save Draft),
--     and the rewrite of an own draft, which may send it on as pending;
--   * event_attendees — status 'going' on RSVP, 'cancelled' on cancel. That
--     is the only column there besides the keys, so it is left alone;
--   * offer_claims — offer_id and profile_id only;
--   * favorites — keys only, nothing to guard.

-- ─── reviews: moderation, the business's answer, and who wrote it ───
create or replace function reviews_guard_columns()
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
  return new;
end;
$$;

drop trigger if exists reviews_guard_columns on reviews;
create trigger reviews_guard_columns
  before insert or update on reviews
  for each row execute function reviews_guard_columns();

-- ─── listings: only drafts and listings waiting for review ───
-- A resident's listing is either being written (draft) or waiting for the
-- panel (pending). Publishing, marking sold or rented, expiring and removing
-- are the panel's. An update has to leave the listing draft or pending too,
-- so a live listing cannot be edited in place: an owner's change sends it
-- back for review.
create or replace function listings_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if new.status not in ('draft', 'pending') then
    raise exception 'a listing can only be saved as a draft or sent for review'
      using errcode = '42501';
  end if;

  if tg_op = 'INSERT' then
    new.is_featured := false;
    new.view_count := 0;
    new.published_at := null;
    new.expires_at := null;
    new.agent_id := null;
    return new;
  end if;

  if new.is_featured is distinct from old.is_featured
     or new.view_count is distinct from old.view_count
     or new.published_at is distinct from old.published_at
     or new.expires_at is distinct from old.expires_at
     or new.agent_id is distinct from old.agent_id
     or new.owner_id is distinct from old.owner_id then
    raise exception 'featuring, publishing dates, the agency and the owner of a listing are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists listings_guard_columns on listings;
create trigger listings_guard_columns
  before insert or update on listings
  for each row execute function listings_guard_columns();

-- ─── businesses: status, verification, promotion and the rating ───
-- The app has no screen where an owner edits their business, but the
-- policies allow it, so the columns the client sells or moderates are held.
-- A business an owner adds waits for review.
create or replace function businesses_guard_columns()
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
    new.is_verified := false;
    new.is_featured := false;
    new.is_sponsored := false;
    new.is_recommended := false;
    new.featured_start := null;
    new.featured_end := null;
    new.rating := 0;
    new.review_count := 0;
    new.approved_at := null;
    new.closed_at := null;
    return new;
  end if;

  if new.status is distinct from old.status
     or new.is_verified is distinct from old.is_verified
     or new.is_featured is distinct from old.is_featured
     or new.is_sponsored is distinct from old.is_sponsored
     or new.is_recommended is distinct from old.is_recommended
     or new.featured_start is distinct from old.featured_start
     or new.featured_end is distinct from old.featured_end
     or new.rating is distinct from old.rating
     or new.review_count is distinct from old.review_count
     or new.approved_at is distinct from old.approved_at
     or new.closed_at is distinct from old.closed_at
     or new.owner_id is distinct from old.owner_id then
    raise exception 'a business''s status, verification, promotion, rating and owner are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists businesses_guard_columns on businesses;
create trigger businesses_guard_columns
  before insert or update on businesses
  for each row execute function businesses_guard_columns();

-- ─── offer_claims: whether the offer was used ───
-- Redeeming happens at the business, not on the claimant's phone.
create or replace function offer_claims_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.redeemed := false;
    new.redeemed_at := null;
    return new;
  end if;

  if new.redeemed is distinct from old.redeemed
     or new.redeemed_at is distinct from old.redeemed_at then
    raise exception 'a claim is marked redeemed by the business, not by the claimant'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists offer_claims_guard_columns on offer_claims;
create trigger offer_claims_guard_columns
  before insert or update on offer_claims
  for each row execute function offer_claims_guard_columns();

-- `offer_claims_own` lets an admin reach a claim but its WITH CHECK is only
-- `profile_id = auth.uid()`, so an admin could not mark someone's claim
-- redeemed — and with the guard above nobody else can either. The same fix
-- 00031 made for comments and reports.
drop policy if exists offer_claims_admin_update on offer_claims;
create policy offer_claims_admin_update
  on offer_claims for update
  using (is_admin()) with check (is_admin());
