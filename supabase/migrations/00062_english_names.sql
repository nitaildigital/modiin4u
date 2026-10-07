-- ============================================================
-- Modiin4u — Migration 00062
-- Businesses and categories have an English name
--
-- With English chosen, the website and the app showed English menus and
-- headings around Hebrew names: "Businesses in Modiin" opened on מסעדות and
-- קפה ומאפה, "Find a Professional" on חשמלאי and ישראל לוי (7 Oct). The rows
-- had one name, in Hebrew, as the old site did.
--
-- `name_en` beside `name`, as car parks and municipal places have had since
-- 00030 and 00040. Empty means "show the Hebrew one"; the panel fills it in.
-- Nothing else changes: slugs, addresses and the Hebrew names stay.
--
-- Safe to run more than once.
-- ============================================================

alter table public.categories add column if not exists name_en text;
alter table public.businesses add column if not exists name_en text;
