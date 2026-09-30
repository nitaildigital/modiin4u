-- Municipal places: the Municipal page's service tiles
--
-- The client listed what each tile should hold: "Public Institutions — all
-- public institutions in Modi'in, including synagogues. Health — all clinics.
-- Education — all schools and kindergartens. Transportation — bus and train
-- stations, just basic locations. Emergency — emergency numbers: the 106
-- hotline, police, MADA."
--
-- One table for all of them, a row a place, filed by `category`; the tiles
-- read their categories (Institutions: institution + synagogue; Education:
-- school + kindergarten; Transportation: train_station + bus_stop). The
-- client manages the rows in the panel (מוסדות עירוניים). Rows brought in
-- from an outside source carry it in `source` / `source_ref`, so an import
-- can be run again, and undone, without touching what he typed himself
-- (`source = 'panel'`). A location is optional: an emergency number has
-- none. Hiding a row takes it off the site and keeps it.

create table if not exists municipal_places (
  id          uuid primary key default gen_random_uuid(),
  category    text not null check (category in (
                'institution', 'synagogue', 'health', 'school',
                'kindergarten', 'train_station', 'bus_stop', 'emergency')),
  name        text not null,
  name_en     text,
  address     text,
  phone       text,
  notes       text,
  latitude    double precision check (latitude between -90 and 90),
  longitude   double precision check (longitude between -180 and 180),
  is_active   boolean not null default true,
  sort_order  int not null default 0,
  source      text not null default 'panel',
  source_ref  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (source, source_ref)
);

create index if not exists municipal_places_category_idx
  on municipal_places (category, is_active, sort_order);

drop trigger if exists municipal_places_updated_at on municipal_places;
create trigger municipal_places_updated_at
  before update on municipal_places
  for each row execute function update_updated_at();

alter table municipal_places enable row level security;

drop policy if exists municipal_places_read on municipal_places;
create policy municipal_places_read on municipal_places
  for select using (is_active or is_admin());

drop policy if exists municipal_places_admin_write on municipal_places;
create policy municipal_places_admin_write on municipal_places
  for all using (is_admin()) with check (is_admin());
