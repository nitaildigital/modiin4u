-- ============================================================
-- Modiin4u — Migration 00021
-- Let a resident upload the photographs for their own listing
--
-- Migration 00017 gave the `media` bucket an insert policy of `is_admin()`,
-- which is right for business logos and article pictures — those are the
-- client's own content. But a resident posting an apartment has to attach
-- photographs of it, and that upload was refused.
--
-- Rather than opening the bucket, this allows a signed-in account to write
-- only under `listings/`, and only to a folder named after its own user id:
--
--     listings/<auth.uid()>/<anything>
--
-- So one resident cannot overwrite another's photographs, and nothing outside
-- `listings/` is reachable. Administrators keep the wider access 00017 gave
-- them.
--
-- Safe to run more than once.
-- ============================================================

-- `storage.foldername(name)` splits the object path, so [1] is the first
-- segment and [2] the second. Comparing the second against the caller's id is
-- what scopes a person to their own folder.

drop policy if exists "media_listing_owner_insert" on storage.objects;
create policy "media_listing_owner_insert"
  on storage.objects for insert
  with check (
    bucket_id = 'media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = 'listings'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "media_listing_owner_update" on storage.objects;
create policy "media_listing_owner_update"
  on storage.objects for update
  using (
    bucket_id = 'media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = 'listings'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

-- Removing a photograph from a listing being edited. Same fence.
drop policy if exists "media_listing_owner_delete" on storage.objects;
create policy "media_listing_owner_delete"
  on storage.objects for delete
  using (
    bucket_id = 'media'
    and auth.uid() is not null
    and (storage.foldername(name))[1] = 'listings'
    and (storage.foldername(name))[2] = auth.uid()::text
  );
