-- ============================================================
-- Modiin4u — Migration 00076
-- Photos in a review; a profile photo shown only with consent
--
-- The client's TestFlight feedback (8 Oct):
--  * "When I write a review I can also upload images" — a review carries up
--    to four photos. They are part of the review and go through the same
--    moderation: a new review, or a review whose photos change, waits for
--    the panel (00075's rule for edited reviews, extended to photos).
--  * "If the user set a profile pic, show it — of course ask them first,
--    once." Reviews and comments copied the author's photo without asking
--    (00029, 00071). Now a profile photo appears next to what someone wrote
--    only after they said yes: `profiles.show_photo_on_posts` — null until
--    asked, then true or false. The app asks the first time someone with a
--    photo writes a review, and Settings can change it.
--
-- Needs 00029, 00039, 00071, 00075. Safe to run more than once.
-- ============================================================

-- ─── 1. Photos on a review ───

alter table public.reviews
  add column if not exists photos text[] not null default '{}';

alter table public.reviews
  drop constraint if exists reviews_photos_count,
  add constraint reviews_photos_count check (cardinality(photos) <= 4);

-- Uploads go to `reviews/<your id>/` in the public media bucket.
drop policy if exists "media_review_insert" on storage.objects;
create policy "media_review_insert"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'reviews'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

-- Their own files only, which they may also remove (a photo taken out of
-- the form before sending).
drop policy if exists "media_review_delete" on storage.objects;
create policy "media_review_delete"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'media'
    and (storage.foldername(name))[1] = 'reviews'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

-- 00075's guard, with photos: a resident's photos must be their own uploads,
-- and changing them sends the review back to the queue.
create or replace function public.reviews_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  url text;
begin
  if not is_resident_write() then
    return new;
  end if;

  foreach url in array coalesce(new.photos, '{}') loop
    if position('/storage/v1/object/public/media/reviews/' || new.author_id::text || '/' in url) = 0 then
      raise exception 'a review''s photos must be uploaded by its author'
        using errcode = '42501';
    end if;
  end loop;

  if tg_op = 'INSERT' then
    new.status := 'pending';
    new.report_count := 0;
    new.is_verified := false;
    new.admin_response := null;
    new.responded_by := null;
    new.responded_at := null;
    return new;
  end if;

  -- author_name and author_avatar_url are copied from the profile by the
  -- triggers below, which run as their owner and so are not stopped here.
  if new.status is distinct from old.status
     or new.report_count is distinct from old.report_count
     or new.is_verified is distinct from old.is_verified
     or new.admin_response is distinct from old.admin_response
     or new.responded_by is distinct from old.responded_by
     or new.responded_at is distinct from old.responded_at
     or new.business_id is distinct from old.business_id
     or new.author_name is distinct from old.author_name
     or new.author_avatar_url is distinct from old.author_avatar_url then
    raise exception 'a review''s status, answer, business and author are set by moderation'
      using errcode = '42501';
  end if;

  -- New words, a new rating or new photos are a new review: back to the
  -- queue (00075).
  if new.body is distinct from old.body
     or new.title is distinct from old.title
     or new.rating is distinct from old.rating
     or new.photos is distinct from old.photos then
    new.status := 'pending';
  end if;
  return new;
end;
$$;

-- ─── 2. A profile photo next to a review or comment, only with consent ───

alter table public.profiles
  add column if not exists show_photo_on_posts boolean;

-- The photo to show for this person's posts: theirs if they agreed, else none.
create or replace function public.post_photo_of(p profiles)
returns text
language sql
stable
as $$
  select case when p.show_photo_on_posts is true then p.avatar_url end;
$$;

create or replace function public.reviews_fill_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select p.full_name, post_photo_of(p)
    into new.author_name, new.author_avatar_url
  from public.profiles p
  where p.id = new.author_id;
  return new;
end;
$$;

create or replace function public.comments_fill_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  select p.full_name, post_photo_of(p)
    into new.author_name, new.author_avatar_url
  from public.profiles p
  where p.id = new.author_id;
  return new;
end;
$$;

-- Kept in step when the name, the photo or the answer changes.
create or replace function public.profiles_sync_review_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.full_name is distinct from old.full_name
     or new.avatar_url is distinct from old.avatar_url
     or new.show_photo_on_posts is distinct from old.show_photo_on_posts then
    update public.reviews
    set author_name = new.full_name,
        author_avatar_url = post_photo_of(new)
    where author_id = new.id;
  end if;
  return new;
end;
$$;

create or replace function public.profiles_sync_comment_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.full_name is distinct from old.full_name
     or new.avatar_url is distinct from old.avatar_url
     or new.show_photo_on_posts is distinct from old.show_photo_on_posts then
    update public.comments
    set author_name = new.full_name,
        author_avatar_url = post_photo_of(new)
    where author_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_sync_review_author on public.profiles;
create trigger profiles_sync_review_author
  after update of full_name, avatar_url, show_photo_on_posts on public.profiles
  for each row execute function public.profiles_sync_review_author();

-- Photos copied before anyone was asked come off; they come back for anyone
-- who says yes.
update public.reviews r set author_avatar_url = null
  from public.profiles p
  where p.id = r.author_id and r.author_avatar_url is not null and p.show_photo_on_posts is not true;
update public.comments c set author_avatar_url = null
  from public.profiles p
  where p.id = c.author_id and c.author_avatar_url is not null and p.show_photo_on_posts is not true;
