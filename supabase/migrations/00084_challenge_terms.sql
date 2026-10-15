-- ============================================================
-- Modiin4u — Migration 00084
-- A step competition's own terms (the client's points 13–14, 5 Oct)
--
-- The prize and the winner came with 00058; the competition's rules were
-- left for "an information page per competition". They live on the
-- challenge itself, written in the panel beside the prize, in Hebrew and
-- (optionally) English, in the same plain text the information pages use
-- (**bold**, headings, lists). The app and the site show them under the
-- competition's banner while it runs; empty, nothing is shown.
--
-- `challenges` is read by everyone already (a running competition is
-- public) and written by the panel only; the new columns follow.
-- Safe to run more than once.
-- ============================================================

alter table public.challenges
  add column if not exists terms    text,
  add column if not exists terms_en text;

comment on column public.challenges.terms    is 'The competition''s terms, as the panel writes them (Hebrew).';
comment on column public.challenges.terms_en is 'The competition''s terms in English; empty falls back to Hebrew.';
