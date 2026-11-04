-- ============================================================
-- Modiin4u — Migration 00087
-- An article's banners, kept on the article, with defaults for the rest
--
-- The client (4 Nov) asked for three banners on the article page — its
-- start, middle and end — replaced from the panel. 00086 made them three
-- campaign slots, the same on every article and booked under Campaigns. He
-- manages them from Articles instead, article by article:
--
--   1. `articles.banners`: the article's own, as
--      { "top": {"image", "mobile", "link"}, "middle": {…}, "end": {…} } —
--      a slot left out has none of its own. Written in the article's editor;
--      read with the article, by anyone who may read the article.
--   2. `app_settings` key `article_banners`, the same shape: the defaults,
--      set once from Articles, shown in any slot an article leaves empty.
--      The table is readable by everyone and written by the panel already.
--   3. The three campaign slots of 00086 are switched off — no page draws
--      them now, and nothing was booked in them. Switched off, not removed:
--      `is_active` back on brings them back. active_banners() keeps the
--      mobile image it gained there.
--
-- The panel's media check (00034) searches json columns, so a banner's file
-- counts as in use and is never cleared away as unused.
--
-- Editing only the banners sends no notification: the publish trigger
-- (articles_queue_push) watches the status, the title and the pictures, not
-- this column. No new table, so no new grants.
-- ============================================================

alter table public.articles
  add column if not exists banners jsonb;

alter table public.articles
  drop constraint if exists articles_banners_object;
alter table public.articles
  add constraint articles_banners_object
  check (banners is null or jsonb_typeof(banners) = 'object');

update ad_placements
   set is_active = false
 where code in ('ARTICLE_TOP', 'ARTICLE_MIDDLE', 'ARTICLE_INLINE');
