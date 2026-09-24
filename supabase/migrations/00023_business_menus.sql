-- ============================================================
-- Modiin4u — Migration 00023
-- Menus, so the Menu tab stops inventing one
--
-- The business page has a Menu tab, and it had no table behind it. It showed
-- the same invented menu on all 220 businesses — hummus, lamb chops, beef
-- kebab, Israeli beer — so a pizzeria, a hairdresser and a dentist each
-- offered grilled meats at ₪112.
--
-- This is the table it needed. The tab is hidden for a business with no rows,
-- so a business without a menu shows no menu rather than someone else's.
--
-- Safe to run more than once.
-- ============================================================

create table if not exists public.business_menu_items (
  id          uuid primary key default gen_random_uuid(),
  business_id uuid not null
              references public.businesses(id) on delete cascade,

  -- The heading it sits under — "ראשונות", "עיקריות". Free text rather than
  -- a fixed list, because a bakery and a bar do not group things the same
  -- way. Null groups under no heading at all.
  section     text,

  name        text not null,
  description text,

  -- Agorot, so no rounding: ₪32.50 is 3250. Null for "market price" or a
  -- dish that is only priced in person.
  price_agorot int,

  -- Temporarily off the menu without deleting the row.
  is_available boolean not null default true,

  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- The tab reads one business's items in order, and nothing else does.
create index if not exists idx_menu_items_business
  on public.business_menu_items (business_id, sort_order);

comment on column public.business_menu_items.price_agorot is
  'Agorot. 3250 is ₪32.50. Null when the dish carries no fixed price.';

-- ─── Who may read and write ───
--
-- A menu is public, like the business page it sits on. Only administrators
-- edit it: the businesses in the directory are the client''s own records, and
-- there is no business-owner account type yet.

alter table public.business_menu_items enable row level security;

drop policy if exists menu_items_read on public.business_menu_items;
create policy menu_items_read on public.business_menu_items
  for select using (true);

drop policy if exists menu_items_write_admin on public.business_menu_items;
create policy menu_items_write_admin on public.business_menu_items
  for all using (is_admin()) with check (is_admin());
