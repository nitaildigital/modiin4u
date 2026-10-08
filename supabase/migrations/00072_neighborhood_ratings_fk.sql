-- Neighbourhood ratings: the rater references the account, not the profile.
--
-- 00071 made neighborhood_ratings with keys to both profiles and
-- neighborhoods. The API reads such a table as a second link between the
-- two, beside profiles.neighborhood_id, and an embed that names neither —
-- the app's own profile read, `profiles?select=*,neighborhoods(name)` —
-- was refused as ambiguous (PGRST201). Every signed-in person then loaded
-- as a bare session: no name, no neighbourhood, and administrators and
-- business owners without their role.
--
-- Pointing profile_id at auth.users keeps what the key was for — a deleted
-- account takes its ratings with it — while auth is outside the API, so
-- profiles and neighborhoods have one link again. Installed apps still send
-- the old embed, which is why this is fixed here and not only in the app.

alter table public.neighborhood_ratings
  drop constraint if exists neighborhood_ratings_profile_id_fkey;

alter table public.neighborhood_ratings
  add constraint neighborhood_ratings_profile_id_fkey
  foreign key (profile_id) references auth.users(id) on delete cascade;

notify pgrst, 'reload schema';
