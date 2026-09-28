-- Banners the public site may show
--
-- The web design carries paid banners in several places — beside the home
-- page map, down the side of the news page, inside the navbar's Businesses
-- and Professionals menus — and the client's current site already sells them:
-- its mega menus fade through the photographs of businesses that paid to be
-- there. The schema has had the tables for this since 00008: `ad_placements`
-- names the slots and `campaigns` holds the creative, the link and the dates.
--
-- But `campaigns` is admin-only (00013), and rightly: a row carries the
-- impressions, the clicks, the salesperson and the agreement behind it. A
-- policy is per row, not per column, so opening it to the public key would
-- hand all of that out. So the public gets a function instead, which answers
-- with the four columns a page needs to draw a banner and nothing else, and
-- only for campaigns that are running now.
--
-- Nothing is shown unless an administrator has made a campaign active for
-- that slot. A slot with no campaign draws nothing — the page does not keep a
-- grey box open for an advertiser who has not arrived.

create or replace function public.active_banners(p_code text)
returns table (id uuid, image_url text, destination_url text, name text)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.desktop_image, c.destination_url, c.name
  from campaigns c
  join ad_placements p on p.id = c.placement_id
  where p.code = p_code
    and p.is_active
    and c.status = 'active'
    and c.desktop_image is not null
    and (c.start_at is null or c.start_at <= now())
    and (c.end_at is null or c.end_at > now())
  order by c.priority desc, c.created_at;
$$;

revoke all on function public.active_banners(text) from public;
grant execute on function public.active_banners(text) to anon, authenticated;

-- The slots the web design draws that 00008 did not name.
insert into ad_placements (code, label, description, max_banners, sort_order)
values
  ('MENU_BUSINESSES', 'תפריט עסקים', 'Photographs fading inside the navbar''s Businesses menu', 6, 20),
  ('MENU_PROFESSIONALS', 'תפריט בעלי מקצוע', 'Photographs fading inside the navbar''s Professionals menu', 6, 21),
  ('HOME_MAP_SIDE', 'ליד המפה בעמוד הבית', 'Three banners beside the home page map: one wide, two square', 3, 22),
  ('NEWS_SIDEBAR', 'צד עמוד החדשות', 'The column of banners beside the news categories', 4, 23),
  ('DEALS_TOP', 'ראש עמוד המבצעים', 'Three banners across the top of the deals page', 3, 24)
on conflict (code) do nothing;
