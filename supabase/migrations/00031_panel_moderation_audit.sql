-- Home-block drafts, moderation, and the audit trail
--
-- 1. Home-block drafts were public. 00013 let everyone read a block only
--    once it was active and published, and 00014's blanket "public read"
--    loop then added `home_blocks_read_all USING (true)` beside it. Policies
--    are OR-ed, so the looser one won and anyone with the public key could
--    read every draft and every switched-off block. Dropping it leaves the
--    published-only read from 00013 and the two admin policies (00013's
--    `home_blocks_admin`, 00014's `home_blocks_write_admin`), which still let
--    the panel read and write everything.
--
-- 2. Moderators could not moderate. `comments_write_own` and `reports_own`
--    let an admin reach a row (USING … OR is_admin()) but their WITH CHECK is
--    only `author_id = auth.uid()` / `reporter_id = auth.uid()`, so any update
--    an admin made to someone else's comment or report was refused. These add
--    an admin-only update policy beside them.
--
-- 3. The audit log's actor is stamped by the database. The panel writes a
--    row per change; `admin_id` points at `admin_users`, not at the signed-in
--    user, and a client could put anything there. The trigger fills it from
--    auth.uid() whatever the client sent. Inserting is already allowed to
--    admins by 00014's `audit_logs_admin_only`.

-- ─── 1. home_blocks: drafts stay private ───
drop policy if exists home_blocks_read_all on home_blocks;

-- The published-only read, restated in case an environment lacks it.
drop policy if exists "home_blocks_select_public" on home_blocks;
create policy "home_blocks_select_public"
  on home_blocks for select
  using (is_active and published);

drop policy if exists home_blocks_write_admin on home_blocks;
create policy home_blocks_write_admin
  on home_blocks for all
  using (is_admin()) with check (is_admin());

-- ─── 2. comments and reports: admins may update any row ───
drop policy if exists comments_admin_update on comments;
create policy comments_admin_update
  on comments for update
  using (is_admin()) with check (is_admin());

drop policy if exists reports_admin_update on reports;
create policy reports_admin_update
  on reports for update
  using (is_admin()) with check (is_admin());

-- ─── 3. audit_logs: the actor is whoever is signed in ───
create or replace function audit_logs_stamp_actor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.admin_id := (
    select id from admin_users where profile_id = auth.uid() limit 1
  );
  new.created_at := now();
  return new;
end;
$$;

drop trigger if exists audit_logs_stamp_actor on audit_logs;
create trigger audit_logs_stamp_actor
  before insert on audit_logs
  for each row execute function audit_logs_stamp_actor();
