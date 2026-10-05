-- ============================================================
-- Modiin4u — Migration 00055
-- A resident can mark their own live listing sold or rented
--
-- My Apartments had no actions at all: once a listing was sent, its owner
-- could not take it down, change it or say the flat had gone, and had to ask
-- the office. Taking it down (back to a draft), changing it (a draft again,
-- then sent for review) and deleting it were already allowed by the rules;
-- the column guard (00033) refused "sold" and "rented", which only the panel
-- could set.
--
-- The guard now lets the owner move a live listing to sold or rented, and
-- nothing else with it: featuring, the publishing dates, the agency and the
-- owner stay the panel's. Sold and rented listings leave the site, as before.
--
-- Safe to run more than once.
-- ============================================================

create or replace function listings_guard_columns()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not is_resident_write() then
    return new;
  end if;

  if new.status not in ('draft', 'pending')
     and not (
       tg_op = 'UPDATE'
       and old.status = 'active'
       and new.status in ('sold', 'rented')
     ) then
    raise exception 'a listing can only be saved as a draft or sent for review'
      using errcode = '42501';
  end if;

  if tg_op = 'INSERT' then
    new.is_featured := false;
    new.view_count := 0;
    new.published_at := null;
    new.expires_at := null;
    new.agent_id := null;
    return new;
  end if;

  if new.is_featured is distinct from old.is_featured
     or new.view_count is distinct from old.view_count
     or new.published_at is distinct from old.published_at
     or new.expires_at is distinct from old.expires_at
     or new.agent_id is distinct from old.agent_id
     or new.owner_id is distinct from old.owner_id then
    raise exception 'featuring, publishing dates, the agency and the owner of a listing are set by the management panel'
      using errcode = '42501';
  end if;
  return new;
end;
$$;
