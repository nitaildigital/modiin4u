-- ============================================================
-- Modiin4u — Migration 00063
-- A resident's reply to a review appears at once
--
-- Since 00039 a reply waited, like a review, for someone in the panel to
-- approve it — every "thanks" and "agreed" in every conversation. Replies
-- are a conversation between residents (the client, 30 Sep: "users can reply
-- to other users, like on Facebook"), and one that waits hours for an admin
-- is not one. Now a reply is saved approved, and the panel keeps what it
-- needs after the fact: hiding a reply (Comments), the Report queue (a reply
-- is reportable from the app), and blocking its writer (00054).
--
-- `app_settings.replies_need_approval` = true puts approval back, from the
-- panel's Settings, should the conversations need it. Reviews, and any other
-- kind of comment, still start pending.
--
-- The reply notifications (00045's `queue_reply_push`) already fire for a
-- row inserted approved, so the review's author and the conversation hear of
-- a reply as soon as it is written.
--
-- Safe to run more than once.
-- ============================================================

create or replace function comments_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if new.entity_type = 'review' and not coalesce(
      (select value = 'true'::jsonb from app_settings
        where key = 'replies_need_approval'),
      false) then
      new.status := 'approved';
    else
      new.status := 'pending';
    end if;
    new.report_count := 0;
    return new;
  end if;

  if new.status is distinct from old.status
     or new.report_count is distinct from old.report_count then
    raise exception 'a comment''s status and report count are set by moderation'
      using errcode = '42501';
  end if;
  return new;
end;
$$;
