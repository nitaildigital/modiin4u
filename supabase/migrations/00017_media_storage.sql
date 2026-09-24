-- ============================================================
-- Modiin4u — Migration 00017
-- The media bucket, and who may put things in it
--
-- The admin panel asked for an image URL typed into a text box, so whoever
-- manages the directory had to host the picture somewhere else first. It
-- uploads now, and this is where the files land.
--
-- It also gives the photography somewhere to live that is ours: 129 of the
-- business pictures still point at modiin4u.co.il, and go with it if that
-- site is ever taken down.
--
-- Safe to run more than once.
-- ============================================================

-- ─── 1. The bucket ───
--
-- Public, so the app reads a plain URL with no signing. 10MB and images only,
-- enforced by storage rather than trusted from the client.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'media',
  'media',
  true,
  10485760,
  array[
    'image/jpeg', 'image/png', 'image/webp', 'image/gif',
    -- A few of the business logos are vector.
    'image/svg+xml'
  ]
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ─── 2. Reading ───
--
-- Anyone, signed in or not. These are business logos and cover photographs
-- shown on pages that need no account.

drop policy if exists "media_public_read" on storage.objects;

create policy "media_public_read"
  on storage.objects for select
  using (bucket_id = 'media');

-- ─── 3. Writing ───
--
-- Administrators only. Without this the panel's upload is refused, because a
-- bucket with row level security and no insert policy rejects everything —
-- and reports it as "Bucket not found", which is worth knowing when it looks
-- like the bucket is missing.
--
-- `is_admin()` is the same function the rest of the policies use, so there is
-- one answer to who an administrator is.

drop policy if exists "media_admin_insert" on storage.objects;
create policy "media_admin_insert"
  on storage.objects for insert
  with check (bucket_id = 'media' and is_admin());

drop policy if exists "media_admin_update" on storage.objects;
create policy "media_admin_update"
  on storage.objects for update
  using (bucket_id = 'media' and is_admin());

drop policy if exists "media_admin_delete" on storage.objects;
create policy "media_admin_delete"
  on storage.objects for delete
  using (bucket_id = 'media' and is_admin());
