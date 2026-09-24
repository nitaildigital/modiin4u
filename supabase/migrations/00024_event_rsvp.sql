-- ============================================================
-- Modiin4u — Migration 00024
-- Keep `events.rsvp_count` honest
--
-- The event page has an "I'm going" button. It was a local `setState` — it
-- changed a word on screen, wrote nothing, and forgot itself the moment you
-- left the page. `event_attendees` has existed since 00006 and was not
-- referenced anywhere in the app.
--
-- Wiring the button up is the app's job. The count beside it is this file's:
-- `rsvp_count` is a plain column with nothing keeping it in step, so a real
-- RSVP would have left the number it sits next to unchanged.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. Recount ───
--
-- SECURITY DEFINER because a resident may write their own attendance row but
-- has no rights over `events`, which is admin-write. Counting here rather
-- than incrementing keeps the column correct even if rows are changed by
-- hand or a trigger is missed.

create or replace function public.sync_event_rsvp_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target uuid := coalesce(new.event_id, old.event_id);
begin
  update public.events e
     set rsvp_count = (
           select count(*)
             from public.event_attendees a
            where a.event_id = target
              -- Someone who cancelled is not attending, but the row is kept
              -- so they are not counted as a fresh RSVP if they return.
              and a.status <> 'cancelled'
         )
   where e.id = target;

  return coalesce(new, old);
end;
$$;

drop trigger if exists on_event_attendee_change on public.event_attendees;

create trigger on_event_attendee_change
  after insert or update or delete on public.event_attendees
  for each row execute function public.sync_event_rsvp_count();

-- ─── 2. Bring the existing rows into line ───
--
-- Every count is 0 today and there are no attendees, so this changes
-- nothing now. It matters on a re-run, and it means the column can be
-- trusted rather than assumed.

update public.events e
   set rsvp_count = c.n
  from (
    select ev.id, count(a.*) filter (where a.status <> 'cancelled') as n
      from public.events ev
      left join public.event_attendees a on a.event_id = ev.id
     group by ev.id
  ) c
 where c.id = e.id
   and e.rsvp_count is distinct from c.n;

-- ─── 3. Reading who else is going ───
--
-- The owner policy from 00014 lets someone see only their own attendance
-- row, which is right. The page also needs to know whether *this* person is
-- going, and that is covered by the same policy — so nothing further is
-- needed here. The public count comes from `events.rsvp_count` above, not
-- from reading other people's rows.
