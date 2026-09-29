-- Parking lots, for the map's Parkings layer
--
-- The phone map's Figma frame has four layers — Businesses, Events, Parkings,
-- Real Estate — and the app shipped with three, because there was nothing to
-- put under the fourth: the old layer drew four car parks written into the
-- source. The client asked for every lot in the city with its location,
-- managed from the panel (handover, point 4), so this is the table he fills.
--
-- Only what he can know and keep true: a name, where it is, and a line of
-- his own about it (hours, price, residents' permit). No capacity or live
-- occupancy — there is no feed for either, and a number nobody updates is
-- worse than none.
--
-- Hiding a lot sets is_active = false rather than deleting it; the client
-- asked for a trash, not permanent removal.

create table if not exists parking_lots (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  name_en     text,
  address     text,
  notes       text,
  latitude    double precision not null check (latitude between -90 and 90),
  longitude   double precision not null check (longitude between -180 and 180),
  image_url   text,
  is_active   boolean not null default true,
  sort_order  int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

drop trigger if exists parking_lots_updated_at on parking_lots;
create trigger parking_lots_updated_at
  before update on parking_lots
  for each row execute function update_updated_at();

alter table parking_lots enable row level security;

-- Anyone may see a lot that is shown; an administrator sees hidden ones too.
drop policy if exists parking_lots_read on parking_lots;
create policy parking_lots_read on parking_lots
  for select using (is_active or is_admin());

drop policy if exists parking_lots_admin_write on parking_lots;
create policy parking_lots_admin_write on parking_lots
  for all using (is_admin()) with check (is_admin());
