import { cache } from 'react';
import { db } from '../supabase';
import { isUuid } from '../params';
import type { Lang } from '../i18n';

/** One event as the cards, rows and pins draw it (lib/features/events/models/event.dart). */
export type EventCard = {
  id: string;
  title: string;
  /** `image_url`, else `og_image`, as Event.fromJson reads it. */
  image: string | null;
  start_date: string | null;
  start_time: string | null;
  end_time: string | null;
  is_all_day: boolean;
  venue_name: string | null;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  is_online: boolean;
  is_free: boolean;
  /** "50", never "50.0": a whole price is written without decimals. */
  price: string | null;
  rsvp_count: number;
  published_at: string | null;
  /** When it starts, in milliseconds, on Israel's clock. */
  starts: number | null;
};

export type EventDetail = EventCard & {
  slug: string;
  status: string;
  short_description: string | null;
  full_description: string | null;
  og_image: string | null;
  end_date: string | null;
  waze_url: string | null;
  online_url: string | null;
  ticket_url: string | null;
  is_sold_out: boolean;
  business_id: string | null;
  seo_title: string | null;
  meta_description: string | null;
  meta_keywords: string | null;
  og_title: string | null;
  og_description: string | null;
  noindex: boolean | null;
  updated_at: string | null;
};

export type EventCategory = { id: string; name: string; name_en: string | null; slug: string; image_url: string | null };

const CARD = 'id,title,image_url,og_image,start_date,start_time,end_time,is_all_day,venue_name,address,latitude,longitude,is_online,is_free,price,rsvp_count,published_at';
const DETAIL = CARD + ',slug,status,short_description,full_description,end_date,waze_url,online_url,ticket_url,is_sold_out,business_id,seo_title,meta_description,meta_keywords,og_title,og_description,noindex,updated_at';

type Row = Record<string, unknown>;

/** Israel's offset from UTC, in minutes, at [utcMs]. */
function israelOffset(utcMs: number): number {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Jerusalem', hourCycle: 'h23',
    year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit',
  }).formatToParts(new Date(utcMs));
  const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? 0);
  return Math.round((Date.UTC(get('year'), get('month') - 1, get('day'), get('hour'), get('minute'), get('second')) - utcMs) / 60000);
}

/** A date and a clock time as Israel reads them, as an instant. The table
 *  keeps the two apart, in Israel's time, so they are joined here. */
export function israelInstant(date: string, time?: string | null): number {
  const [y, m, d] = date.slice(0, 10).split('-').map(Number);
  const [h, mi] = (time ?? '').split(':').map((s) => Number(s));
  const wall = Date.UTC(y, m - 1, d, Number.isFinite(h) ? h : 0, Number.isFinite(mi) ? mi : 0);
  let utc = wall - israelOffset(wall) * 60000;
  // Near a clock change the first guess can sit on the other side of it.
  const again = wall - israelOffset(utc) * 60000;
  if (again !== utc) utc = again;
  return utc;
}

/** "2026-12-08T20:30:00+02:00" — for structured data, which wants the offset. */
export function israelIso(date: string, time?: string | null): string {
  const parts = (time ?? '').split(':');
  if (parts.length < 2) return date.slice(0, 10);
  const at = israelInstant(date, time);
  const off = israelOffset(at);
  const sign = off >= 0 ? '+' : '-';
  const two = (n: number) => String(Math.abs(n)).padStart(2, '0');
  return `${date.slice(0, 10)}T${two(Number(parts[0]))}:${two(Number(parts[1]))}:00${sign}${two(Math.trunc(off / 60))}:${two(off % 60)}`;
}

/** `price` is numeric(10,2) and can arrive as 50 or "50.00"; written "50". */
function priceText(v: unknown): string | null {
  if (v == null || v === '') return null;
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? String(n) : String(v);
}

function str(v: unknown): string | null {
  return typeof v === 'string' ? v : null;
}

function toCard(r: Row): EventCard {
  const start = str(r.start_date);
  const num = (v: unknown) => (typeof v === 'number' ? v : v == null ? null : Number(v));
  return {
    id: r.id as string,
    title: (r.title as string) ?? '',
    image: str(r.image_url) || str(r.og_image),
    start_date: start,
    start_time: str(r.start_time),
    end_time: str(r.end_time),
    is_all_day: !!r.is_all_day,
    venue_name: str(r.venue_name),
    address: str(r.address),
    latitude: num(r.latitude),
    longitude: num(r.longitude),
    is_online: !!r.is_online,
    is_free: !!r.is_free,
    price: priceText(r.price),
    rsvp_count: Number(r.rsvp_count ?? 0),
    published_at: str(r.published_at),
    starts: start ? israelInstant(start, str(r.start_time)) : null,
  };
}

/** Whether a pin can go on the map: not online, and with coordinates. */
export function hasCoordinates(e: Pick<EventCard, 'is_online' | 'latitude' | 'longitude'>): boolean {
  return !e.is_online && !!e.latitude && !!e.longitude;
}

/** Events still to come, earliest first — and only those
 *  (upcomingEventsProvider): published rows ordered by start date, without
 *  the ones whose start has passed. An event with no start time counts from
 *  the start of its day, as the app reads it. */
export const upcomingEvents = cache(async (): Promise<EventCard[]> => {
  const { data } = await db.from('events').select(CARD).eq('status', 'published')
    .order('start_date', { ascending: true }).order('start_time', { ascending: true, nullsFirst: true });
  const now = Date.now();
  return ((data ?? []) as Row[]).map(toCard).filter((e) => e.starts == null || e.starts >= now);
});

/** One event by its id, whatever its date — as the app opens it. The
 *  database's own rules decide which statuses a visitor may read. */
export const eventById = cache(async (id: string): Promise<EventDetail | null> => {
  if (!isUuid(id)) return null;
  const { data } = await db.from('events').select(DETAIL).eq('id', id).maybeSingle();
  if (!data) return null;
  const r = data as unknown as Row;
  return {
    ...toCard(r),
    slug: (r.slug as string) ?? '',
    status: (r.status as string) ?? '',
    short_description: str(r.short_description),
    full_description: str(r.full_description),
    og_image: str(r.og_image),
    end_date: str(r.end_date),
    waze_url: str(r.waze_url),
    online_url: str(r.online_url),
    ticket_url: str(r.ticket_url),
    is_sold_out: !!r.is_sold_out,
    business_id: str(r.business_id),
    seo_title: str(r.seo_title),
    meta_description: str(r.meta_description),
    meta_keywords: str(r.meta_keywords),
    og_title: str(r.og_title),
    og_description: str(r.og_description),
    noindex: (r.noindex as boolean | null) ?? null,
    updated_at: str(r.updated_at),
  };
});

/** The event categories, in the editor's order (eventCategoriesProvider). */
export const eventCategories = cache(async (): Promise<EventCategory[]> => {
  const { data } = await db.from('categories').select('id,name,name_en,slug,image_url')
    .eq('scope', 'event').eq('is_active', true).order('sort_order', { ascending: true });
  return (data ?? []) as EventCategory[];
});

/** Each event's categories, keyed by event id, the primary one first
 *  (eventCategoriesByEventProvider). An event filed nowhere has none. */
export const eventCategoryLinks = cache(async (): Promise<Record<string, EventCategory[]>> => {
  const [categories, { data }] = await Promise.all([
    eventCategories(),
    db.from('entity_categories').select('entity_id,category_id,is_primary').eq('entity_type', 'event'),
  ]);
  const byId = new Map(categories.map((c) => [c.id, c]));
  const links = ((data ?? []) as { entity_id: string; category_id: string; is_primary: boolean | null }[])
    .map((l, i) => ({ ...l, i }))
    .sort((a, b) => (a.is_primary ? 0 : 1) - (b.is_primary ? 0 : 1) || a.i - b.i);
  const out: Record<string, EventCategory[]> = {};
  for (const l of links) {
    const c = byId.get(l.category_id);
    if (c) (out[l.entity_id] ??= []).push(c);
  }
  return out;
});

export type EventOrganizer = { slug: string; name: string; logo: string | null; subtitle: string | null };

/** Who is putting the event on (eventOrganizerProvider): the business named
 *  by `business_id`, with the category it is filed under — the most specific
 *  one in the menus — or its short description beneath its name. */
export async function eventOrganizer(businessId: string | null, lang: Lang): Promise<EventOrganizer | null> {
  if (!businessId || !isUuid(businessId)) return null;
  const [{ data: b }, { data: links }] = await Promise.all([
    db.from('businesses').select('id,slug,name,name_en,logo_url,cover_url,short_description').eq('id', businessId).maybeSingle(),
    db.from('entity_categories').select('categories(name,name_en,parent_id,in_menus,scope)')
      .eq('entity_type', 'business').eq('entity_id', businessId),
  ]);
  if (!b) return null;
  type Cat = { name: string; name_en: string | null; parent_id: string | null; in_menus: boolean | null; scope: string };
  let kind: Cat | null = null;
  for (const l of (links ?? []) as unknown as { categories: Cat | null }[]) {
    const c = l.categories;
    if (!c || c.scope !== 'business' || c.in_menus === false) continue;
    if (!kind || (kind.parent_id == null && c.parent_id != null)) kind = c;
  }
  const local = (he: string, en: string | null | undefined) => (lang === 'en' && en?.trim() ? en : he);
  const kindName = kind ? local(kind.name, kind.name_en) : null;
  const about = (b.short_description as string | null)?.trim() || null;
  return {
    slug: b.slug as string,
    name: local(b.name as string, b.name_en as string | null),
    logo: (b.logo_url as string | null) || (b.cover_url as string | null),
    subtitle: kindName || about,
  };
}
