-- ============================================================
-- Modiin4u — Migration 00047
-- A category can stay out of the menus
--
-- The old site's 63 business categories come back as categories of their
-- own (tool/import_old_categories.py, 5 Oct), each at its old address for
-- the sake of search engines. Four of them were lists rather than
-- categories — "עסקים באתר", two wartime lists, "פתוח בשבת" — with no
-- natural place in the tree. As top-level categories they would have become
-- tiles on the Businesses screen and cards in the directory.
--
-- `in_menus` off keeps a category's page and address, and its place in
-- search engines, but leaves it out of the category lists. It is not
-- `is_active`: that is how the panel removes a category, and a removed one
-- has no page at all. The panel's category form has the switch.
--
-- Additive; every existing category stays in the menus. Safe to run more
-- than once.
-- ============================================================

alter table public.categories
  add column if not exists in_menus boolean not null default true;

comment on column public.categories.in_menus is
  'Off: the category keeps its page and address but is left out of category lists and menus.';
