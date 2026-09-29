-- Which columns a resident may write, not just which rows
--
-- The resident policies on these tables check that the row is the
-- resident's own (`id = auth.uid()`, `author_id = auth.uid()`, …) and stop
-- there. Row level security cannot name columns, so with the public key and
-- a signed-in session anyone could, on their own row:
--   * profiles — lift their own ban, mark themselves verified, give
--     themselves points or a level;
--   * comments — post a comment already approved, or reset its report count;
--   * reports — mark their own report resolved;
--   * daily_steps — record a million steps and top the leaderboard;
--   * challenge_participants / game_sessions — write their own progress,
--     completion or score.
-- And `audit_logs_admin_only` was FOR ALL, so an administrator could edit or
-- delete the trail of what administrators did.
--
-- The guards below are BEFORE triggers. They leave three kinds of writer
-- alone:
--   * administrators (`is_admin()`), who moderate and correct all of this
--     from the panel;
--   * the service role, used by the maintenance scripts;
--   * the database's own SECURITY DEFINER functions — the new-user trigger
--     from 00015, the review-name copy from 00029, the counters from 00024
--     and 00025, and any points or challenge function added later. Those run
--     as the function's owner, so `current_user` is not `authenticated` or
--     `anon` inside them.
-- For everyone else, a new row gets the defaults whatever the client sent,
-- and an update that would change a guarded column is refused with a clear
-- error. An update that sends a guarded column unchanged still goes through,
-- so a profile save that happens to include the whole row is not broken.
--
-- Nothing in the app writes challenge_participants or game_sessions today
-- (the steps screens only read them), so freezing their results costs
-- nothing now; when they are scored it should be by a function, not by the
-- phone.

-- Whether the statement comes from a resident's own session. SECURITY
-- INVOKER on purpose: `current_user` has to be the caller's role.
create or replace function is_resident_write()
returns boolean
language sql
stable
set search_path = public
as $$
  select current_user in ('authenticated', 'anon') and not is_admin();
$$;

-- ─── profiles: bans, verification, points and level ───
create or replace function profiles_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.is_verified := false;
    new.is_banned := false;
    new.ban_reason := null;
    new.points := 0;
    new.level := 1;
    return new;
  end if;

  if new.is_verified is distinct from old.is_verified
     or new.is_banned is distinct from old.is_banned
     or new.ban_reason is distinct from old.ban_reason
     or new.points is distinct from old.points
     or new.level is distinct from old.level then
    raise exception 'is_verified, is_banned, ban_reason, points and level are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_columns on profiles;
create trigger profiles_guard_columns
  before insert or update on profiles
  for each row execute function profiles_guard_columns();

-- ─── comments: moderation state ───
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
    new.status := 'pending';
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

drop trigger if exists comments_guard_columns on comments;
create trigger comments_guard_columns
  before insert or update on comments
  for each row execute function comments_guard_columns();

-- ─── reports: how the report was handled ───
create or replace function reports_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.status := 'open';
    new.resolved_by := null;
    new.resolved_at := null;
    new.resolution := null;
    return new;
  end if;

  if new.status is distinct from old.status
     or new.resolved_by is distinct from old.resolved_by
     or new.resolved_at is distinct from old.resolved_at
     or new.resolution is distinct from old.resolution then
    raise exception 'a report''s status and resolution are set by moderation'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists reports_guard_columns on reports;
create trigger reports_guard_columns
  before insert or update on reports
  for each row execute function reports_guard_columns();

-- ─── daily_steps: a believable day ───
-- The phone reports the count, so the database can only bound it. A hundred
-- thousand steps is well past a marathon; anything above is not a real day.
alter table daily_steps drop constraint if exists daily_steps_steps_range;
alter table daily_steps
  add constraint daily_steps_steps_range check (steps between 0 and 100000);

-- ─── challenge_participants: progress and completion ───
create or replace function challenge_participants_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.progress := 0;
    new.completed := false;
    new.completed_at := null;
    return new;
  end if;

  if new.progress is distinct from old.progress
     or new.completed is distinct from old.completed
     or new.completed_at is distinct from old.completed_at then
    raise exception 'challenge progress is recorded by the system'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists challenge_participants_guard_columns on challenge_participants;
create trigger challenge_participants_guard_columns
  before insert or update on challenge_participants
  for each row execute function challenge_participants_guard_columns();

-- ─── game_sessions: the score ───
create or replace function game_sessions_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.score := null;
    return new;
  end if;

  if new.score is distinct from old.score then
    raise exception 'a game''s score is recorded by the system'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists game_sessions_guard_columns on game_sessions;
create trigger game_sessions_guard_columns
  before insert or update on game_sessions
  for each row execute function game_sessions_guard_columns();

-- ─── audit_logs: written and read, never rewritten ───
-- The panel inserts a row per change (the actor is stamped by 00031's
-- trigger) and the audit and trash screens read them. Nothing edits or
-- deletes them, and nothing should be able to.
drop policy if exists audit_logs_admin_only on audit_logs;

drop policy if exists audit_admin_read on audit_logs;
create policy audit_admin_read
  on audit_logs for select
  using (is_admin());

drop policy if exists audit_logs_admin_insert on audit_logs;
create policy audit_logs_admin_insert
  on audit_logs for insert
  with check (is_admin());
