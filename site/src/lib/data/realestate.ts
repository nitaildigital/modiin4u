import { cache } from 'react';
import { db } from '../supabase';
import { isUuid } from '../params';
import type { Lang } from '../i18n';

// What the real estate pages read: `listings` with its neighbourhood and
// agent, `neighborhoods`, and the businesses filed under a neighbourhood —
// the same queries as the app's ListingRepository and the realestate
// providers (lib/features/realestate/), so the site shows the same rows.
//
// Row level security does the deciding on `listings`: the public key reads
// only `active` rows (00018). A listing past its date is moved to `expired`
// by the nightly job (00066), so it drops out the same way.

export type ListingKind = 'sale' | 'rent';
export type PropertyType = 'apartment' | 'penthouse' | 'garden' | 'duplex' | 'villa' | 'studio' | 'other';

export type Hood = { id: string; name: string; name_en: string | null; description?: string | null };
export type Agent = { id: string; name: string | null; agency: string | null; phone: string | null; photo_url: string | null };

export type Listing = {
  id: string; title: string; kind: ListingKind; property_type: PropertyType;
  rooms: number | null; floor: number | null; sqm: number | null;
  price: number | null; price_per_month: number | null;
  address: string | null; neighborhood_id: string | null;
  latitude: number | null; longitude: number | null;
  cover_url: string | null; is_broker: boolean | null; is_featured: boolean | null;
  agent_id: string | null; contact_name: string | null; contact_phone: string | null;
  created_at: string;
  neighborhoods: Hood | null;
  real_estate_agents: Agent | null;
};

export type ListingDetail = Listing & {
  description: string | null; bathrooms: number | null; gallery: string[] | null;
  has_parking: boolean | null; has_elevator: boolean | null; has_storage: boolean | null;
  has_balcony: boolean | null; has_mamad: boolean | null; is_furnished: boolean | null;
  is_accessible: boolean | null; is_renovated: boolean | null; updated_at: string | null;
};

// `!inner` deliberately not used, as in the app: a listing with no agent and
// no neighbourhood is normal and must still come back.
const LIST_FIELDS = 'id,title,kind,property_type,rooms,floor,sqm,price,price_per_month,address,neighborhood_id,'
  + 'latitude,longitude,cover_url,is_broker,is_featured,agent_id,contact_name,contact_phone,created_at,'
  + 'neighborhoods(id,name,name_en),real_estate_agents(id,name,agency,phone,photo_url)';
const DETAIL_FIELDS = 'id,title,description,kind,property_type,rooms,bathrooms,floor,sqm,price,price_per_month,address,'
  + 'neighborhood_id,latitude,longitude,has_parking,has_elevator,has_storage,has_balcony,has_mamad,is_furnished,'
  + 'is_accessible,is_renovated,cover_url,gallery,agent_id,is_broker,contact_name,contact_phone,is_featured,created_at,updated_at,'
  + 'neighborhoods(id,name,name_en,description),real_estate_agents(id,name,agency,phone,photo_url)';

/** `fetchActive()`: every active listing, featured first, newest first, at
 *  most 100 — the one fetch every real estate page narrows for itself
 *  (allActiveListingsProvider). */
export const activeListings = cache(async (): Promise<Listing[]> => {
  const { data } = await db.from('listings').select(LIST_FIELDS).eq('status', 'active')
    .order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100);
  return (data ?? []) as unknown as Listing[];
});

/** One listing (`fetchById`). Null when the id matches no row, or the row is
 *  not active — the public read policy decides. */
export const listingById = cache(async (id: string): Promise<ListingDetail | null> => {
  if (!isUuid(id)) return null;
  const { data } = await db.from('listings').select(DETAIL_FIELDS).eq('id', id).maybeSingle();
  return data as unknown as ListingDetail | null;
});

/** Other active listings in the same neighbourhood (`fetchNearby`): six at
 *  most, none when the listing is filed under none. */
export async function nearbyListings(l: Pick<Listing, 'id' | 'neighborhood_id'>): Promise<Listing[]> {
  if (!l.neighborhood_id) return [];
  const { data } = await db.from('listings').select(LIST_FIELDS).eq('status', 'active')
    .eq('neighborhood_id', l.neighborhood_id).neq('id', l.id).limit(6);
  return (data ?? []) as unknown as Listing[];
}

/** A neighbourhood's active listings of one kind, featured and newest first
 *  (neighborhoodListingsProvider → fetchActive). */
export async function hoodListings(hoodId: string, kind: ListingKind): Promise<Listing[]> {
  const { data } = await db.from('listings').select(LIST_FIELDS).eq('status', 'active')
    .eq('neighborhood_id', hoodId).eq('kind', kind)
    .order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100);
  return (data ?? []) as unknown as Listing[];
}

export type AgentContact = { phone: string | null; whatsapp: string | null; email: string | null };

/** The agent's ways of being reached that the listing join leaves out
 *  (listingAgentContactProvider): the Contact menu offers WhatsApp and
 *  e-mail where the agent has them. */
export async function agentContact(agentId: string | null): Promise<AgentContact | null> {
  if (!agentId) return null;
  const { data } = await db.from('real_estate_agents').select('phone,whatsapp,email').eq('id', agentId).maybeSingle();
  if (!data) return null;
  const clean = (v: unknown) => (typeof v === 'string' && v.trim() ? v.trim() : null);
  return { phone: clean(data.phone), whatsapp: clean(data.whatsapp), email: clean(data.email) };
}

// ─── Neighbourhoods ───

export type Neighborhood = { id: string; name: string; name_en: string | null; slug: string | null; description: string | null; image_url: string | null };

/** Every active neighbourhood, in the order the admin set
 *  (activeNeighborhoodsProvider; the search's dropdown reads the same rows). */
export const activeNeighborhoods = cache(async (): Promise<Neighborhood[]> => {
  const { data } = await db.from('neighborhoods').select('id,name,name_en,slug,image_url')
    .eq('is_active', true).order('sort_order', { ascending: true });
  return ((data ?? []) as Omit<Neighborhood, 'description'>[]).map((n) => ({ ...n, description: null }));
});

/** The neighbourhood the address names (neighborhoodByIdProvider). */
export const neighborhoodById = cache(async (id: string): Promise<Neighborhood | null> => {
  if (!isUuid(id)) return null;
  const { data } = await db.from('neighborhoods').select('id,name,name_en,slug,description,image_url').eq('id', id).limit(1);
  const n = (data ?? [])[0] as Neighborhood | undefined;
  if (!n) return null;
  return { ...n, description: n.description?.trim() ? n.description.trim() : null };
});

/** Its photographs, the one set as its picture first, then its gallery from
 *  `entity_media` (neighborhoodPhotosProvider). */
export async function neighborhoodPhotos(n: Pick<Neighborhood, 'id' | 'image_url'>): Promise<string[]> {
  const { data } = await db.from('entity_media').select('sort_order, media(url)')
    .eq('entity_type', 'neighborhood').eq('entity_id', n.id).eq('role', 'gallery').order('sort_order', { ascending: true });
  const photos: string[] = [];
  const add = (u: unknown) => { if (typeof u === 'string' && u.trim() && !photos.includes(u)) photos.push(u); };
  add(n.image_url);
  for (const r of (data ?? []) as unknown as { media: { url: string } | null }[]) add(r.media?.url);
  return photos;
}

async function count(table: 'listings' | 'businesses', filters: [string, string][]): Promise<number | null> {
  let q = db.from(table).select('id', { count: 'exact', head: true });
  for (const [c, v] of filters) q = q.eq(c, v);
  const { count: n, error } = await q;
  return error ? null : n ?? 0;
}

/** The figures the database can answer. The website's box counts flats for
 *  sale (neighborhoodStatsProvider); the phone layout's cards count every
 *  active listing there (neighborhoodCountsProvider) — under the same label,
 *  as the app has it. Null when a count could not be read: a dash, not a
 *  nought. */
export async function neighborhoodFigures(id: string) {
  const [forSale, listings, businesses] = await Promise.all([
    count('listings', [['neighborhood_id', id], ['status', 'active'], ['kind', 'sale']]),
    count('listings', [['neighborhood_id', id], ['status', 'active']]),
    count('businesses', [['neighborhood_id', id], ['status', 'active'], ['kind', 'business']]),
  ]);
  return { forSale, listings, businesses };
}

/** The residents' average and how many rated (`neighborhood_rating_summary`,
 *  00071) — null when nobody has, so no "0.0" reads as a bad score. */
export async function neighborhoodRating(id: string): Promise<{ average: number; count: number } | null> {
  try {
    const { data } = await db.rpc('neighborhood_rating_summary', { p_neighborhood: id });
    const row = ((data ?? []) as { average: number | null; ratings: number | null }[])[0];
    const n = row?.ratings ?? 0;
    if (!row || !n || row.average == null) return null;
    return { average: Number(row.average), count: n };
  } catch {
    return null;
  }
}

// ─── Businesses filed under a neighbourhood ───

export type HoodBusiness = {
  id: string; slug: string | null; name: string; name_en: string | null;
  short_description: string | null; full_description: string | null; address: string | null;
  cover_url: string | null; og_image_url: string | null; logo_url: string | null;
  rating: number | null; review_count: number | null;
  neighborhoods: { name: string; name_en: string | null } | null;
  /** What it is (its category in the reader's language), and the root
   *  category's slug, for the café / restaurant badge. */
  kind?: { name: string; rootSlug: string } | null;
};

/** Active businesses there, promoted first then newest (BusinessRepository
 *  .fetchAll), the ones with a photograph first (neighborhoodBusinessesProvider). */
export async function hoodBusinesses(hoodId: string, lang: Lang): Promise<HoodBusiness[]> {
  const fields = 'id,slug,name,name_en,short_description,full_description,address,cover_url,og_image_url,logo_url,'
    + 'rating,review_count,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)';
  const { data } = await db.from('businesses').select(fields).eq('status', 'active').eq('kind', 'business')
    .eq('neighborhood_id', hoodId)
    .order('promoted_until', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false });
  const all = (data ?? []) as unknown as HoodBusiness[];
  const pictured = (b: HoodBusiness) => !!(b.cover_url || b.og_image_url);
  const rows = [...all.filter(pictured), ...all.filter((b) => !pictured(b))];
  if (!rows.length) return rows;
  const kinds = await primaryCategories(rows.map((b) => b.id), lang);
  return rows.map((b) => ({ ...b, kind: kinds[b.id] ?? null }));
}

type Cat = { id: string; name: string; name_en: string | null; slug: string; parent_id: string | null; in_menus: boolean | null };

const businessCategories = cache(async (): Promise<Cat[]> => {
  const { data } = await db.from('categories').select('id,name,name_en,slug,parent_id,in_menus')
    .eq('scope', 'business').eq('is_active', true).order('sort_order', { ascending: true });
  return (data ?? []) as Cat[];
});

/** Each business's own category (businessPrimaryCategoryProvider): one shown
 *  in the menus, a sub-category over a main one, with its root's slug. */
async function primaryCategories(ids: string[], lang: Lang): Promise<Record<string, { name: string; rootSlug: string }>> {
  const [cats, { data: links }] = await Promise.all([
    businessCategories(),
    db.from('entity_categories').select('entity_id,category_id').eq('entity_type', 'business').in('entity_id', ids),
  ]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const chosen = new Map<string, Cat>();
  for (const link of (links ?? []) as { entity_id: string; category_id: string }[]) {
    const c = byId.get(link.category_id);
    if (!c || c.in_menus === false) continue;
    const have = chosen.get(link.entity_id);
    if (!have || (have.parent_id == null && c.parent_id != null)) chosen.set(link.entity_id, c);
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
  const out: Record<string, { name: string; rootSlug: string }> = {};
  for (const [id, c] of chosen) out[id] = { name: localName(c.name, c.name_en, lang), rootSlug: rootOf(c) };
  return out;
}

/** Hebrew, and English where the panel has one (00062, 00066). */
export function localName(he: string, en: string | null | undefined, lang: Lang): string {
  const e = en?.trim();
  return lang === 'en' && e ? e : he;
}
