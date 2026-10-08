import { cache } from 'react';
import { db } from '../supabase';
import { isUuid } from '../params';

/** A deal, as the `offers` table stores it, with the business behind it
 *  (lib/features/deals/models/offer.dart). */
export type Deal = {
  id: string;
  name: string;
  description: string | null;
  terms: string | null;
  image_url: string | null;
  start_at: string | null;
  end_at: string | null;
  max_claims: number | null;
  max_per_user: number | null;
  points_required: number;
  is_featured: boolean;
  claim_count: number;
  /** `all`, `verified` (the design's "Residents Only") or `new_users`. */
  audience: string | null;
  created_at: string | null;
  /** How long is left when the page was drawn, in milliseconds; 0 once it
   *  has ended, null when the deal has no end date. */
  ms_left: number | null;
  business: {
    id: string; slug: string; name: string; name_en: string | null; address: string | null; phone: string | null;
    logo: string | null; cover: string | null; hood: string | null; hood_en: string | null;
  } | null;
};

const BUSINESS = 'businesses(id,slug,name,name_en,address,phone,logo_url,cover_url,neighborhoods!businesses_neighborhood_id_fkey(name,name_en))';
const LIST = `id,name,image_url,start_at,end_at,max_claims,max_per_user,points_required,is_featured,claim_count,audience,created_at,business_id,${BUSINESS}`;
const DETAIL = `id,name,description,terms,image_url,start_at,end_at,max_claims,max_per_user,points_required,is_featured,claim_count,audience,created_at,business_id,${BUSINESS}`;

type Row = Record<string, unknown>;

function text(v: unknown): string | null {
  return typeof v === 'string' && v.trim() ? v : null;
}

function toDeal(r: Row, now: number): Deal {
  const b = r.businesses as Row | null;
  const hood = b?.neighborhoods as Row | null | undefined;
  const end = text(r.end_at);
  return {
    id: r.id as string,
    name: (r.name as string) ?? '',
    description: text(r.description),
    terms: text(r.terms),
    image_url: text(r.image_url),
    start_at: text(r.start_at),
    end_at: end,
    max_claims: r.max_claims == null ? null : Number(r.max_claims),
    max_per_user: r.max_per_user == null ? null : Number(r.max_per_user),
    points_required: Number(r.points_required ?? 0),
    is_featured: !!r.is_featured,
    claim_count: Number(r.claim_count ?? 0),
    audience: text(r.audience),
    created_at: text(r.created_at),
    ms_left: end ? Math.max(0, Date.parse(end) - now) : null,
    business: b ? {
      id: b.id as string,
      slug: (b.slug as string) ?? '',
      name: (b.name as string) ?? '',
      name_en: text(b.name_en),
      address: text(b.address),
      phone: text(b.phone),
      logo: text(b.logo_url),
      cover: text(b.cover_url),
      hood: text(hood?.name),
      hood_en: text(hood?.name_en),
    } : null,
  };
}

/** Whether the deal is over: the table keeps an offer `active` until the
 *  panel expires it, and one whose end date has passed is not a deal any
 *  more. */
export function hasExpired(d: Pick<Deal, 'ms_left'>): boolean {
  return d.ms_left === 0;
}

/** Every active offer (activeOffersProvider, fetchActive): one with an
 *  approved promotion first, then the panel's featured ones, then the
 *  soonest to end — sixty at most, as the app reads them. */
export const activeDeals = cache(async (): Promise<Deal[]> => {
  const base = () => db.from('offers').select(LIST).eq('status', 'active');
  let res = await base().order('promoted_until', { ascending: false, nullsFirst: false })
    .order('is_featured', { ascending: false }).order('end_at', { ascending: true, nullsFirst: false }).limit(60);
  // Before 00069 there is no promotion column; the old order then.
  if (res.error && res.error.message.includes('promoted_until')) {
    res = await base().order('is_featured', { ascending: false }).order('end_at', { ascending: true, nullsFirst: false }).limit(60);
  }
  const now = Date.now();
  return ((res.data ?? []) as unknown as Row[]).map((r) => toDeal(r, now));
});

/** The deals still running. */
export async function liveDeals(): Promise<Deal[]> {
  return (await activeDeals()).filter((d) => !hasExpired(d));
}

/** One deal by its id, as the app opens it — the database's own rules let a
 *  visitor read the active ones; one that has ended by its date still opens,
 *  and says so. */
export const dealById = cache(async (id: string): Promise<Deal | null> => {
  if (!isUuid(id)) return null;
  const { data } = await db.from('offers').select(DETAIL).eq('id', id).maybeSingle();
  return data ? toDeal(data as unknown as Row, Date.now()) : null;
});

export type DealCategory = { id: string; name: string; name_en: string | null; slug: string; image_url: string | null };

/** The business categories at the top of the tree that are in the menus, in
 *  the admin's order (businessCategoriesProvider). A deal has no category of
 *  its own; it is in its business's. */
export const dealCategories = cache(async (): Promise<DealCategory[]> => {
  const { data } = await db.from('categories').select('id,name,name_en,slug,image_url,parent_id,in_menus')
    .eq('scope', 'business').eq('is_active', true).order('sort_order', { ascending: true });
  return ((data ?? []) as (DealCategory & { parent_id: string | null; in_menus: boolean | null })[])
    .filter((c) => c.parent_id == null && c.in_menus !== false)
    .map(({ id, name, name_en, slug, image_url }) => ({ id, name, name_en, slug, image_url }));
});

/** For each business, every category it is filed under together with the
 *  ones above them — so a pizzeria answers both פיצה and מסעדות
 *  (fetchCategoriesOfBusinesses). */
export async function categoriesOfBusinesses(ids: string[]): Promise<Record<string, string[]>> {
  const unique = [...new Set(ids)];
  if (!unique.length) return {};
  const [{ data: cats }, { data: links }] = await Promise.all([
    db.from('categories').select('id,parent_id').eq('scope', 'business'),
    db.from('entity_categories').select('category_id,entity_id').eq('entity_type', 'business').in('entity_id', unique),
  ]);
  const parents = new Map(((cats ?? []) as { id: string; parent_id: string | null }[]).map((c) => [c.id, c.parent_id]));
  const out: Record<string, Set<string>> = {};
  for (const l of (links ?? []) as { category_id: string; entity_id: string }[]) {
    // A link to an article or event category is not a business's kind.
    if (!parents.has(l.category_id)) continue;
    const set = (out[l.entity_id] ??= new Set());
    let at: string | null | undefined = l.category_id;
    for (let depth = 0; depth < 6 && at; depth++) {
      set.add(at);
      at = parents.get(at);
    }
  }
  return Object.fromEntries(Object.entries(out).map(([k, v]) => [k, [...v]]));
}

/** A business's gallery, in the editor's order — the phone deal page's
 *  "Show all photos" (businessGalleryProvider). */
export async function businessGallery(businessId: string): Promise<string[]> {
  const { data } = await db.from('entity_media').select('sort_order,media(url)')
    .eq('entity_type', 'business').eq('entity_id', businessId).eq('role', 'gallery').order('sort_order', { ascending: true });
  return ((data ?? []) as unknown as { media: { url: string | null } | null }[])
    .map((r) => r.media?.url).filter((u): u is string => !!u);
}
