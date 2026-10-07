-- ============================================================
-- Modiin4u — Migration 00065
-- Notifications around moderation: to the writer, to the team, to the reply
--
-- Asked on 7 Oct, testing on the phone:
--   * A resident whose review (or reply, while replies need approval) the
--     panel approved heard nothing; they had to go and look.
--   * The team heard nothing of a new review, reply or listing waiting for
--     approval; the queue was found by opening the panel.
--   * A reply notification opened the business page at its top, and the
--     reply was somewhere down the Reviews tab. The link now names the review
--     and the reply, and the app opens the tab and scrolls to it
--     (business_detail_screen.dart, `?review=…&reply=…`).
--
-- The team is the active administrators who may act on it: super admins, and
-- roles with the panel module — 'moderation' for reviews and replies,
-- 'businesses' for listings (the panel files נדל״ן under it). Their alerts
-- carry no link: the panel is the website's (/admin), not the app's.
--
-- Safe to run more than once.
-- ============================================================

-- Who on the team hears of something waiting in [p_module], less [p_except]
-- (an administrator does not need telling of their own review).
create or replace function public.moderator_profile_ids(p_module text, p_except uuid default null)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_agg(distinct au.profile_id)
    from admin_users au
    join admin_roles ro on ro.id = au.role_id
   where au.is_active
     and au.profile_id is distinct from p_except
     and (ro.name = 'super_admin'
          or exists (
            select 1 from admin_role_permissions p
             where p.role_id = au.role_id
               and p.module = p_module
               and p.action = 'view'
               and p.allowed));
$$;

revoke all on function public.moderator_profile_ids(text, uuid) from public, anon, authenticated;

create or replace function public.snippet(p text, n int default 100)
returns text
language sql
immutable
as $$
  select case when length(coalesce(p, '')) > n
              then left(p, n - 3) || '…' else coalesce(p, '') end;
$$;

-- ─── Replies: the link to the reply, the writer on approval, the team ───
create or replace function public.queue_reply_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_review   reviews;
  v_business text;
  v_text     text;
  v_link     text;
  v_others   jsonb;
  v_team     jsonb;
begin
  if new.entity_type <> 'review' then
    return new;
  end if;
  -- Only a change of state matters; an edit to the text is not news.
  if tg_op = 'UPDATE' and old.status = new.status then
    return new;
  end if;

  select * into v_review from reviews where id = new.entity_id;
  if v_review.id is null then
    return new;
  end if;
  select name into v_business from businesses where id = v_review.business_id;

  v_text := coalesce(nullif(trim(new.author_name), ''), 'תושב/ת') || ': ' ||
    snippet(new.body, 120);
  -- The business page opens on the Reviews tab at this reply.
  v_link := '/business/' || v_review.business_id ||
    '?review=' || v_review.id || '&reply=' || new.id;

  -- Waiting for approval (Settings → replies need approval): the team.
  if new.status = 'pending' then
    v_team := moderator_profile_ids('moderation', new.author_id);
    if v_team is not null then
      insert into push_campaigns (
        title, body, title_en, body_en,
        status, scheduled_at, audience_type, audience_filter, source_type, source_id
      ) values (
        'תגובה חדשה ממתינה לאישור',
        coalesce(v_business || ' · ', '') || v_text || ' — בניהול ← תגובות.',
        'New reply awaiting approval',
        coalesce(v_business || ' · ', '') || v_text || ' — Panel → Comments.',
        'scheduled', now(), 'profiles',
        jsonb_build_object('profile_ids', v_team),
        'moderation', new.id
      );
    end if;
    return new;
  end if;

  if new.status <> 'approved' then
    return new;
  end if;

  -- Approved after waiting: its writer hears so.
  if tg_op = 'UPDATE' and old.status = 'pending' then
    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'התגובה שלך פורסמה', coalesce(v_business, '') || ': ' || snippet(new.body, 100),
      'Your reply is published', coalesce(v_business, '') || ': ' || snippet(new.body, 100),
      v_link,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', jsonb_build_array(new.author_id)),
      'reply', new.id
    );
  end if;

  if v_review.author_id <> new.author_id then
    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'תגובה חדשה לביקורת שלך', v_text, 'New reply to your review', v_text, v_link,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', jsonb_build_array(v_review.author_id)),
      'reply', new.id
    );
  end if;

  select jsonb_agg(distinct c.author_id) into v_others
    from comments c
   where c.entity_type = 'review'
     and c.entity_id = v_review.id
     and c.status = 'approved'
     and c.id <> new.id
     and c.author_id <> new.author_id
     and c.author_id <> v_review.author_id;

  if v_others is not null then
    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'תגובה חדשה בשיחה', v_text, 'New reply in a conversation you''re in', v_text, v_link,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', v_others),
      'reply', new.id
    );
  end if;

  return new;
end;
$$;

-- ─── Reviews: the team when one waits, its writer when it is approved ───
create or replace function public.queue_review_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business text;
  v_team     jsonb;
  v_link     text;
begin
  if tg_op = 'UPDATE' and old.status = new.status then
    return new;
  end if;
  select name into v_business from businesses where id = new.business_id;
  v_link := '/business/' || new.business_id || '?review=' || new.id;

  if new.status = 'pending' then
    v_team := moderator_profile_ids('moderation', new.author_id);
    if v_team is not null then
      insert into push_campaigns (
        title, body, title_en, body_en,
        status, scheduled_at, audience_type, audience_filter, source_type, source_id
      ) values (
        'ביקורת חדשה ממתינה לאישור',
        coalesce(v_business, '') || ' · ' || new.rating || '★ · ' ||
          coalesce(nullif(trim(new.author_name), ''), 'תושב/ת') || ': ' ||
          snippet(new.body, 90) || ' — בניהול ← ביקורות.',
        'New review awaiting approval',
        coalesce(v_business, '') || ' · ' || new.rating || '★ · ' ||
          coalesce(nullif(trim(new.author_name), ''), 'Resident') || ': ' ||
          snippet(new.body, 90) || ' — Panel → Reviews.',
        'scheduled', now(), 'profiles',
        jsonb_build_object('profile_ids', v_team),
        'moderation', new.id
      );
    end if;
  elsif new.status = 'approved' and tg_op = 'UPDATE' and old.status = 'pending'
        and new.author_id is not null then
    insert into push_campaigns (
      title, body, title_en, body_en, deep_link,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'הביקורת שלך פורסמה', coalesce(v_business, '') || ': ' || snippet(new.body, 100),
      'Your review is published', coalesce(v_business, '') || ': ' || snippet(new.body, 100),
      v_link,
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', jsonb_build_array(new.author_id)),
      'review', new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists reviews_queue_push on public.reviews;
create trigger reviews_queue_push
  after insert or update of status on public.reviews
  for each row execute function public.queue_review_push();

-- ─── Listings: the team when a resident sends one for review ───
-- (Its approval already announces it to Real estate followers, 00060.)
create or replace function public.queue_listing_review_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team jsonb;
begin
  if new.status <> 'pending'
     or (tg_op = 'UPDATE' and old.status = 'pending') then
    return new;
  end if;
  v_team := moderator_profile_ids('businesses', new.owner_id);
  if v_team is not null then
    insert into push_campaigns (
      title, body, title_en, body_en,
      status, scheduled_at, audience_type, audience_filter, source_type, source_id
    ) values (
      'מודעת נדל״ן ממתינה לאישור', snippet(new.title, 100) || ' — בניהול ← נדל״ן.',
      'Listing awaiting approval', snippet(new.title, 100) || ' — Panel → Real estate.',
      'scheduled', now(), 'profiles',
      jsonb_build_object('profile_ids', v_team),
      'moderation', new.id
    );
  end if;
  return new;
end;
$$;

drop trigger if exists listings_queue_review_push on public.listings;
create trigger listings_queue_review_push
  after insert or update of status on public.listings
  for each row execute function public.queue_listing_review_push();
