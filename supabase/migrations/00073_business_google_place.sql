-- ============================================================
-- Modiin4u — Migration 00073
-- A business's Google Maps place, for its opening hours
--
-- The client (8 Oct): take businesses' hours from Google or from WordPress.
-- WordPress gave 171 businesses their hours (00071, hours_text); for the
-- rest the business page asks Google. As with the car parks (00044),
-- Google's terms let us keep a place's ID but not its details, so only the
-- ID is stored and the hours are fetched when the page opens, with Google's
-- credit. The hours a business or the client enter come first; Google's
-- are shown only where there are none.
--
-- Set by tool/link_business_google.py where the match is certain, and
-- editable in the panel's business editor. Not unique: two of our rows can
-- be the same place.
--
-- Safe to run more than once.
-- ============================================================

alter table public.businesses
  add column if not exists google_place_id text;
