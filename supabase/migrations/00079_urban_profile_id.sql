-- ============================================================
-- Modiin4u — Migration 00079
-- urban_profile() also gives the profile's id and its visibility
--
-- A resident who reports someone's Urban Profile reports the account
-- (reports, type 'user'), which needs its id; profiles themselves are
-- private, so the function that already returns the visible profile gives
-- it. The visibility is for the owner's own view of their link.
--
-- Needs 00077. Safe to run more than once.
-- ============================================================

create or replace function public.urban_profile(p_username text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'id', p.id,
    'username', p.username,
    'visibility', p.profile_visibility,
    'name', p.full_name,
    'avatar_url', p.avatar_url,
    'neighborhood', n.name,
    'neighborhood_en', n.name_en,
    'bio', p.bio,
    'interests', to_jsonb(p.interests),
    'member_since', p.created_at,
    'is_owner', p.id = auth.uid(),
    'places', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', b.id, 'slug', b.slug, 'name', b.name, 'name_en', b.name_en,
        'image', coalesce(b.cover_url, b.logo_url), 'kind', b.kind,
        'top_pick', pp.top_pick) order by pp.position)
      from profile_places pp join businesses b on b.id = pp.business_id
      where pp.profile_id = p.id and b.status = 'active'), '[]'::jsonb)
  )
  from profiles p
  left join neighborhoods n on n.id = p.neighborhood_id
  where p.username = lower(p_username)
    and not coalesce(p.is_banned, false)
    and (p.id = auth.uid()
         or (p.profile_visibility = 'residents' and auth.uid() is not null));
$$;

revoke all on function public.urban_profile(text) from public;
grant execute on function public.urban_profile(text) to anon, authenticated;
