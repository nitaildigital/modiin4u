-- ============================================================
-- Modiin4u — Migration 00081
-- A business publishes its own events
--
-- The client, TestFlight 11 Oct: "the business needs the ability to upload
-- events — no new design, take the existing design language and the
-- functionality an event needs, and give the business the option to publish
-- events as well."
--
--   * The owner of an active business may create events for it and edit
--     them. Each one waits for the panel (status 'pending'), as a new
--     business does; the panel publishes it from Events → Pending.
--   * Editing a published event sends it back to the queue — what the team
--     approved is what residents see. The owner may withdraw an event
--     ('cancelled'), which the panel can undo; nothing is deleted.
--   * The team hears of an event waiting for it; the owner hears when it is
--     published. Publishing announces it to residents as any event is
--     (events_queue_push).
--   * Featured, sponsored, the counters, the publishing time and the
--     notification switch stay the panel's.
--
-- Needs 00006, 00051, 00069. Safe to run more than once.
-- ============================================================

-- ─── Who may write ───

drop policy if exists events_owner_read on public.events;
create policy events_owner_read on public.events
  for select to authenticated
  using (business_id is not null and public.owns_business(business_id));

drop policy if exists events_owner_insert on public.events;
create policy events_owner_insert on public.events
  for insert to authenticated
  with check (
    business_id is not null
    and public.owns_business(business_id)
    and exists (select 1 from public.businesses b where b.id = business_id and b.status = 'active')
  );

drop policy if exists events_owner_update on public.events;
create policy events_owner_update on public.events
  for update to authenticated
  using (business_id is not null and public.owns_business(business_id))
  with check (business_id is not null and public.owns_business(business_id));

-- ─── What an owner's write may set ───

create or replace function public.events_owner_guard()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- The panel and the service write as before.
  if not is_resident_write() or is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.organizer_id := auth.uid();
    new.is_featured := false;
    new.is_sponsored := false;
    new.view_count := 0;
    new.rsvp_count := 0;
    new.calendar_adds := 0;
    new.share_count := 0;
    new.published_at := null;
    new.push_campaign_id := null;
    new.notify_on_publish := true;
    if coalesce(trim(new.slug), '') = '' then
      new.slug := 'event-' || substr(md5(random()::text || clock_timestamp()::text), 1, 10);
    end if;
    return new;
  end if;

  if new.business_id is distinct from old.business_id
     or new.organizer_id is distinct from old.organizer_id
     or new.is_featured is distinct from old.is_featured
     or new.is_sponsored is distinct from old.is_sponsored
     or new.view_count is distinct from old.view_count
     or new.rsvp_count is distinct from old.rsvp_count
     or new.calendar_adds is distinct from old.calendar_adds
     or new.share_count is distinct from old.share_count
     or new.published_at is distinct from old.published_at
     or new.push_campaign_id is distinct from old.push_campaign_id
     or new.notify_on_publish is distinct from old.notify_on_publish
     or new.slug is distinct from old.slug then
    raise exception 'an event''s business, counters and publishing are set by the panel'
      using errcode = '42501';
  end if;

  -- The owner may withdraw an event; any other status is the panel's.
  if new.status is distinct from old.status and new.status <> 'cancelled' then
    raise exception 'an event is published by the panel' using errcode = '42501';
  end if;

  -- Changed while not being withdrawn: back to the queue.
  if new.status <> 'cancelled'
     and (new.title, new.short_description, new.full_description, new.image_url,
          new.start_date, new.start_time, new.end_date, new.end_time, new.is_all_day,
          new.venue_name, new.address, new.is_online, new.online_url, new.is_free,
          new.price, new.ticket_url)
         is distinct from
         (old.title, old.short_description, old.full_description, old.image_url,
          old.start_date, old.start_time, old.end_date, old.end_time, old.is_all_day,
          old.venue_name, old.address, old.is_online, old.online_url, old.is_free,
          old.price, old.ticket_url) then
    new.status := 'pending';
  end if;
  return new;
end;
$$;

drop trigger if exists events_a_owner_guard on public.events;
create trigger events_a_owner_guard
  before insert or update on public.events
  for each row execute function public.events_owner_guard();

-- ─── Who is told ───

create or replace function public.on_business_event_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business text;
  v_logo     text;
begin
  if new.business_id is null then
    return new;
  end if;
  select name, logo_url into v_business, v_logo from businesses where id = new.business_id;

  -- Waiting for the panel: the team, once each time it enters the queue.
  if new.status = 'pending' and (tg_op = 'INSERT' or old.status is distinct from 'pending') then
    perform notify_people(
      moderator_profile_ids('events', auth.uid()),
      'אירוע חדש ממתין לאישור', new.title || coalesce(' · ' || v_business, '') || ' — בניהול ← אירועים ← ממתין.',
      'New event awaiting approval', new.title || coalesce(' · ' || v_business, '') || ' — Panel → Events → Pending.',
      null, 'event_pending', new.id
    );
  -- Published by the panel: the business.
  elsif tg_op = 'UPDATE' and new.status = 'published' and old.status = 'pending' then
    perform notify_people(
      business_owner_ids(new.business_id),
      'האירוע שלך פורסם', new.title || ' מוצג עכשיו באפליקציה.',
      'Your event is published', new.title || ' is now shown in the app.',
      '/event/' || new.id, 'event_published', new.id, coalesce(new.image_url, v_logo)
    );
  end if;
  return new;
end;
$$;

revoke all on function public.on_business_event_change() from public, anon, authenticated;

drop trigger if exists events_after_business_change on public.events;
create trigger events_after_business_change
  after insert or update of status on public.events
  for each row execute function public.on_business_event_change();
