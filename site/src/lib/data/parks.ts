import { cache } from 'react';
import { db } from '../supabase';
import type { Lang } from '../i18n';

// The city's parks: rows the client files as a park in the panel
// (`businesses.kind = 'park'`), listed where the Municipal page's Parks tile
// leads (parksProvider in business_providers.dart).

export type Park = {
  id: string; slug: string | null; name: string; name_en: string | null;
  short_description: string | null; full_description: string | null; address: string | null;
  cover_url: string | null; og_image_url: string | null; logo_url: string | null;
  rating: number | null; review_count: number | null; promoted_until: string | null;
  neighborhoods: { name: string | null; name_en: string | null } | null;
};

/** The most specific category a park is filed under, if any — the card's
 *  "kind of place" (businessPrimaryCategoryProvider). */
export type ParkKind = { name: string; name_en: string | null };

export function parkName(p: Pick<Park, 'name' | 'name_en'>, lang: Lang): string {
  const en = p.name_en?.trim();
  return lang === 'en' && en ? en : p.name;
}

/** Active parks with an approved promotion first, then best rated, then by
 *  name in the reader's language. */
export const parks = cache(async (lang: Lang): Promise<Park[]> => {
  const { data } = await db.from('businesses')
    .select('id,slug,name,name_en,short_description,full_description,address,cover_url,og_image_url,logo_url,rating,review_count,promoted_until,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)')
    .eq('status', 'active').eq('kind', 'park')
    .order('promoted_until', { ascending: false, nullsFirst: false })
    .order('created_at', { ascending: false });
  const now = Date.now();
  const promoted = (p: Park) => (p.promoted_until && Date.parse(p.promoted_until) > now ? 1 : 0);
  const rows = (data ?? []) as unknown as Park[];
  return rows.sort((a, b) => {
    const byPromotion = promoted(b) - promoted(a);
    if (byPromotion) return byPromotion;
    const byRating = (b.rating ?? 0) - (a.rating ?? 0);
    if (byRating) return byRating;
    const x = parkName(a, lang), y = parkName(b, lang);
    return x < y ? -1 : x > y ? 1 : 0;
  });
});

type Link = { entity_id: string; categories: { name: string; name_en: string | null; parent_id: string | null; in_menus: boolean | null; is_active: boolean | null; scope: string | null } | null };

/** Each park's category, where the client has filed it under one shown in
 *  the menus — a sub-category before a main one. */
export async function parkKinds(ids: string[]): Promise<Record<string, ParkKind>> {
  if (!ids.length) return {};
  const { data } = await db.from('entity_categories')
    .select('entity_id,categories(name,name_en,parent_id,in_menus,is_active,scope)')
    .eq('entity_type', 'business').in('entity_id', ids);
  const chosen: Record<string, Link['categories']> = {};
  for (const l of (data ?? []) as unknown as Link[]) {
    const c = l.categories;
    if (!c || c.scope !== 'business' || c.is_active === false || c.in_menus === false) continue;
    const have = chosen[l.entity_id];
    if (!have || (have.parent_id == null && c.parent_id != null)) chosen[l.entity_id] = c;
  }
  return Object.fromEntries(Object.entries(chosen).map(([id, c]) => [id, { name: c!.name, name_en: c!.name_en }]));
}
