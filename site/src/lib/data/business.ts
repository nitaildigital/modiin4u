import { cache } from 'react';
import { db } from '../supabase';
import { isUuid } from '../params';
import type { Lang } from '../i18n';

/** One business page's row, the columns the page and its metadata read
 *  (business_repository.dart fetchById, Business.fromJson). */
export type Business = {
  id: string; slug: string | null; kind: string;
  name: string; name_en: string | null;
  short_description: string | null; full_description: string | null;
  phone: string | null; website: string | null; whatsapp: string | null; instagram: string | null;
  address: string | null; latitude: number | null; longitude: number | null;
  logo_url: string | null; cover_url: string | null; og_image_url: string | null;
  rating: number | null; review_count: number | null; kosher_level: string | null;
  has_delivery: boolean | null; has_outdoor: boolean | null; is_accessible: boolean | null;
  has_parking: boolean | null; pet_friendly: boolean | null; open_on_shabbat: boolean | null;
  hours_text: string | null; google_place_id: string | null;
  meta_title: string | null; meta_description: string | null; meta_keywords: string | null;
  og_title: string | null; og_description: string | null; noindex: boolean | null;
  updated_at: string | null; neighborhood_id: string | null;
  /** The account that runs the business, if any — who reads its Messages. */
  owner_id: string | null;
  neighborhoods: { id: string; name: string; name_en: string | null; slug: string | null } | null;
  business_hours: { day_of_week: number | null; open_time: string | null; close_time: string | null }[];
};

const FIELDS = 'id,slug,kind,name,name_en,short_description,full_description,phone,website,whatsapp,instagram,'
  + 'address,latitude,longitude,logo_url,cover_url,og_image_url,rating,review_count,kosher_level,'
  + 'has_delivery,has_outdoor,is_accessible,has_parking,pet_friendly,open_on_shabbat,hours_text,google_place_id,'
  + 'meta_title,meta_description,meta_keywords,og_title,og_description,noindex,updated_at,neighborhood_id,owner_id,'
  + 'neighborhoods!businesses_neighborhood_id_fkey(id,name,name_en,slug),business_hours(day_of_week,open_time,close_time)';

/** One active business or park, by its slug or by its id — the app takes
 *  both: its own cards link by id, the old site's articles by slug. */
export const businessBySlugOrId = cache(async (key: string): Promise<Business | null> => {
  const k = key.trim().replace(/\/+$/, '');
  if (!k) return null;
  const { data, error } = await db.from('businesses').select(FIELDS)
    .eq(isUuid(k) ? 'id' : 'slug', k).eq('status', 'active').limit(1).maybeSingle();
  // A failed read is an error page, not "no such business": a 404 would tell
  // Google the page is gone.
  if (error) throw new Error(`business ${k}: ${error.message}`);
  return data as Business | null;
});

/** The name in the reader's language (localName): English where the panel
 *  has one, Hebrew otherwise. */
export function localName(he: string, en: string | null | undefined, lang: Lang): string {
  const e = en?.trim();
  return lang === 'en' && e ? e : he;
}

/** The photographs WordPress had for it, in their order (businessGalleryProvider). */
export const businessGallery = cache(async (id: string): Promise<string[]> => {
  const { data } = await db.from('entity_media').select('sort_order,media(url)')
    .eq('entity_type', 'business').eq('entity_id', id).eq('role', 'gallery').order('sort_order', { ascending: true });
  return ((data ?? []) as unknown as { media: { url: string | null } | null }[])
    .map((r) => r.media?.url).filter((u): u is string => typeof u === 'string' && !!u);
});

export type Review = {
  id: string; author_name: string | null; rating: number; body: string | null; created_at: string | null;
  /** The author's photo, only when they agreed to show it (00076). */
  author_avatar_url: string | null;
  /** Photographs attached to the review (00076). */
  photos: string[] | null;
  profiles: { full_name: string | null } | null;
};

/** The approved reviews, newest first. The website has no accounts, so no
 *  one's own pending review is ever among them (businessReviewsProvider). */
export const businessReviews = cache(async (id: string): Promise<Review[]> => {
  const { data } = await db.from('reviews')
    .select('id,author_name,author_avatar_url,photos,rating,body,created_at,profiles!reviews_author_id_fkey(full_name)')
    .eq('business_id', id).eq('status', 'approved').order('created_at', { ascending: false });
  return (data ?? []) as unknown as Review[];
});

export type Reply = { id: string; entity_id: string; author_name: string | null; body: string | null; created_at: string | null };

/** Residents' approved replies under these reviews, oldest first, by review
 *  id (reviewRepliesProvider; the web page shows the approved ones only). */
export async function reviewReplies(reviewIds: string[]): Promise<Record<string, Reply[]>> {
  if (!reviewIds.length) return {};
  const { data } = await db.from('comments').select('id,entity_id,author_name,body,created_at')
    .eq('entity_type', 'review').in('entity_id', reviewIds).eq('status', 'approved')
    .order('created_at', { ascending: true });
  const out: Record<string, Reply[]> = {};
  for (const r of (data ?? []) as Reply[]) (out[r.entity_id] ??= []).push(r);
  return out;
}

export type MenuItem = { id: string; section: string | null; name: string; description: string | null; price_agorot: number | null; is_available: boolean | null };

/** The menu the panel keeps, in its order; empty for most businesses. */
export const businessMenu = cache(async (id: string): Promise<MenuItem[]> => {
  const { data } = await db.from('business_menu_items').select('id,section,name,description,price_agorot,is_available')
    .eq('business_id', id).order('sort_order', { ascending: true });
  return (data ?? []) as MenuItem[];
});

type Cat = { id: string; slug: string; name: string; name_en: string | null; parent_id: string | null; in_menus: boolean | null };
export type Kind = { category: Cat; rootSlug: string };

const activeCategories = cache(async (): Promise<Cat[]> => {
  const { data } = await db.from('categories').select('id,slug,name,name_en,parent_id,in_menus')
    .eq('scope', 'business').eq('is_active', true).order('sort_order', { ascending: true });
  return (data ?? []) as Cat[];
});

const categoryLinks = cache(async (): Promise<{ entity_id: string; category_id: string }[]> => {
  const { data } = await db.from('entity_categories').select('entity_id,category_id').eq('entity_type', 'business');
  return (data ?? []) as { entity_id: string; category_id: string }[];
});

/** The category each business is named by, keyed by business id, and the
 *  slug at the top of its branch (businessPrimaryCategoryProvider): the most
 *  specific one in the menus — a pizzeria is "פיצה", not "מסעדות". */
export const primaryKinds = cache(async (): Promise<Record<string, Kind>> => {
  const [cats, links] = await Promise.all([activeCategories(), categoryLinks()]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const chosen: Record<string, Cat> = {};
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (!c || c.in_menus === false) continue;
    const have = chosen[l.entity_id];
    if (!have || (have.parent_id == null && c.parent_id != null)) chosen[l.entity_id] = c;
  }
  const rootOf = (c: Cat) => {
    let at = c;
    for (let d = 0; d < 5 && at.parent_id; d++) {
      const p = byId.get(at.parent_id);
      if (!p) break;
      at = p;
    }
    return at.slug;
  };
  return Object.fromEntries(Object.entries(chosen).map(([id, c]) => [id, { category: c, rootSlug: rootOf(c) }]));
});

export type BusinessCard = {
  id: string; slug: string | null; name: string; name_en: string | null;
  short_description: string | null; full_description: string | null; address: string | null;
  cover_url: string | null; og_image_url: string | null; logo_url: string | null;
  rating: number | null; review_count: number | null; neighborhood_id: string | null;
  neighborhoods: { name: string; name_en: string | null } | null;
};

/** Every active business (not parks), promoted first, then newest
 *  (businessesProvider → fetchAll). */
const activeBusinesses = cache(async (): Promise<BusinessCard[]> => {
  const { data } = await db.from('businesses')
    .select('id,slug,name,name_en,short_description,full_description,address,cover_url,og_image_url,logo_url,rating,review_count,neighborhood_id,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)')
    .eq('status', 'active').eq('kind', 'business')
    .order('promoted_until', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false });
  return (data ?? []) as unknown as BusinessCard[];
});

/** The row under the page (web_business_detail_screen _buildMoreBusinesses):
 *  others in the same neighbourhood, else others of the same kind; those
 *  with a photograph first; five at most. */
export async function moreBusinesses(b: Business): Promise<{ cards: BusinessCard[]; inNeighborhood: boolean; kinds: Record<string, Kind> }> {
  const [all, kinds] = await Promise.all([activeBusinesses(), primaryKinds()]);
  const others = all.filter((x) => x.id !== b.id);
  let picked = b.neighborhood_id ? others.filter((x) => x.neighborhood_id === b.neighborhood_id) : [];
  const inNeighborhood = picked.length > 0;
  const mine = kinds[b.id];
  if (!picked.length && mine) picked = others.filter((x) => kinds[x.id]?.category.id === mine.category.id);
  const photo = (x: BusinessCard) => !!(x.cover_url || x.og_image_url);
  picked = [...picked.filter(photo), ...picked.filter((x) => !photo(x))].slice(0, 5);
  return { cards: picked, inNeighborhood, kinds };
}
