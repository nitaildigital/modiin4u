import type { Lang } from '@/lib/i18n';
import { isUuid } from '@/lib/params';
import type { Listing, ListingKind, PropertyType } from '@/lib/data/realestate';
import { hoodName, priceOf } from './format';

// The real estate search as the address carries it — the filters of
// web_realestate_search_screen.dart (and the phone tab's), each a `?` field,
// so a search is a page of its own that the server draws:
//   kind=sale|rent   q=<text>   type=<type> (repeatable)   rooms=1..5 (repeatable, 5 = 5+)
//   floor=low|mid|high   neighborhood=<id>   min=<₪>   max=<₪>   sort=newest|price-low|price-high

export type SearchParams = Record<string, string | string[] | undefined>;

export type Floor = 'low' | 'mid' | 'high';
export type Sort = 'newest' | 'price-low' | 'price-high';

export type Search = {
  kind: ListingKind | null; q: string; types: PropertyType[]; rooms: number[];
  floor: Floor | null; neighborhood: string | null; min: number | null; max: number | null; sort: Sort;
};

const TYPES: PropertyType[] = ['apartment', 'penthouse', 'garden', 'duplex', 'villa', 'studio', 'other'];

const all = (v: string | string[] | undefined) => (Array.isArray(v) ? v : v ? [v] : []);
const one = (v: string | string[] | undefined) => all(v)[0] ?? '';
const num = (v: string) => (/^\d+$/.test(v) ? Number(v) : null);

export function readSearch(sp: SearchParams): Search {
  const kind = one(sp.kind);
  const floor = one(sp.floor);
  const sort = one(sp.sort);
  const hood = one(sp.neighborhood);
  return {
    kind: kind === 'sale' || kind === 'rent' ? kind : null,
    q: one(sp.q).trim().slice(0, 100),
    types: [...new Set(all(sp.type).filter((t): t is PropertyType => TYPES.includes(t as PropertyType)))],
    rooms: [...new Set(all(sp.rooms).map(Number).filter((n) => n >= 1 && n <= 5 && Number.isInteger(n)))],
    floor: floor === 'low' || floor === 'mid' || floor === 'high' ? floor : null,
    neighborhood: isUuid(hood) ? hood : null,
    min: num(one(sp.min)),
    max: num(one(sp.max)),
    sort: sort === 'price-low' || sort === 'price-high' ? sort : 'newest',
  };
}

/** The address of a search, the empty fields left out. */
export function searchHref(s: Partial<Search>, base = '/search-apartments/'): string {
  const p = new URLSearchParams();
  if (s.kind) p.set('kind', s.kind);
  if (s.q) p.set('q', s.q);
  for (const t of s.types ?? []) p.append('type', t);
  for (const r of s.rooms ?? []) p.append('rooms', String(r));
  if (s.floor) p.set('floor', s.floor);
  if (s.neighborhood) p.set('neighborhood', s.neighborhood);
  if (s.min != null) p.set('min', String(s.min));
  if (s.max != null) p.set('max', String(s.max));
  if (s.sort && s.sort !== 'newest') p.set('sort', s.sort);
  const qs = p.toString();
  return qs ? `${base}?${qs}` : base;
}

/** How many filters narrow the list beyond the typed search. */
export function filterCount(s: Search): number {
  return (s.types.length ? 1 : 0) + (s.rooms.length ? 1 : 0) + (s.min != null || s.max != null ? 1 : 0)
    + (s.floor ? 1 : 0) + (s.neighborhood ? 1 : 0);
}

const FLOORS: Record<Floor, [number, number | null]> = { low: [1, 3], mid: [4, 7], high: [8, null] };

/** The search page's own filtering (_apply): the typed text in the title,
 *  the address or the neighbourhood; the ticked types and room counts; the
 *  price range — a listing with no price drops out once a range is set; the
 *  floor bucket — an unrecorded floor sits in none; the neighbourhood. */
export function applySearch(rows: Listing[], s: Search, lang: Lang): Listing[] {
  const q = s.q.toLowerCase();
  return rows.filter((l) => {
    if (q && !l.title.toLowerCase().includes(q) && !(l.address ?? '').toLowerCase().includes(q)
      && !(hoodName(l, lang) ?? '').toLowerCase().includes(q) && !(l.neighborhoods?.name ?? '').toLowerCase().includes(q)) return false;
    if (s.types.length && !s.types.includes(l.property_type)) return false;
    if (s.rooms.length) {
      if (l.rooms == null) return false;
      if (!s.rooms.includes(l.rooms >= 5 ? 5 : Math.floor(l.rooms))) return false;
    }
    if (s.min != null || s.max != null) {
      const p = priceOf(l);
      if (p == null) return false;
      if (s.min != null && p < s.min) return false;
      if (s.max != null && p > s.max) return false;
    }
    if (s.floor) {
      const [from, to] = FLOORS[s.floor];
      if (l.floor == null || l.floor < from || (to != null && l.floor > to)) return false;
    }
    if (s.neighborhood && l.neighborhood_id !== s.neighborhood) return false;
    return true;
  });
}

/** Newest first, or by price — a listing with no price last either way,
 *  rather than as if it were the cheapest. */
export function sortListings(rows: Listing[], sort: Sort): Listing[] {
  const out = [...rows];
  if (sort === 'newest') return out.sort((a, b) => b.created_at.localeCompare(a.created_at));
  const up = sort === 'price-low';
  return out.sort((a, b) => {
    const pa = priceOf(a), pb = priceOf(b);
    if (pa == null && pb == null) return 0;
    if (pa == null) return 1;
    if (pb == null) return -1;
    return up ? pa - pb : pb - pa;
  });
}

/** The cheapest and the dearest price among [rows], or null when there are
 *  not two different prices to slide between. */
export function priceBounds(rows: Listing[]): [number, number] | null {
  const prices = rows.map(priceOf).filter((p): p is number => p != null).sort((a, b) => a - b);
  if (prices.length < 2 || prices[0] === prices[prices.length - 1]) return null;
  return [prices[0], prices[prices.length - 1]];
}
