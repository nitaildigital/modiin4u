-- ============================================================
-- Modiin4u — Migration 00020
-- The profile fields the edit screen collected but threw away
--
-- "Edit Profile" shows family status, whether you have a pet, and a date of
-- birth. None of the three had a column, and `updateProfile` sent only name,
-- phone and neighbourhood — so anything typed there was discarded the moment
-- the screen closed.
--
-- Worse, they were not empty: they opened on 'Married', 'Yes' and
-- '12 May 1990' for everybody, so the screen told each person a birthday and
-- a marital status that were made up.
--
-- Safe to run more than once.
-- ============================================================

alter table public.profiles
  add column if not exists family_status text,
  add column if not exists has_pet       boolean,
  add column if not exists date_of_birth date;

-- Left null when unanswered, so "not told us" stays distinct from an answer.
comment on column public.profiles.family_status is
  'single | married | divorced | widowed. Null until the person chooses.';
comment on column public.profiles.has_pet is
  'Null until answered, so unknown is not the same as no.';

-- Stored as a key rather than a display string, so the value survives a
-- change of language.
alter table public.profiles
  drop constraint if exists profiles_family_status_check;

alter table public.profiles
  add constraint profiles_family_status_check
  check (family_status is null
         or family_status in ('single', 'married', 'divorced', 'widowed'));
