-- ============================================================
-- 00026 — let a resident upload their own profile photograph
-- ============================================================
--
-- The Edit Profile screen has had a photo picker since it was built. It
-- opened the gallery, showed the chosen image in the avatar circle, and then
-- `_save` never sent it anywhere — `updateProfile` was called without an
-- avatar. Someone picked a photograph, watched it appear, tapped Save, and
-- found it gone the next time they opened the screen.
--
-- The `media` bucket already admits an administrator (00017) and a resident
-- writing to their own listing folder (00021). This adds the same scoping for
-- avatars: `avatars/<your id>/…` and nowhere else.
--
-- `storage.foldername(name)` splits the object path, so [1] is the first
-- segment and [2] the second. Comparing the second against the caller's id is
-- what keeps one resident out of another's folder.

drop policy if exists "media_avatar_owner_insert" on storage.objects;
create policy "media_avatar_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

-- Replacing a photograph is an update when the path is reused, and an insert
-- plus a delete when it is not. Both are scoped the same way.
drop policy if exists "media_avatar_owner_update" on storage.objects;
create policy "media_avatar_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "media_avatar_owner_delete" on storage.objects;
create policy "media_avatar_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
