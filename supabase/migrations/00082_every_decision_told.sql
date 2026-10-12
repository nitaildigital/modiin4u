-- ============================================================
-- Modiin4u — Migration 00082
-- Every decision about someone's content reaches them
--
-- Harshit, 12 Oct: "when we get the confirmation e-mail or anything, we need
-- to send a notification — for approved or declined, all things." What was
-- already told (00063–00081): a review or a reply published, a business
-- approved, a photo approved or not, a promotion approved or declined, an
-- application's status, an event published, a report answered, a listing
-- expired. What was not, and is now:
--
--   * Confirming the e-mail — a welcome. (No device is registered yet; the
--     bell shows it once they sign in on one.)
--   * A review not approved, or hidden after it was shown.
--   * A comment on an article published; any comment not approved, or
--     hidden after it was shown.
--   * A real-estate listing approved, or not approved.
--   * A business not approved (closed or suspended from the queue), or
--     suspended after it was live.
--   * A business's event not approved (cancelled by the panel from the
--     queue).
--
-- The panel's own decisions only: a resident withdrawing their own listing
-- or event, or an owner closing their business, is not told about it.
--
-- Needs 00069 (notify_people, business_owner_ids), 00081. Safe to run more
-- than once.
-- ============================================================

-- ─── The welcome, when the e-mail is confirmed ───

create or replace function public.on_email_confirmed()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.email_confirmed_at is null and new.email_confirmed_at is not null
     and exists (select 1 from profiles where id = new.id) then
    perform notify_people(
      jsonb_build_array(new.id),
      'ברוכים הבאים למודיעין בשבילך!', 'כתובת האימייל אומתה והחשבון מוכן. כל מה שקורה בעיר — במקום אחד.',
      'Welcome to Modiin4U!', 'Your e-mail is confirmed and your account is ready. Everything happening in the city, in one place.',
      '/', 'welcome', new.id
    );
  end if;
  return new;
exception when others then
  -- A confirmation must never fail because of its welcome.
  return new;
end;
$$;

revoke all on function public.on_email_confirmed() from public, anon, authenticated;

drop trigger if exists on_email_confirmed on auth.users;
create trigger on_email_confirmed
  after update of email_confirmed_at on auth.users
  for each row execute function public.on_email_confirmed();

-- ─── Reviews ───

create or replace function public.on_review_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business text;
  v_link     text;
begin
  if new.status is not distinct from old.status or new.author_id is null then
    return new;
  end if;
  select name into v_business from businesses where id = new.business_id;
  v_link := '/business/' || new.business_id || '?review=' || new.id;

  if old.status = 'pending' and new.status = 'rejected' then
    perform notify_people(
      jsonb_build_array(new.author_id),
      'הביקורת שלך לא אושרה', coalesce(v_business, '') || ' — הביקורת לא עמדה בכללי הקהילה ולא פורסמה.',
      'Your review was not approved', coalesce(v_business, '') || ' — it did not meet the community rules and was not published.',
      null, 'review_rejected', new.id
    );
  elsif old.status = 'approved' and new.status in ('hidden', 'rejected') then
    perform notify_people(
      jsonb_build_array(new.author_id),
      'הביקורת שלך הוסתרה', coalesce(v_business, '') || ' — הביקורת הוסרה מהעמוד לאחר בדיקה.',
      'Your review was hidden', coalesce(v_business, '') || ' — it was taken off the page after a review.',
      null, 'review_hidden', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_review_decision() from public, anon, authenticated;

drop trigger if exists reviews_after_decision on public.reviews;
create trigger reviews_after_decision
  after update of status on public.reviews
  for each row execute function public.on_review_decision();

-- ─── Comments (replies to reviews, comments on articles) ───

create or replace function public.on_comment_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_where text;
  v_link  text;
begin
  if new.status is not distinct from old.status or new.author_id is null then
    return new;
  end if;

  if new.entity_type = 'article' then
    select title into v_where from articles where id = new.entity_id;
    v_link := '/article/' || new.entity_id || '?comment=' || new.id;
    -- A reply to a review is told it is published already (00063).
    if old.status = 'pending' and new.status = 'approved' then
      perform notify_people(
        jsonb_build_array(new.author_id),
        'התגובה שלך פורסמה', coalesce(v_where, '') || ': ' || snippet(new.body, 100),
        'Your comment is published', coalesce(v_where, '') || ': ' || snippet(new.body, 100),
        v_link, 'comment_published', new.id
      );
      return new;
    end if;
  elsif new.entity_type = 'review' then
    select b.name into v_where from reviews r join businesses b on b.id = r.business_id where r.id = new.entity_id;
  end if;

  if old.status = 'pending' and new.status = 'rejected' then
    perform notify_people(
      jsonb_build_array(new.author_id),
      'התגובה שלך לא אושרה', coalesce(v_where || ' — ', '') || 'התגובה לא עמדה בכללי הקהילה ולא פורסמה.',
      'Your comment was not approved', coalesce(v_where || ' — ', '') || 'it did not meet the community rules and was not published.',
      null, 'comment_rejected', new.id
    );
  elsif old.status = 'approved' and new.status in ('hidden', 'rejected') then
    perform notify_people(
      jsonb_build_array(new.author_id),
      'התגובה שלך הוסתרה', coalesce(v_where || ' — ', '') || 'התגובה הוסרה לאחר בדיקה.',
      'Your comment was hidden', coalesce(v_where || ' — ', '') || 'it was taken down after a review.',
      null, 'comment_hidden', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_comment_decision() from public, anon, authenticated;

drop trigger if exists comments_after_decision on public.comments;
create trigger comments_after_decision
  after update of status on public.comments
  for each row execute function public.on_comment_decision();

-- ─── Real-estate listings ───

create or replace function public.on_listing_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is not distinct from old.status or new.owner_id is null or old.status <> 'pending' then
    return new;
  end if;
  if new.status = 'active' then
    perform notify_people(
      jsonb_build_array(new.owner_id),
      'המודעה שלך אושרה', coalesce(new.title, '') || ' מוצגת עכשיו באפליקציה.',
      'Your listing is approved', coalesce(new.title, '') || ' is now shown in the app.',
      '/listing/' || new.id, 'listing_approved', new.id
    );
  elsif new.status = 'removed' and is_admin() then
    perform notify_people(
      jsonb_build_array(new.owner_id),
      'המודעה שלך לא אושרה', coalesce(new.title, '') || ' — לפרטים אפשר לפנות אלינו דרך עזרה ותמיכה.',
      'Your listing was not approved', coalesce(new.title, '') || ' — for details, contact us through Help & Support.',
      '/my-apartments', 'listing_rejected', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_listing_decision() from public, anon, authenticated;

drop trigger if exists listings_after_decision on public.listings;
create trigger listings_after_decision
  after update of status on public.listings
  for each row execute function public.on_listing_decision();

-- ─── Businesses ───

create or replace function public.on_business_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status is not distinct from old.status or new.owner_id is null or not is_admin() then
    return new;
  end if;
  if old.status = 'pending' and new.status in ('closed', 'suspended', 'draft') then
    perform notify_people(
      business_owner_ids(new.id),
      'העסק שלך לא אושר', new.name || ' — לפרטים אפשר לפנות אלינו דרך עזרה ותמיכה.',
      'Your business was not approved', new.name || ' — for details, contact us through Help & Support.',
      null, 'business_rejected', new.id
    );
  elsif old.status = 'active' and new.status = 'suspended' then
    perform notify_people(
      business_owner_ids(new.id),
      'העסק שלך הושעה', new.name || ' אינו מוצג כרגע באפליקציה. לפרטים: עזרה ותמיכה.',
      'Your business was suspended', new.name || ' is not shown in the app for now. For details: Help & Support.',
      null, 'business_suspended', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_business_decision() from public, anon, authenticated;

drop trigger if exists businesses_after_decision on public.businesses;
create trigger businesses_after_decision
  after update of status on public.businesses
  for each row execute function public.on_business_decision();

-- ─── A business's events ───

create or replace function public.on_business_event_decision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.business_id is null or new.status is not distinct from old.status or not is_admin() then
    return new;
  end if;
  if old.status = 'pending' and new.status in ('cancelled', 'draft') then
    perform notify_people(
      business_owner_ids(new.business_id),
      'האירוע שלך לא אושר', new.title || ' — לפרטים אפשר לפנות אלינו דרך עזרה ותמיכה.',
      'Your event was not approved', new.title || ' — for details, contact us through Help & Support.',
      '/business-events', 'event_rejected', new.id
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_business_event_decision() from public, anon, authenticated;

drop trigger if exists events_after_decision on public.events;
create trigger events_after_decision
  after update of status on public.events
  for each row execute function public.on_business_event_decision();
