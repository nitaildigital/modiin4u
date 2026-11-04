-- ============================================================
-- Modiin4u — Migration 00086
-- Three banners on every article page: the start, the middle and the end
--
-- The client (4 Nov): banners at the beginning, the middle and the end of
-- the article page, which he replaces from the panel whenever he likes, and
-- right on a phone. Each is a slot like the others (00008, 00028): he books
-- a campaign in it under Campaigns, and a slot with nothing booked draws
-- nothing. The end is the slot the page already drew under the story,
-- ARTICLE_INLINE, renamed for where it is.
--
-- A campaign has had a mobile image since 00008, but active_banners() gave
-- the site only the desktop one. It now hands out both, so a phone can be
-- given a banner made for its shape. Its columns change, so it is dropped
-- and made again; the public key keeps its right to call it.
-- ============================================================

insert into ad_placements (code, label, description, max_banners, sort_order)
values
  ('ARTICLE_TOP', 'ראש הכתבה', 'Above the story on every article page', 1, 3),
  ('ARTICLE_MIDDLE', 'אמצע הכתבה', 'Halfway through the story on every article page', 1, 3)
on conflict (code) do nothing;

update ad_placements
   set label = 'סוף הכתבה',
       description = 'Below the story on every article page'
 where code = 'ARTICLE_INLINE';

drop function if exists public.active_banners(text);

create function public.active_banners(p_code text)
returns table (id uuid, image_url text, destination_url text, name text, mobile_image_url text)
language sql
stable
security definer
set search_path = public
as $$
  select c.id, c.desktop_image, c.destination_url, c.name, c.mobile_image
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
