-- ============================================================
-- Modiin4u — Migration 00066
-- Article views, listings that expire, a reply to the reporter,
-- neighbourhoods in English
--
-- From the tracker (7 Oct):
--   1. Article views were never counted (39): "most viewed" ranked the
--      numbers imported from WordPress. A view now counts once per visitor
--      per article per 30 minutes, as business views do (00048), on top of
--      the imported count.
--   2. An approved listing never expired, and approval set no publishing
--      date. Approval now stamps `published_at`, and — when the panel's
--      Settings say how many days a listing stays up
--      (`app_settings.listings_expire_days`; unset or 0, never) —
--      `expires_at`; a nightly job moves listings past it to 'expired', and
--      their owner is told.
--   3. A resident who reported something heard nothing more. When the
--      panel resolves or dismisses the report, the reporter is told.
--   4. Neighbourhood names stayed Hebrew in English: `name_en`, as
--      businesses and categories have (00062). Empty shows the Hebrew; the
--      panel fills it in. Nothing is filled here.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Article views ───
create table if not exists public.article_views (
  id         bigint generated always as identity primary key,
  article_id uuid not null references public.articles(id) on delete cascade,
  visitor    text not null check (length(visitor) between 8 and 64),
  platform   text not null check (platform in ('app', 'web')),
  created_at timestamptz not null default now()
);
create index if not exists idx_article_views_article_visitor
  on public.article_views (article_id, visitor, created_at);

alter table public.article_views enable row level security;
-- No policies: written only through record_article_view.

create or replace function public.record_article_view(
  p_article  uuid,
  p_platform text,
  p_visitor  text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from article_views
     where article_id = p_article
       and visitor = p_visitor
       and created_at > now() - interval '30 minutes'
  ) then
    return;
  end if;
  if not exists (select 1 from articles where id = p_article and status = 'published') then
    return;
  end if;
  insert into article_views (article_id, visitor, platform)
  values (p_article, p_visitor, p_platform);
  update articles set view_count = coalesce(view_count, 0) + 1 where id = p_article;
end;
$$;

revoke all on function public.record_article_view(uuid, text, text) from public;
grant execute on function public.record_article_view(uuid, text, text) to anon, authenticated;

-- A view is not an edit: the counters changing alone leave `updated_at`
-- (which the site gives search engines as the article's date) as it was.
drop trigger if exists articles_updated_at on public.articles;
create trigger articles_updated_at
  before update on public.articles
  for each row
  when ((to_jsonb(new) - 'view_count' - 'unique_views' - 'share_count' - 'save_count' - 'updated_at')
        is distinct from
        (to_jsonb(old) - 'view_count' - 'unique_views' - 'share_count' - 'save_count' - 'updated_at'))
  execute function update_updated_at();

-- ─── 2. Listings: published and expiry dates on approval, nightly expiry ───
create or replace function public.listings_stamp_approval()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_days int;
begin
  if new.status <> 'active'
     or (tg_op = 'UPDATE' and old.status = 'active') then
    return new;
  end if;
  new.published_at := coalesce(new.published_at, now());
  select case when jsonb_typeof(value) = 'number' then value::text::int end
    into v_days
    from app_settings where key = 'listings_expire_days';
  if coalesce(v_days, 0) > 0
     and (new.expires_at is null or new.expires_at < now()) then
    new.expires_at := now() + make_interval(days => v_days);
  end if;
  return new;
end;
$$;

-- Named to run before listings_guard_columns (00033/00055), which only
-- concerns residents; residents never set 'active' themselves.
drop trigger if exists listings_a_stamp_approval on public.listings;
create trigger listings_a_stamp_approval
  before insert or update of status on public.listings
  for each row execute function public.listings_stamp_approval();

create or replace function public.expire_listings()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
begin
  for r in
    update listings set status = 'expired'
     where status = 'active'
       and expires_at is not null
       and expires_at < now()
    returning id, title, owner_id
  loop
    if r.owner_id is not null then
      insert into push_campaigns (
        title, body, title_en, body_en, deep_link,
        status, scheduled_at, audience_type, audience_filter, source_type, source_id
      ) values (
        'המודעה שלך פגה', snippet(r.title, 100) || ' — אפשר לפרסם אותה מחדש בדירות שלי.',
        'Your listing has expired', snippet(r.title, 100) || ' — you can post it again from My Apartments.',
        '/my-apartments',
        'scheduled', now(), 'profiles',
        jsonb_build_object('profile_ids', jsonb_build_array(r.owner_id)),
        'listing', r.id
      );
    end if;
  end loop;
end;
$$;

revoke all on function public.expire_listings() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.unschedule('expire-listings')
 where exists (select 1 from cron.job where jobname = 'expire-listings');
-- 01:10 UTC: 03:10–04:10 in Modi'in.
select cron.schedule('expire-listings', '10 1 * * *', $job$ select public.expire_listings(); $job$);

-- ─── 3. The reporter hears what became of their report ───
create or replace function public.reports_after_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  r          reports;
  v_open     int;
  v_hide_at  int;
  v_admins   jsonb;
  v_what     text;
  v_what_en  text;
begin
  if tg_op = 'DELETE' then r := old; else r := new; end if;

  select count(*) into v_open
    from reports
   where entity_type = r.entity_type
     and entity_id = r.entity_id
     and status in ('open', 'reviewed');

  if r.entity_type = 'review' then
    update reviews set report_count = v_open
     where id = r.entity_id and report_count is distinct from v_open;
  elsif r.entity_type = 'comment' then
    update comments set report_count = v_open
     where id = r.entity_id and report_count is distinct from v_open;
  end if;

  v_what := case r.entity_type
    when 'review' then 'ביקורת' when 'comment' then 'תגובה'
    when 'business' then 'עסק' when 'listing' then 'מודעת נדל״ן'
    else 'תוכן' end;
  v_what_en := case r.entity_type
    when 'review' then 'a review' when 'comment' then 'a reply'
    when 'business' then 'a business' when 'listing' then 'a listing'
    else 'content' end;

  -- Closed by the panel: the reporter is told, once.
  if tg_op = 'UPDATE'
     and old.status in ('open', 'reviewed')
     and new.status in ('resolved', 'dismissed') then
    insert into push_campaigns (
      title, body, title_en, body_en,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'עדכון על הדיווח שלך',
      case new.status
        when 'resolved' then 'בדקנו את הדיווח שלך על ' || v_what || ' וטיפלנו בו. תודה שעזרת לשמור על הקהילה.'
        else 'בדקנו את הדיווח שלך על ' || v_what || ' ולא מצאנו שהוא מפר את הכללים. תודה על הדיווח.'
      end,
      'An update on your report',
      case new.status
        when 'resolved' then 'We looked at your report about ' || v_what_en || ' and dealt with it. Thank you for helping.'
        else 'We looked at your report about ' || v_what_en || ' and found it within the rules. Thank you for reporting.'
      end,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', jsonb_build_array(new.reporter_id)),
      'report_result', new.id
    );
    return null;
  end if;

  if tg_op <> 'INSERT' then
    return null;
  end if;

  select case when jsonb_typeof(value) = 'number' then value::text::int end
    into v_hide_at
    from app_settings where key = 'reports_auto_hide_at';
  if coalesce(v_hide_at, 0) > 0 and v_open >= v_hide_at then
    if r.entity_type = 'review' then
      update reviews set status = 'hidden'
       where id = r.entity_id and status = 'approved';
    elsif r.entity_type = 'comment' then
      update comments set status = 'hidden'
       where id = r.entity_id and status = 'approved';
    end if;
  end if;

  if v_open = 1 then
    v_admins := moderator_profile_ids('moderation');
    if v_admins is not null then
      insert into push_campaigns (
        title, body, title_en, body_en,
        status, scheduled_at, audience_type, audience_filter, source_type, source_id
      ) values (
        'דיווח חדש', 'תושב דיווח על ' || v_what || '. פרטים בניהול ← דיווחים.',
        'New report', 'A resident reported ' || v_what_en || '. See the panel → Reports.',
        'scheduled', now(), 'profiles',
        jsonb_build_object('profile_ids', v_admins),
        'report', r.id
      );
    end if;
  end if;

  return null;
end;
$$;

-- ─── 4. Neighbourhoods in English ───
alter table public.neighborhoods add column if not exists name_en text;

-- ─── 5. Who may change what a role may do ───
-- Every active administrator could write `admin_role_permissions`, so a
-- content editor could give their own role every right — 00050's
-- enforcement reads these rows. Reading stays open to administrators (the
-- panel shows each one its sections); writing is the main admin's, as
-- changing the team and the roles already is (00042). The panel's Team
-- section edits them (Roles & rights).
drop policy if exists admin_role_permissions_admin_only on public.admin_role_permissions;
drop policy if exists admin_role_permissions_read on public.admin_role_permissions;
drop policy if exists admin_role_permissions_write on public.admin_role_permissions;
create policy admin_role_permissions_read on public.admin_role_permissions
  for select to authenticated using (is_admin());
create policy admin_role_permissions_write on public.admin_role_permissions
  for all to authenticated using (is_super_admin()) with check (is_super_admin());

-- ─── 6. A deal that has ended cannot be claimed ───
-- Found 7 Oct: half the deals marked active were past their end date, and a
-- claim on one was accepted — a voucher for a deal already over. The phone's
-- list hides ended deals, but a link or an open page still reached them.
-- Only a resident's claim is checked; the panel may still record one.
create or replace function public.offer_claims_live_offer()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;
  if not exists (
    select 1 from offers
     where id = new.offer_id
       and status = 'active'
       and (start_at is null or start_at <= now())
       and (end_at is null or end_at > now())
  ) then
    raise exception 'offer-ended' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists offer_claims_a_live_offer on public.offer_claims;
create trigger offer_claims_a_live_offer
  before insert on public.offer_claims
  for each row execute function public.offer_claims_live_offer();
