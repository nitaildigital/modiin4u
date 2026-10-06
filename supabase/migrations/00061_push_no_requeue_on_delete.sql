-- ============================================================
-- Modiin4u — Migration 00061
-- A deleted notification is not sent again
--
-- Found on 6 Oct, cleaning up after testing 00060: deleting a notification
-- outright sets its deal's (or article's, event's, business's, listing's,
-- competition's) `push_campaign_id` to null through the foreign key. That is
-- an update of the row, the notification triggers (00045, 00060) saw a live
-- row with no notification, and queued a new one, sent five minutes later.
-- The panel cancels rather than deletes, so it shows on a hard delete — a
-- clean-up, or the trash.
--
-- Both functions now leave a row alone when the notification it pointed to
-- no longer exists. Otherwise unchanged.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.queue_publish_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  kind      text := tg_argv[0];            -- 'article' | 'event' | 'business'
  r         jsonb := to_jsonb(new);
  live      boolean;
  pending   push_campaigns;
  v_title   text;
  v_body    text;
  v_title_en text;
  v_image   text;
  v_link    text;
  v_topic   text;
  v_id      uuid;
begin
  -- A notification deleted outright clears this link, through the foreign
  -- key, and that reaches here as an update: without this the row was
  -- announced again five minutes later.
  if tg_op = 'UPDATE' and new.push_campaign_id is null
     and old.push_campaign_id is not null
     and not exists (select 1 from push_campaigns where id = old.push_campaign_id) then
    return new;
  end if;

  live := case kind
    when 'business' then r ->> 'status' = 'active' and r ->> 'closed_at' is null
    when 'event' then r ->> 'status' = 'published'
      -- An event that is already over is not news.
      and (r ->> 'start_date')::date >= (now() at time zone 'Asia/Jerusalem')::date
    else r ->> 'status' = 'published'
  end;

  if new.push_campaign_id is not null then
    select * into pending from push_campaigns
     where id = new.push_campaign_id and status = 'scheduled';
  end if;

  -- Wording around the item, in each language; the item's own name stays as
  -- it was written, which is Hebrew.
  case kind
    when 'article' then
      v_title := 'כתבה חדשה';  v_title_en := 'New article';
      v_body  := r ->> 'title';
      v_image := coalesce(r ->> 'featured_image', r ->> 'mobile_image');
      v_link  := '/article/' || new.id;
      v_topic := 'news';
    when 'event' then
      v_title := 'אירוע חדש';  v_title_en := 'New event';
      v_body  := (r ->> 'title') || ' · ' || to_char((r ->> 'start_date')::date, 'DD.MM');
      v_image := r ->> 'image_url';
      v_link  := '/event/' || new.id;
      v_topic := 'events';
    else
      v_title := 'עסק חדש בעיר';  v_title_en := 'New in town';
      v_body  := r ->> 'name';
      v_image := r ->> 'cover_url';
      v_link  := '/business/' || new.id;
      v_topic := 'businesses';
  end case;

  if pending.id is not null then
    if not live or not new.notify_on_publish then
      update push_campaigns set status = 'cancelled' where id = pending.id;
      new.push_campaign_id := null;
    else
      update push_campaigns
         set title = v_title, body = v_body, title_en = v_title_en,
             body_en = v_body, image_url = v_image
       where id = pending.id;
    end if;
    return new;
  end if;

  -- A campaign that was sent, or that the panel cancelled by hand, stays
  -- the row's: neither is queued again.
  if new.push_campaign_id is not null or not live or not new.notify_on_publish then
    return new;
  end if;

  insert into push_campaigns (
    title, body, title_en, body_en, image_url, deep_link,
    status, scheduled_at, audience_type, audience_filter,
    source_type, source_id
  ) values (
    v_title, v_body, v_title_en, v_body, v_image, v_link,
    'scheduled', now() + interval '5 minutes', 'topic',
    jsonb_build_object('topic', v_topic),
    kind, new.id
  )
  returning id into v_id;

  new.push_campaign_id := v_id;
  return new;
end;
$$;


create or replace function public.queue_more_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  kind      text := tg_argv[0];            -- 'offer' | 'listing' | 'challenge'
  -- A resident's or owner's write, asked of the request rather than of
  -- `current_user` (is_resident_write), which in a security definer
  -- function is always this function's owner.
  resident  boolean := auth.uid() is not null and not is_admin();
  r         jsonb := to_jsonb(new);
  live      boolean;
  pending   push_campaigns;
  v_title   text;
  v_title_en text;
  v_body    text;
  v_body_en text;
  v_image   text;
  v_link    text;
  v_type    text := 'topic';
  v_filter  jsonb;
  v_when    timestamptz := now() + interval '5 minutes';
  v_id      uuid;
  v_price   text;
begin
  -- A notification deleted outright clears this link, through the foreign
  -- key, and that reaches here as an update: without this the row was
  -- announced again five minutes later.
  if tg_op = 'UPDATE' and new.push_campaign_id is null
     and old.push_campaign_id is not null
     and not exists (select 1 from push_campaigns where id = old.push_campaign_id) then
    return new;
  end if;

  -- The link to a campaign is the database's: a resident writing it could
  -- point their row at someone else's scheduled notification and cancel it.
  if resident then
    new.push_campaign_id := case when tg_op = 'INSERT' then null else old.push_campaign_id end;
  end if;

  -- A business owner's deal is not the panel's to announce.
  if kind = 'offer' and resident then
    if tg_op = 'INSERT' then new.notify_on_publish := false; end if;
    new.push_campaign_id := case when tg_op = 'INSERT' then null else old.push_campaign_id end;
    return new;
  end if;

  live := case kind
    when 'offer' then r ->> 'status' = 'active'
      and (r ->> 'end_at' is null or (r ->> 'end_at')::timestamptz > now())
    when 'listing' then r ->> 'status' = 'active'
    else (r ->> 'is_active')::boolean
      and (r ->> 'end_at')::timestamptz > now()
      and r ->> 'winner_id' is null
  end;

  case kind
    when 'offer' then
      v_title := 'מבצע חדש';  v_title_en := 'New deal';
      v_body := r ->> 'name';  v_body_en := v_body;
      v_image := r ->> 'image_url';
      v_link := '/deal/' || new.id;
      v_filter := jsonb_build_object('topic', 'deals');
    when 'listing' then
      v_price := coalesce(r ->> 'price', r ->> 'price_per_month');
      v_title := case when r ->> 'kind' = 'rent' then 'דירה חדשה להשכרה' else 'דירה חדשה למכירה' end;
      v_title_en := case when r ->> 'kind' = 'rent' then 'New for rent' else 'New for sale' end;
      v_body := (r ->> 'title') || case when v_price is null then '' else ' · ₪' || to_char(v_price::numeric, 'FM999,999,999') end;
      v_body_en := v_body;
      v_image := r ->> 'cover_url';
      v_link := '/listing/' || new.id;
      v_filter := jsonb_build_object('topic', 'realestate');
    else
      v_title := 'תחרות צעדים חדשה';  v_title_en := 'New step competition';
      v_body := (r ->> 'name') || coalesce(' · פרס: ' || nullif(trim(r ->> 'prize'), ''), '');
      v_body_en := (r ->> 'name') || coalesce(' · Prize: ' || nullif(trim(coalesce(r ->> 'prize_en', r ->> 'prize')), ''), '');
      v_image := r ->> 'image_url';
      v_link := '/steps';
      v_type := 'all';
      v_filter := '{}'::jsonb;
      -- Announced when it begins, not when it is typed in.
      v_when := greatest(v_when, (r ->> 'start_at')::timestamptz);
  end case;

  if new.push_campaign_id is not null then
    select * into pending from push_campaigns
     where id = new.push_campaign_id and status = 'scheduled';
  end if;

  if pending.id is not null then
    if not live or not new.notify_on_publish then
      update push_campaigns set status = 'cancelled' where id = pending.id;
      new.push_campaign_id := null;
    else
      update push_campaigns
         set title = v_title, body = v_body, title_en = v_title_en,
             body_en = v_body_en, image_url = v_image, scheduled_at = v_when
       where id = pending.id;
    end if;
    return new;
  end if;

  if new.push_campaign_id is not null or not live or not new.notify_on_publish then
    return new;
  end if;

  insert into push_campaigns (
    title, body, title_en, body_en, image_url, deep_link,
    status, scheduled_at, audience_type, audience_filter,
    source_type, source_id
  ) values (
    v_title, v_body, v_title_en, v_body_en, v_image, v_link,
    'scheduled', v_when, v_type, v_filter, kind, new.id
  )
  returning id into v_id;

  new.push_campaign_id := v_id;
  return new;
end;
$$;

