import { cache } from 'react';
import { db } from '../supabase';
import type { Lang } from '../i18n';
import { plain } from '../seo';

/** A business category as the directory reads it (`categories`, scope
 *  business, switched on in the panel). */
export type BizCategory = {
  id: string; slug: string; name: string; name_en: string | null; parent_id: string | null;
  sort_order: number | null; in_menus: boolean | null; image_url: string | null;
  meta_title: string | null; meta_description: string | null; description: string | null;
};

/** A business row with what the lists draw. */
export type BizRow = {
  id: string; slug: string; name: string; name_en: string | null;
  short_description: string | null; full_description: string | null;
  address: string | null; latitude: number | null; longitude: number | null;
  cover_url: string | null; og_image_url: string | null; logo_url: string | null;
  rating: number | null; review_count: number | null; kosher_level: string | null;
  has_delivery: boolean | null; phone: string | null; whatsapp: string | null; email: string | null;
  promoted_until: string | null; created_at: string | null;
  neighborhoods: { name: string | null; name_en: string | null } | null;
};

const BIZ_FIELDS = 'id,slug,name,name_en,short_description,full_description,address,latitude,longitude,'
  + 'cover_url,og_image_url,logo_url,rating,review_count,kosher_level,has_delivery,phone,whatsapp,email,'
  + 'promoted_until,created_at,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)';

/** The panel's business categories, in its order (fetchCategories). */
export const businessCategories = cache(async (): Promise<BizCategory[]> => {
  const { data, error } = await db.from('categories')
    .select('id,slug,name,name_en,parent_id,sort_order,in_menus,image_url,meta_title,meta_description,description')
    .eq('scope', 'business').eq('is_active', true).order('sort_order', { ascending: true });
  // A failed read must not pass for "no such category" — that would answer
  // an address Google knows with a 404.
  if (error) throw new Error(`categories: ${error.message}`);
  return (data ?? []) as BizCategory[];
});

export async function businessCategoryBySlug(slug: string): Promise<BizCategory | null> {
  return (await businessCategories()).find((c) => c.slug === slug) ?? null;
}

/** Every business-to-category link (fetchCategoryLinks): one read for the
 *  whole directory — a couple of hundred rows — rather than one per list. */
export const categoryLinks = cache(async (): Promise<{ entity_id: string; category_id: string }[]> => {
  const { data, error } = await db.from('entity_categories').select('entity_id,category_id').eq('entity_type', 'business');
  if (error) throw new Error(`entity_categories: ${error.message}`);
  return (data ?? []) as { entity_id: string; category_id: string }[];
});

/** Whether an approved promotion (00069) is running now. */
export function isPromoted(b: Pick<BizRow, 'promoted_until'>): boolean {
  return !!b.promoted_until && new Date(b.promoted_until).getTime() > Date.now();
}

/** Every active business in the directory (businessesProvider): a promotion
 *  running first, then newest first. The database orders by promoted_until,
 *  which 00069 clears when it ends; the stable pass after it keeps a lapsed
 *  one from standing first should the clearing lag. */
export const activeBusinesses = cache(async (): Promise<BizRow[]> => {
  const { data, error } = await db.from('businesses').select(BIZ_FIELDS)
    .eq('status', 'active').eq('kind', 'business')
    .order('promoted_until', { ascending: false, nullsFirst: false })
    .order('created_at', { ascending: false });
  if (error) throw new Error(`businesses: ${error.message}`);
  const rows = (data ?? []) as unknown as BizRow[];
  return [...rows.filter(isPromoted), ...rows.filter((b) => !isPromoted(b))];
});

/** The ids filed under a category or directly under one of its children —
 *  a main category lists its sub-categories' businesses too, as the app and
 *  the old site's category pages did (fetchBusinessIdsInCategory). */
export async function idsInCategory(categoryId: string): Promise<Set<string>> {
  const [cats, links] = await Promise.all([businessCategories(), categoryLinks()]);
  const within = new Set([categoryId, ...cats.filter((c) => c.parent_id === categoryId).map((c) => c.id)]);
  return new Set(links.filter((l) => within.has(l.category_id)).map((l) => l.entity_id));
}

/** The active businesses in a category, in the directory's order. */
export async function businessesInCategory(categoryId: string): Promise<BizRow[]> {
  const [ids, all] = await Promise.all([idsInCategory(categoryId), activeBusinesses()]);
  return all.filter((b) => ids.has(b.id));
}

/** How many businesses sit in each category, a main category counting its
 *  sub-categories' businesses once each (fetchCategoryCounts), so the number
 *  on a card matches the list it opens. */
export const categoryCounts = cache(async (): Promise<Map<string, number>> => {
  const [cats, links] = await Promise.all([businessCategories(), categoryLinks()]);
  const parentOf = new Map(cats.map((c) => [c.id, c.parent_id]));
  const members = new Map<string, Set<string>>();
  const add = (cat: string, biz: string) => {
    if (!members.has(cat)) members.set(cat, new Set());
    members.get(cat)!.add(biz);
  };
  for (const l of links) {
    add(l.category_id, l.entity_id);
    const parent = parentOf.get(l.category_id);
    if (parent) add(parent, l.entity_id);
  }
  return new Map([...members].map(([k, v]) => [k, v.size]));
});

export type PrimaryCategory = { category: BizCategory; rootSlug: string };

/** The category a card names for each business (businessPrimaryCategory-
 *  Provider): the most specific one it is filed under — "פיצה" over
 *  "מסעדות" — leaving out the old site's lists kept out of the menus, with
 *  the slug at the top of its branch, which decides the card's badge. */
export const primaryCategories = cache(async (): Promise<Map<string, PrimaryCategory>> => {
  const [cats, links] = await Promise.all([businessCategories(), categoryLinks()]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const chosen = new Map<string, BizCategory>();
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (!c || c.in_menus === false) continue;
    const have = chosen.get(l.entity_id);
    if (!have || (have.parent_id == null && c.parent_id != null)) chosen.set(l.entity_id, c);
  }
  const rootOf = (c: BizCategory) => {
    let at = c;
    for (let depth = 0; depth < 5 && at.parent_id; depth++) {
      const parent = byId.get(at.parent_id);
      if (!parent) break;
      at = parent;
    }
    return at.slug;
  };
  return new Map([...chosen].map(([id, c]) => [id, { category: c, rootSlug: rootOf(c) }]));
});

/** Every category each business is linked to, keyed by business id. */
export const categoriesByBusiness = cache(async (): Promise<Map<string, BizCategory[]>> => {
  const [cats, links] = await Promise.all([businessCategories(), categoryLinks()]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const out = new Map<string, BizCategory[]>();
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (!c) continue;
    if (!out.has(l.entity_id)) out.set(l.entity_id, []);
    out.get(l.entity_id)!.push(c);
  }
  return out;
});

// ── names and texts in the reader's language ──

/** The English name where the panel has one and the reader chose English. */
export function localName(he: string, en: string | null | undefined, lang: Lang): string {
  const e = en?.trim();
  return lang === 'en' && e ? e : he;
}

export const catName = (c: Pick<BizCategory, 'name' | 'name_en'>, lang: Lang) => localName(c.name, c.name_en, lang);
export const bizName = (b: Pick<BizRow, 'name' | 'name_en'>, lang: Lang) => localName(b.name, b.name_en, lang);

/** The card's one line about the business: the short description, else the
 *  long one (Business.description), as plain text. */
export function bizDescription(b: Pick<BizRow, 'short_description' | 'full_description'>): string {
  return plain(b.short_description ?? b.full_description, 200);
}

export function bizNeighborhood(b: Pick<BizRow, 'neighborhoods'>, lang: Lang): string {
  return b.neighborhoods ? localName(b.neighborhoods.name ?? '', b.neighborhoods.name_en, lang) : '';
}

/** The certificate's name as the cards print it, or null for none. */
export function kosherLabel(level: string | null | undefined): string | null {
  switch (level) {
    case 'rabbanut': return 'רבנות';
    case 'mehadrin': return 'מהדרין';
    case 'badatz': return 'בד״ץ';
    case 'other': return 'כשר';
    default: return null;
  }
}

/** The cover, or the sharing picture where there is no cover. */
export const bizPhoto = (b: Pick<BizRow, 'cover_url' | 'og_image_url'>) => b.cover_url || b.og_image_url || null;

/** A photo in storage asked for at the width it is drawn (sizedPhotoUrl in
 *  network_photo.dart): `contain` inside a box as tall as storage allows, so
 *  only the width binds. Anything not in storage is left as it is. */
export function sizedPhoto(url: string | null | undefined, px: number): string | null {
  if (!url) return null;
  const stored = '/storage/v1/object/public/';
  if (!url.includes('.supabase.co' + stored)) return url;
  const path = url.split('?')[0].toLowerCase();
  if (!/\.(jpe?g|png|webp)$/.test(path)) return url;
  const steps = [200, 400, 600, 800, 1200, 1600, 2000, 2500];
  const width = steps.find((s) => s >= px) ?? 2500;
  const sep = url.includes('?') ? '&' : '?';
  return `${url.replace(stored, '/storage/v1/render/image/public/')}${sep}width=${width}&height=2500&resize=contain&quality=75`;
}

// ── restaurants ──

export type FoodKind = 'restaurant' | 'cafe' | 'bar';
export const BARS_KEY = 'bars';

/** Whether a business calls itself a bar or a pub (describesABar): there is
 *  no bar category the app reads, but a bar's own line opens with the word —
 *  "בר קוקטיילים", "פאב אירי", "wine & vibe | בר יין". Each "|" part is read on
 *  its own, since several put an English name first. */
export function describesABar(description: string | null | undefined): boolean {
  if (!description) return false;
  return description.split('|').some((part) => {
    const first = part.trim().split(/[\s,\-–]+/)[0].toLowerCase();
    return ['בר', 'פאב', 'bar', 'pub'].includes(first);
  });
}

export type FoodPlace = {
  business: BizRow;
  /** The most specific food category — "פיצה" rather than "מסעדות". */
  category: BizCategory | null;
  /** Every food category it is in, with their parents, plus 'bars'. */
  slugs: Set<string>;
  /** The sub-category of מסעדות it is filed under, for the card's pill. */
  cuisine: BizCategory | null;
  kind: FoodKind;
};

/** The places to eat and drink (_loadFoodPlaces): the businesses in
 *  "restaurants", its sub-categories or "cafe-bakery", in the directory's
 *  order — and, with [withBars], those that describe themselves as a bar. */
export async function foodPlaces(withBars: boolean): Promise<FoodPlace[]> {
  const [all, cats, links] = await Promise.all([activeBusinesses(), businessCategories(), categoryLinks()]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const restaurants = cats.find((c) => c.slug === 'restaurants');
  const isFood = (c: BizCategory) => c.slug === 'cafe-bakery' || c.slug === 'restaurants' || (!!restaurants && c.parent_id === restaurants.id);
  const perBusiness = new Map<string, BizCategory[]>();
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (!c || !isFood(c)) continue;
    if (!perBusiness.has(l.entity_id)) perBusiness.set(l.entity_id, []);
    perBusiness.get(l.entity_id)!.push(c);
  }
  const places: FoodPlace[] = [];
  for (const b of all) {
    const mine = perBusiness.get(b.id) ?? [];
    const isBar = withBars && describesABar(b.short_description ?? b.full_description);
    if (!mine.length && !isBar) continue;
    const specific = mine.length ? (mine.find((c) => c.slug !== 'restaurants') ?? mine[0]) : null;
    const slugs = new Set<string>();
    for (const c of mine) {
      slugs.add(c.slug);
      const parent = c.parent_id ? byId.get(c.parent_id) : undefined;
      if (parent) slugs.add(parent.slug);
    }
    if (isBar) slugs.add(BARS_KEY);
    places.push({
      business: b,
      category: specific,
      slugs,
      cuisine: mine.find((c) => !!restaurants && c.parent_id === restaurants.id) ?? null,
      // A place's own word for itself first: Portofino is filed under
      // קפה ומאפה and opens its line with "בר מסעדה".
      kind: isBar ? 'bar' : mine.some((c) => c.slug === 'cafe-bakery') ? 'cafe' : 'restaurant',
    });
  }
  return places;
}

/** Best rated first; among equals the one with a photograph, then the
 *  order they came in (_ratedFirst). */
export function ratedFirst<T extends { business: BizRow }>(places: T[]): T[] {
  const photo = (p: T) => (bizPhoto(p.business) ? 0 : 1);
  return places.map((p, i) => [p, i] as const).sort(([a, ai], [b, bi]) =>
    (b.business.rating ?? 0) - (a.business.rating ?? 0)
    || (b.business.review_count ?? 0) - (a.business.review_count ?? 0)
    || photo(a) - photo(b)
    || ai - bi).map(([p]) => p);
}
