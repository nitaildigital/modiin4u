-- ============================================================
-- Modiin4u — Migration 00059
-- Two RSVPs at the same moment are both counted
--
-- `sync_event_rsvp_count` (00024) recounts an event's attendees after each
-- change. Two residents tapping "I'm going" at the same moment each counted
-- before the other's row was committed, and both wrote the same number: found
-- on 6 Oct with two phones side by side — three attendees, a count of two.
--
-- The event's row is now locked first, in a statement of its own, so the
-- second waits for the first to finish and then counts with it included.
-- The counts already off are put right — only on events someone has
-- RSVP'd to: the sample events' invented numbers are the sample-data
-- clean-up's, not this.
--
-- Safe to run more than once.
-- ============================================================

create or replace function public.sync_event_rsvp_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target uuid := coalesce(new.event_id, old.event_id);
begin
  -- Waits for any other RSVP on this event to commit; the count below is a
  -- new statement, so it sees that row.
  perform 1 from public.events where id = target for update;

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

update public.events e
   set rsvp_count = c.n
  from (
    select a.event_id as id, count(*) filter (where a.status <> 'cancelled') as n
      from public.event_attendees a
     group by a.event_id
  ) c
 where c.id = e.id
   and e.rsvp_count is distinct from c.n;
