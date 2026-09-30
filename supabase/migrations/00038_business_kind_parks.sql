-- Parks, as the client asked: "set it up like businesses — but without a
-- phone number, menu, or website. Do keep reviews, photos, description."
--
-- A park is a row in `businesses`, so it has the business page, the photo
-- gallery (`entity_media`), resident reviews, the map point and the panel's
-- editor with no second copy of any of them. `kind` tells the two apart:
-- the business directory (the Businesses tab, Home's rows, the neighbourhood
-- counts) reads `kind = 'business'`, and the Municipal page's Parks tile
-- reads `kind = 'park'`.
--
-- Every existing row is a business, which the default says; nothing is
-- rewritten. A category would not have done: parks are not a trade, and a
-- category shows up in the directory's menus and grid.

alter table businesses
  add column if not exists kind text not null default 'business';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'businesses_kind_check'
  ) then
    alter table businesses
      add constraint businesses_kind_check check (kind in ('business', 'park'));
  end if;
end $$;

create index if not exists businesses_kind_status_idx
  on businesses (kind, status);
