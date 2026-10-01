-- ============================================================
-- Modiin4u — Migration 00044
-- A car park's Google Maps place
--
-- The client (1 Oct): show whatever Google has about each car park — its
-- name there, opening hours, rating, photos, payment methods. Google's
-- terms let an app keep a place's ID indefinitely but not the place's
-- details, so the ID is what is stored here; the app fetches the details
-- from Google when someone opens the car park. Empty for a car park Google
-- does not list. Set by tool/link_parking_google.py, editable in the panel.
--
-- Safe to run more than once.
-- ============================================================

alter table public.parking_lots
  add column if not exists google_place_id text;

create unique index if not exists parking_lots_google_place_id_key
  on public.parking_lots (google_place_id)
  where google_place_id is not null;
