-- ============================================================
-- Modiin4u — Migration 00085
-- A broker's link on every listing they publish
--
-- The client (26 Oct): a real estate broker adds a link — the office's
-- website, a Facebook page — once, and it appears on every property page
-- they publish, as "Visit broker's website", in the app and on the site.
-- The broker enters it themselves, in Edit Profile; the panel can see and
-- clear it.
--
-- The link is kept on the broker's profile, which only its owner and the
-- panel can read. A visitor reads it through listing_broker_link(), which
-- hands out that one field, and only for a published listing a broker
-- published — never the rest of the profile.
-- ============================================================

alter table public.profiles
  add column if not exists broker_url text;

-- A web address and nothing else: no javascript: or other schemes on a
-- button every visitor can press.
alter table public.profiles
  drop constraint if exists profiles_broker_url_web;
alter table public.profiles
  add constraint profiles_broker_url_web
  check (broker_url is null
         or (broker_url ~* '^https?://[^[:space:]]+$' and length(broker_url) <= 300));

-- The link of the broker who published [p_listing], or null: a listing
-- that is not published, not a broker's, or whose broker is blocked shows
-- no link.
create or replace function public.listing_broker_link(p_listing uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select p.broker_url
    from listings l
    join profiles p on p.id = l.owner_id
   where l.id = p_listing
     and l.status = 'active'
     and l.is_broker
     and p.is_broker
     and not coalesce(p.is_banned, false)
     and p.broker_url is not null;
$$;

-- Since 30 Oct new objects get no API access by default (CLAUDE.md); the
-- column inherits the table's grants, the function is granted here.
revoke all on function public.listing_broker_link(uuid) from public;
grant execute on function public.listing_broker_link(uuid) to anon, authenticated, service_role;
