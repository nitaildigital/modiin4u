import { cache } from 'react';
import { db } from '../supabase';
import type { Lang } from '../i18n';

// What the home page reads, query for query as the Flutter home screens do
// (home_web_providers.dart, business_providers.dart, event_providers.dart,
// offer_providers.dart, listing_providers.dart, map_providers.dart). Both
// layouts are in one page, so each read is made once per request (`cache`)
// and shared by the desktop sections and the phone rows.

// ── The site notice ──────────────────────────────────────────────────────

export type HomeNotice = { id: string; label: string | null; message: string | null; link: string | null; linkLabel: string | null };

type Cfg = Record<string, unknown>;

/** `<key>_he` / `<key>_en` for the page's language, else the plain `<key>`. */
function cfgText(config: Cfg, key: string, lang: Lang): string | null {
  for (const k of [`${key}_${lang}`, key]) {
    const v = config[k];
    if (typeof v === 'string' && v.trim()) return v.trim();
  }
  return null;
}

/** The `alert` row of `home_blocks` running now — the bar under the hero —
 *  or null. Published, active, and inside its start/end window; a failed
 *  read shows no notice (homeNoticeProvider). */
export const homeNotice = cache(async (lang: Lang): Promise<HomeNotice | null> => {
  try {
    const { data } = await db.from('home_blocks').select('id,title,config,start_at,end_at,sort_order')
      .eq('block_type', 'alert').eq('is_active', true).eq('published', true).order('sort_order');
    const now = Date.now();
    for (const r of (data ?? []) as { id: string; title: string | null; config: Cfg | null; start_at: string | null; end_at: string | null }[]) {
      if (r.start_at && Date.parse(r.start_at) > now) continue;
      if (r.end_at && Date.parse(r.end_at) < now) continue;
      const c = r.config && typeof r.config === 'object' ? r.config : {};
      const own = r.title?.trim() || null;
      const label = cfgText(c, 'title', lang) ?? cfgText(c, 'label', lang) ?? own;
      const message = cfgText(c, 'message', lang) ?? cfgText(c, 'text', lang) ?? cfgText(c, 'body', lang);
      // A notice with nothing to say in English has nothing to say at all.
      if (!(cfgText(c, 'message', 'en') ?? cfgText(c, 'text', 'en') ?? cfgText(c, 'body', 'en')) && !(cfgText(c, 'title', 'en') ?? cfgText(c, 'label', 'en') ?? own)) continue;
      let link: string | null = null;
      for (const k of ['url', 'link', 'link_url', 'href', 'route']) {
        const v = c[k];
        if (typeof v === 'string' && v.trim()) { link = v.trim(); break; }
      }
      return { id: r.id, label, message, link, linkLabel: cfgText(c, 'link_label', lang) ?? cfgText(c, 'cta', lang) };
    }
    return null;
  } catch {
    return null;
  }
});

// ── Businesses ───────────────────────────────────────────────────────────

export type Biz = {
  id: string; slug: string; name: string; name_en: string | null;
  short_description: string | null; full_description: string | null;
  cover_url: string | null; og_image_url: string | null; logo_url: string | null;
  address: string | null; phone: string | null; whatsapp: string | null; email: string | null;
  rating: number | null; review_count: number | null; kosher_level: string | null;
  latitude: number | null; longitude: number | null; promoted_until: string | null;
  neighborhoods: { name: string | null; name_en: string | null } | null;
};

const BIZ = 'id,slug,name,name_en,short_description,full_description,cover_url,og_image_url,logo_url,address,phone,whatsapp,email,rating,review_count,kosher_level,latitude,longitude,promoted_until,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)';

/** Every active business (not parks), a running promotion first, then the
 *  newest — BusinessRepository.fetchAll(status: 'active'). */
export const activeBusinesses = cache(async (): Promise<Biz[]> => {
  const { data } = await db.from('businesses').select(BIZ).eq('status', 'active').eq('kind', 'business')
    .order('promoted_until', { ascending: false, nullsFirst: false }).order('created_at', { ascending: false });
  return (data ?? []) as unknown as Biz[];
});

/** The photograph a card shows: the cover, else the sharing image. */
export const bizImage = (b: Biz) => b.cover_url || b.og_image_url || null;
/** The one-line description: the short one, else the long one. */
export const bizDescription = (b: Biz) => (b.short_description ?? b.full_description ?? '').trim();
export const bizName = (b: Biz, lang: Lang) => (lang === 'en' && b.name_en?.trim()) || b.name;
export const bizNeighborhood = (b: Biz, lang: Lang) =>
  (lang === 'en' && b.neighborhoods?.name_en?.trim()) || b.neighborhoods?.name || '';
export const isPromoted = (b: Biz) => !!b.promoted_until && Date.parse(b.promoted_until) > Date.now();

/** The kosher certificate as the cards name it, or null for none. */
export function kosherLabel(level: string | null): string | null {
  switch (level) {
    case 'rabbanut': return 'רבנות';
    case 'mehadrin': return 'מהדרין';
    case 'badatz': return 'בד״ץ';
    case 'other': return 'כשר';
    default: return null;
  }
}

export type Cat = { id: string; slug: string; name: string; name_en: string | null; parent_id: string | null; sort_order: number | null; in_menus: boolean | null };

export const businessCategories = cache(async (): Promise<Cat[]> => {
  const { data } = await db.from('categories').select('id,slug,name,name_en,parent_id,sort_order,in_menus')
    .eq('scope', 'business').eq('is_active', true).order('sort_order');
  return (data ?? []) as Cat[];
});

export const catName = (c: Pick<Cat, 'name' | 'name_en'>, lang: Lang) => (lang === 'en' && c.name_en?.trim()) || c.name;

/** Every business-to-category link, read a thousand at a time (the API's
 *  page size), so the filing stays whole as it grows. In the table's own
 *  order, as the app reads them: where a business is filed under two
 *  sub-categories, the first link names it. */
export const businessLinks = cache(async (): Promise<{ entity_id: string; category_id: string }[]> => {
  const out: { entity_id: string; category_id: string }[] = [];
  for (let from = 0; ; from += 1000) {
    const { data } = await db.from('entity_categories').select('entity_id,category_id')
      .eq('entity_type', 'business').range(from, from + 999);
    out.push(...((data ?? []) as typeof out));
    if (!data || data.length < 1000) break;
  }
  return out;
});

export type Kind = { category: Cat; rootSlug: string };

/** The category each card names, by business id, and the slug of the top of
 *  its branch (businessPrimaryCategoryProvider): the most specific link
 *  wins, and the old site's lists kept out of the menus never label one. */
export const primaryCategories = cache(async (): Promise<Map<string, Kind>> => {
  const [cats, links] = await Promise.all([businessCategories(), businessLinks()]);
  const byId = new Map(cats.map((c) => [c.id, c]));
  const chosen = new Map<string, Cat>();
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (!c || c.in_menus === false) continue;
    const have = chosen.get(l.entity_id);
    if (!have || (have.parent_id == null && c.parent_id != null)) chosen.set(l.entity_id, c);
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
  return new Map([...chosen].map(([id, c]) => [id, { category: c, rootSlug: rootOf(c) }]));
});

const hasPhoto = (b: Biz) => !!bizImage(b);

/** "AI Picks": the businesses marked recommended, or featured inside their
 *  window (homeRecommendedBusinessesProvider), photographed ones first; then,
 *  to fill the rows, the rest of the directory with a photograph, then
 *  without — never padded with anything invented. */
export const recommendedBusinesses = cache(async (count: number): Promise<Biz[]> => {
  const [picksRaw, all] = await Promise.all([
    db.from('businesses').select(BIZ + ',is_recommended,featured_start,featured_end')
      .eq('status', 'active').eq('kind', 'business').or('is_recommended.eq.true,is_featured.eq.true')
      .order('updated_at', { ascending: false }),
    activeBusinesses(),
  ]);
  const now = Date.now();
  const picked = ((picksRaw.data ?? []) as unknown as (Biz & { is_recommended: boolean | null; featured_start: string | null; featured_end: string | null })[])
    .filter((r) => r.is_recommended || (!(r.featured_start && Date.parse(r.featured_start) > now) && !(r.featured_end && Date.parse(r.featured_end) < now)));
  const picks = [...picked.filter(hasPhoto), ...picked.filter((b) => !hasPhoto(b))];
  const ids = new Set(picks.map((b) => b.id));
  const rest = all.filter((b) => !ids.has(b.id));
  return [...picks, ...rest.filter(hasPhoto), ...rest.filter((b) => !hasPhoto(b))].slice(0, count);
});

/** Restaurants and cafés for the phone's first row (nearbyRestaurantsProvider
 *  without a location): the businesses filed under restaurants, its cuisines
 *  or cafés; a running promotion first, then those with a photograph, then
 *  the best rated and the most reviewed. */
export const foodPlaces = cache(async (): Promise<Biz[]> => {
  const [all, cats, links] = await Promise.all([activeBusinesses(), businessCategories(), businessLinks()]);
  const restaurants = cats.find((c) => c.slug === 'restaurants')?.id;
  const food = new Set(cats.filter((c) => c.slug === 'restaurants' || c.slug === 'cafe-bakery' || (restaurants && c.parent_id === restaurants)).map((c) => c.id));
  const ids = new Set(links.filter((l) => food.has(l.category_id)).map((l) => l.entity_id));
  const photo = (b: Biz) => (hasPhoto(b) ? 0 : 1);
  return all.filter((b) => ids.has(b.id)).sort((a, b) =>
    (isPromoted(b) ? 1 : 0) - (isPromoted(a) ? 1 : 0)
    || photo(a) - photo(b)
    || (b.rating ?? 0) - (a.rating ?? 0)
    || (b.review_count ?? 0) - (a.review_count ?? 0));
});

export type Trade = { category: Cat; ids: Set<string> };

/** Whoever the professionals row can show — filed under Services or a trade
 *  beneath it — and the trades with somebody in them, in the categories'
 *  order (professionalTradesProvider). Faces first: the card is built round
 *  the photograph. */
export const professionals = cache(async (): Promise<{ people: Biz[]; trades: Trade[] }> => {
  const [all, cats, links] = await Promise.all([activeBusinesses(), businessCategories(), businessLinks()]);
  const services = cats.find((c) => c.parent_id == null && c.slug === 'services');
  if (!services) return { people: [], trades: [] };
  const byCat = new Map<string, Set<string>>();
  for (const l of links) {
    if (!byCat.has(l.category_id)) byCat.set(l.category_id, new Set());
    byCat.get(l.category_id)!.add(l.entity_id);
  }
  const trades = cats.filter((c) => c.parent_id === services.id)
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    .filter((c) => (byCat.get(c.id)?.size ?? 0) > 0)
    .map((c) => ({ category: c, ids: byCat.get(c.id)! }));
  const everyone = new Set([...(byCat.get(services.id) ?? []), ...trades.flatMap((t) => [...t.ids])]);
  const pool = all.filter((b) => everyone.has(b.id));
  const face = (b: Biz) => !!(b.logo_url || bizImage(b));
  return { people: [...pool.filter(face), ...pool.filter((b) => !face(b))], trades };
});

// ── Articles ─────────────────────────────────────────────────────────────

export type HomeArticle = { id: string; slug: string; title: string; excerpt: string | null; image: string | null; published_at: string | null };

/** The newest published articles (publishedArticlesProvider: by
 *  `published_at`, newest first), with the picture the app shows — the
 *  featured image, else the phone one, else the sharing one. */
export const homeArticles = cache(async (limit: number): Promise<HomeArticle[]> => {
  const { data } = await db.from('articles').select('id,slug,title,excerpt,featured_image,mobile_image,og_image,published_at')
    .eq('status', 'published').order('published_at', { ascending: false, nullsFirst: false })
    .order('created_at', { ascending: false }).limit(limit);
  return ((data ?? []) as { id: string; slug: string; title: string; excerpt: string | null; featured_image: string | null; mobile_image: string | null; og_image: string | null; published_at: string | null }[])
    .map((a) => ({ id: a.id, slug: a.slug, title: a.title, excerpt: a.excerpt, image: a.featured_image || a.mobile_image || a.og_image || null, published_at: a.published_at }));
});

// ── Events ───────────────────────────────────────────────────────────────

export type HomeEvent = {
  id: string; slug: string | null; title: string; image_url: string | null; og_image: string | null;
  start_date: string | null; start_time: string | null; is_all_day: boolean | null;
  venue_name: string | null; address: string | null; is_free: boolean | null; price: number | string | null;
  latitude: number | null; longitude: number | null;
};

/** Every published event, earliest first (EventRepository.fetchAll). */
export const publishedEvents = cache(async (): Promise<HomeEvent[]> => {
  // From yesterday on (Israel), in the database: the past would otherwise
  // pile up and, past a thousand rows, push the coming ones out.
  const since = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jerusalem', year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(new Date(Date.now() - 86_400_000));
  const { data } = await db.from('events')
    .select('id,slug,title,image_url,og_image,start_date,start_time,is_all_day,venue_name,address,is_free,price,latitude,longitude')
    .eq('status', 'published').or(`start_date.gte.${since},start_date.is.null`).order('start_date', { ascending: true });
  return (data ?? []) as HomeEvent[];
});

/** "2026-10-08 20:00" — now, on the clock in Modi'in. */
function israelNow(): string {
  const p = Object.fromEntries(new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Jerusalem', year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  }).formatToParts(new Date()).map((x) => [x.type, x.value]));
  return `${p.year}-${p.month}-${p.day} ${p.hour}:${p.minute}`;
}

/** Events still to come (upcomingEventsProvider): one whose start, on the
 *  city's clock, is still ahead — or that gives no date at all. */
export const upcomingEvents = cache(async (): Promise<HomeEvent[]> => {
  const now = israelNow();
  return (await publishedEvents()).filter((e) => {
    if (!e.start_date) return true;
    const t = /^\d{1,2}:\d{2}/.test(e.start_time ?? '') ? e.start_time!.slice(0, 5).padStart(5, '0') : '00:00';
    return `${e.start_date.slice(0, 10)} ${t}` >= now;
  });
});

/** "20:00", or null when the event runs all day or gives no time. */
export function eventTime(e: HomeEvent): string | null {
  if (e.is_all_day) return null;
  const m = /^(\d{1,2}):(\d{2})/.exec(e.start_time ?? '');
  return m ? `${m[1]}:${m[2]}` : null;
}

/** "₪50", or null — a whole number without its decimals. */
export function eventPrice(e: HomeEvent): string | null {
  if (e.price == null || e.price === '') return null;
  const n = Number(e.price);
  const s = Number.isFinite(n) ? (Number.isInteger(n) ? String(n) : String(n)) : String(e.price);
  return s.startsWith('₪') ? s : '₪' + s;
}

const EN_EVENT_CATEGORY: Record<string, string> = {
  concerts: 'Music', music: 'Music', community: 'Municipal & Community', 'municipal-community': 'Municipal & Community',
  kids: 'Kids & Family', 'kids-family': 'Kids & Family', 'sports-events': 'Sports', sports: 'Sports',
  workshops: 'Workshops', 'food-drink': 'Food & Drink',
};

/** Each event's first category, primary first, in the page's language
 *  (eventCategoriesByEventProvider + EventLabels.category). */
export const eventCategoryNames = cache(async (lang: Lang): Promise<Map<string, string>> => {
  const [{ data: cats }, { data: links }] = await Promise.all([
    db.from('categories').select('id,slug,name,name_en').eq('scope', 'event').eq('is_active', true).order('sort_order'),
    db.from('entity_categories').select('entity_id,category_id,is_primary').eq('entity_type', 'event'),
  ]);
  const byId = new Map(((cats ?? []) as Cat[]).map((c) => [c.id, c]));
  const out = new Map<string, string>();
  const sorted = ((links ?? []) as { entity_id: string; category_id: string; is_primary: boolean | null }[])
    .sort((a, b) => (a.is_primary ? 0 : 1) - (b.is_primary ? 0 : 1));
  for (const l of sorted) {
    const c = byId.get(l.category_id);
    if (!c || out.has(l.entity_id)) continue;
    out.set(l.entity_id, lang === 'he' ? c.name : EN_EVENT_CATEGORY[c.slug] ?? (c.name_en?.trim() || c.name));
  }
  return out;
});

// ── Deals ────────────────────────────────────────────────────────────────

export type HomeOffer = { id: string; name: string; image_url: string | null; end_at: string | null; businesses: { logo_url: string | null; cover_url: string | null } | null };

/** Active deals whose time is not up (activeOffersProvider, !hasExpired):
 *  a running promotion first, then the featured, then the soonest to end. */
export const liveOffers = cache(async (): Promise<HomeOffer[]> => {
  const { data } = await db.from('offers').select('id,name,image_url,end_at,businesses(logo_url,cover_url)')
    .eq('status', 'active')
    .order('promoted_until', { ascending: false, nullsFirst: false })
    .order('is_featured', { ascending: false })
    .order('end_at', { ascending: true, nullsFirst: false })
    .limit(60);
  const now = Date.now();
  return ((data ?? []) as unknown as HomeOffer[]).filter((o) => !o.end_at || Date.parse(o.end_at) > now);
});

// ── Real estate ──────────────────────────────────────────────────────────

export type HomeListing = {
  id: string; slug: string | null; title: string; kind: string | null; price: number | null; price_per_month: number | null;
  address: string | null; sqm: number | null; rooms: number | null; cover_url: string | null;
  latitude: number | null; longitude: number | null; neighborhoods: { name: string | null; name_en: string | null } | null;
};

/** Active listings, featured first, then the newest (fetchActive, its
 *  default hundred). */
export const activeListings = cache(async (): Promise<HomeListing[]> => {
  const { data } = await db.from('listings')
    .select('id,slug,title,kind,price,price_per_month,address,sqm,rooms,cover_url,latitude,longitude,neighborhoods(name,name_en)')
    .eq('status', 'active').order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100);
  return (data ?? []) as unknown as HomeListing[];
});

/** "₪3,050,000" */
export function shekels(n: number): string {
  return '₪' + String(Math.trunc(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/** 3.5 reads "3.5", 4.0 reads "4". */
export const roomsText = (r: number) => (Number.isInteger(r) ? String(r) : String(r));
