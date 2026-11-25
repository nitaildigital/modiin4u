-- ============================================================
-- 00090 — Telling people about what happens to what they wrote
--
-- The client's "later" from 25 Nov, asked for now: a resident hears when
-- their review or comment is liked or found helpful, and when the business
-- (or the team) answers their review. Replies to reviews and to article
-- comments already tell their writer (00045, 00071).
--
-- All of it goes to 'profiles', the audience behind the app's "Replies to
-- my reviews" switch: one switch for what others do with your writing.
-- Who liked is not said — likes are private (00089).
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. A like or "helpful" on a review or a comment ───
--
-- Once a day per item and kind: a review that collects ten likes in an hour
-- tells its writer once, not ten times, and a like taken back and given
-- again does not tell them twice. Articles and businesses have no writer to
-- tell; a person's own like on their own writing tells nobody.

create or replace function public.on_reaction_notify()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author   uuid;
  v_link     text;
  v_text     text;
  v_place    text;
  v_source   text := 'reaction_' || new.kind;
  v_title    text;
  v_title_en text;
begin
  if new.entity_type = 'review' then
    select r.author_id, '/business/' || r.business_id || '?review=' || r.id,
           coalesce(nullif(trim(r.body), ''), r.title, ''), b.name
      into v_author, v_link, v_text, v_place
      from reviews r join businesses b on b.id = r.business_id
     where r.id = new.entity_id;
  elsif new.entity_type = 'comment' then
    select c.author_id,
           case c.entity_type
             when 'article' then '/article/' || c.entity_id || '?comment=' || c.id
             when 'review' then (select '/business/' || r.business_id || '?review=' || r.id || '&reply=' || c.id
                                   from reviews r where r.id = c.entity_id)
           end,
           c.body
      into v_author, v_link, v_text
      from comments c
     where c.id = new.entity_id;
  else
    return new;
  end if;

  if v_author is null or v_author = new.profile_id then
    return new;
  end if;
  if exists (select 1 from push_campaigns
              where source_type = v_source and source_id = new.entity_id
                and created_at > now() - interval '1 day') then
    return new;
  end if;

  if new.kind = 'helpful' then
    v_title := 'מישהו מצא את הביקורת שלך מועילה';
    v_title_en := 'Someone found your review helpful';
  elsif new.entity_type = 'review' then
    v_title := 'הביקורת שלך קיבלה לייק 👍';
    v_title_en := 'Your review got a like 👍';
  else
    v_title := 'התגובה שלך קיבלה לייק 👍';
    v_title_en := 'Your comment got a like 👍';
  end if;
  v_text := coalesce(v_place || ': ', '') || snippet(v_text, 100);

  insert into push_campaigns (
    title, body, title_en, body_en, deep_link,
    status, scheduled_at, audience_type, audience_filter, source_type, source_id
  ) values (
    v_title, v_text, v_title_en, v_text, v_link,
    'scheduled', now(), 'profiles',
    jsonb_build_object('profile_ids', jsonb_build_array(v_author)),
    v_source, new.entity_id
  );
  return new;
end;
$$;

revoke all on function public.on_reaction_notify() from public, anon, authenticated;

drop trigger if exists reactions_notify on public.reactions;
create trigger reactions_notify
  after insert on public.reactions
  for each row execute function public.on_reaction_notify();

-- ─── 2. The answer to a review ───
--
-- When an answer appears where there was none — from the business's owner
-- (reply_to_review, 00089) or from the panel. Rewording an answer does not
-- tell the writer again; removing one tells nobody.

create or replace function public.on_review_answered()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_place    text;
  v_owner    uuid;
  v_by_owner boolean;
  v_text     text;
begin
  if nullif(trim(coalesce(new.admin_response, '')), '') is null
     or nullif(trim(coalesce(old.admin_response, '')), '') is not null
     or new.status <> 'approved'
     or new.author_id is null
     or new.author_id = new.responded_by then
    return new;
  end if;

  select name, owner_id into v_place, v_owner from businesses where id = new.business_id;
  v_by_owner := v_owner is not null and v_owner = new.responded_by;
  v_text := coalesce(v_place || ': ', '') || snippet(new.admin_response, 100);

  insert into push_campaigns (
    title, body, title_en, body_en, deep_link,
    status, scheduled_at, audience_type, audience_filter, source_type, source_id
  ) values (
    case when v_by_owner then 'בעל העסק הגיב לביקורת שלך' else 'צוות מודיעין בשבילך הגיב לביקורת שלך' end,
    v_text,
    case when v_by_owner then 'The business replied to your review' else 'Modiin4u replied to your review' end,
    v_text,
    '/business/' || new.business_id || '?review=' || new.id,
    'scheduled', now(), 'profiles',
    jsonb_build_object('profile_ids', jsonb_build_array(new.author_id)),
    'review_answer', new.id
  );
  return new;
end;
$$;

revoke all on function public.on_review_answered() from public, anon, authenticated;

drop trigger if exists reviews_answer_notify on public.reviews;
create trigger reviews_answer_notify
  after update of admin_response on public.reviews
  for each row execute function public.on_review_answered();
