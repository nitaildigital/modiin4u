import { db } from '../supabase';
import type { Lang } from '../i18n';
import { href, plain } from '../seo';
import { parkingLots, lotName } from './municipal';
import { LAYER_LOOK, type CityPin } from './map-shared';

export * from './map-shared';

// Every pin on the city map (map_providers.dart): the active businesses, the
// published events, the active property listings and the car parks — each
// with what the pin's card shows (web_map_screen.dart, "Apartment Slide"),
// filled from its own row and only where the row has something to say.

type Biz = {
  id: string; slug: string | null; name: string; name_en: string | null; short_description: string | null;
  address: string | null; latitude: number | null; longitude: number | null; cover_url: string | null;
  og_image_url: string | null; rating: number | null; review_count: number | null;
  neighborhoods: { name: string | null; name_en: string | null } | null;
};
type Cat = { id: string; name: string; name_en: string | null; parent_id: string | null; in_menus: boolean | null };
type Ev = {
  id: string; slug: string | null; title: string; short_description: string | null; image_url: string | null;
  start_time: string | null; is_all_day: boolean | null; venue_name: string | null; address: string | null;
  latitude: number | null; longitude: number | null; is_free: boolean | null; price: number | string | null; rsvp_count: number | null;
};
type Listing = {
  id: string; slug: string | null; title: string; description: string | null; kind: string; property_type: string | null;
  rooms: number | null; floor: number | null; total_floors: number | null; sqm: number | null; price: number | null;
  price_per_month: number | null; address: string | null; latitude: number | null; longitude: number | null;
  cover_url: string | null; gallery: string[] | null; neighborhoods: { name: string | null; name_en: string | null } | null;
};

const local = (he: string | null | undefined, en: string | null | undefined, lang: Lang) =>
  (lang === 'en' && en?.trim() ? en.trim() : he ?? '') || '';

/** "₪3,650,000" (formatShekels). */
export function shekels(amount: number): string {
  return '₪' + String(Math.round(amount)).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/** 3.5 rooms stays 3.5; 3.0 prints as 3. */
const roomsText = (v: number) => String(Number(v));

/** The category each business is filed under — its most specific one shown
 *  in the menus (businessPrimaryCategoryProvider). */
async function businessKinds(lang: Lang): Promise<Record<string, string>> {
  const [{ data: cats }, { data: links }] = await Promise.all([
    db.from('categories').select('id,name,name_en,parent_id,in_menus').eq('scope', 'business').eq('is_active', true),
    db.from('entity_categories').select('entity_id,category_id').eq('entity_type', 'business').limit(10000),
  ]);
  const byId = new Map(((cats ?? []) as Cat[]).map((c) => [c.id, c]));
  const chosen = new Map<string, Cat>();
  for (const l of links ?? []) {
    const c = byId.get(l.category_id as string);
    if (!c || c.in_menus === false) continue;
    const id = l.entity_id as string;
    const have = chosen.get(id);
    if (!have || (have.parent_id == null && c.parent_id != null)) chosen.set(id, c);
  }
  return Object.fromEntries([...chosen].map(([id, c]) => [id, local(c.name, c.name_en, lang)]));
}

export async function cityPins(lang: Lang): Promise<CityPin[]> {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [bizRes, longRes, evRes, lsRes, lots, kinds] = await Promise.all([
    db.from('businesses')
      .select('id,slug,name,name_en,short_description,address,latitude,longitude,cover_url,og_image_url,rating,review_count,neighborhoods!businesses_neighborhood_id_fkey(name,name_en)')
      .eq('status', 'active').eq('kind', 'business').limit(5000),
    // The few with no one-line description fall back to the long one, as
    // the app's model does; read only for them.
    db.from('businesses').select('id,full_description').eq('status', 'active').eq('kind', 'business').is('short_description', null),
    db.from('events')
      .select('id,slug,title,short_description,image_url,start_time,is_all_day,venue_name,address,latitude,longitude,is_free,price,rsvp_count')
      .eq('status', 'published').order('start_date', { ascending: true }),
    db.from('listings')
      .select('id,slug,title,description,kind,property_type,rooms,floor,total_floors,sqm,price,price_per_month,address,latitude,longitude,cover_url,gallery,neighborhoods(name,name_en)')
      .eq('status', 'active').order('is_featured', { ascending: false }).order('created_at', { ascending: false }).limit(100),
    parkingLots(),
    businessKinds(lang),
  ]);
  const longText = new Map((longRes.data ?? []).map((r) => [r.id as string, plain(r.full_description as string | null)]));
  const pins: CityPin[] = [];

  for (const b of (bizRes.data ?? []) as unknown as Biz[]) {
    const lat = Number(b.latitude ?? 0), lng = Number(b.longitude ?? 0);
    // A pin needs coordinates; the seed leaves some at 0,0.
    if (!lat || !lng) continue;
    const name = local(b.name, b.name_en, lang);
    const description = b.short_description?.trim() || longText.get(b.id) || null;
    const kind = kinds[b.id] || description || t('עסק', 'Business');
    const address = b.address?.trim() || local(b.neighborhoods?.name, b.neighborhoods?.name_en, lang) || null;
    const rating = b.rating ? Number(b.rating) : null;
    const reviews = b.review_count ? Number(b.review_count) : null;
    const photo = b.cover_url || b.og_image_url;
    pins.push({
      id: 'b-' + b.id, layer: 'Businesses', lat, lng,
      search: [name, kind, address ?? ''].join(' ').toLowerCase(),
      slide: {
        photos: photo ? [photo] : [],
        badge: kind, badgeColor: LAYER_LOOK.Businesses.color, badgeIcon: LAYER_LOOK.Businesses.icon,
        headline: name, perMonth: null,
        tag: rating == null ? null : `★ ${rating}`,
        facts: [kind, ...(reviews != null ? [t(`${reviews} ביקורות`, `${reviews} reviews`)] : [])],
        address,
        aboutTitle: t('על העסק', 'About This Business'),
        about: description,
        details: [
          [t('קטגוריה', 'Category'), kind],
          ...(rating != null ? [[t('דירוג', 'Rating'), rating.toFixed(1)] as [string, string]] : []),
          ...(reviews != null ? [[t('ביקורות', 'Reviews'), String(reviews)] as [string, string]] : []),
        ],
        route: href(`/business/${b.slug || b.id}/`),
      },
    });
  }

  for (const e of (evRes.data ?? []) as Ev[]) {
    const lat = Number(e.latitude ?? 0), lng = Number(e.longitude ?? 0);
    if (!lat || !lng) continue;
    const parts = (e.start_time ?? '').split(':');
    const time = e.is_all_day || parts.length < 2 ? null : `${parts[0]}:${parts[1]}`;
    const amount = e.price == null || e.price === '' ? null : Number(e.price);
    const price = e.is_free ? t('חינם', 'Free')
      : amount == null || Number.isNaN(amount) ? null
      : `₪${amount}`;
    const venue = e.venue_name?.trim() || null;
    const address = e.address?.trim() || venue;
    const interested = Number(e.rsvp_count ?? 0);
    pins.push({
      id: 'e-' + e.id, layer: 'Events', lat, lng,
      search: [e.title, t('אירוע', 'Event'), address ?? ''].join(' ').toLowerCase(),
      slide: {
        photos: e.image_url ? [e.image_url] : [],
        badge: t('אירוע', 'Event'), badgeColor: LAYER_LOOK.Events.color, badgeIcon: LAYER_LOOK.Events.icon,
        headline: e.title, perMonth: null, tag: price,
        facts: [t('אירוע', 'Event'), ...(time ? [time] : []), t(`${interested} מתעניינים`, `${interested} interested`)],
        address,
        aboutTitle: t('על האירוע', 'About This Event'),
        about: e.short_description?.trim() || null,
        details: [
          [t('קטגוריה', 'Category'), t('אירוע', 'Event')],
          ...(venue ? [[t('מיקום', 'Venue'), venue] as [string, string]] : []),
          ...(time ? [[t('שעה', 'Time'), time] as [string, string]] : []),
          ...(price ? [[t('מחיר', 'Price'), price] as [string, string]] : []),
        ],
        route: href(`/event/${e.id}/`),
      },
    });
  }

  const typeName: Record<string, [string, string]> = {
    apartment: ['דירה', 'Apartment'], penthouse: ['פנטהאוז', 'Penthouse'], garden: ['דירת גן', 'Garden Apartment'],
    duplex: ['דופלקס', 'Duplex'], villa: ['וילה', 'Villa'], studio: ['סטודיו', 'Studio'],
  };
  for (const l of (lsRes.data ?? []) as unknown as Listing[]) {
    if (l.latitude == null || l.longitude == null) continue;
    const [typeHe, typeEn] = typeName[l.property_type ?? ''] ?? ['נכס', 'Property'];
    const type = t(typeHe, typeEn);
    const rent = l.kind === 'rent';
    const price = rent ? l.price_per_month : l.price;
    const storey = l.floor === 0 ? t('קרקע', 'Ground') : String(l.floor);
    const floor = l.floor == null ? null : l.total_floors == null ? storey : `${storey} / ${l.total_floors}`;
    const gallery = (l.gallery ?? []).filter((g) => g && g !== l.cover_url);
    const neighborhood = l.neighborhoods ? local(l.neighborhoods.name, l.neighborhoods.name_en, lang) : null;
    const address = l.address?.trim() || neighborhood || null;
    pins.push({
      id: 'l-' + l.id, layer: 'Real Estate', lat: Number(l.latitude), lng: Number(l.longitude),
      search: [price != null ? shekels(price) : l.title, neighborhood ?? '', address ?? ''].join(' ').toLowerCase(),
      slide: {
        photos: [...(l.cover_url ? [l.cover_url] : []), ...gallery],
        badge: type, badgeColor: LAYER_LOOK['Real Estate'].color, badgeIcon: '/web/map/slide_badge.svg',
        // A listing with no price is not a free one.
        headline: price == null ? t('מחיר לפי בקשה', 'Price on request') : shekels(price),
        perMonth: price != null && rent ? t('/ לחודש', '/ month') : null,
        tag: rent ? t('להשכרה', 'FOR RENT') : t('למכירה', 'FOR SALE'),
        facts: [
          ...(l.rooms != null ? [l.rooms === 1 ? t('חדר 1', '1 Room') : t(`${roomsText(l.rooms)} חדרים`, `${roomsText(l.rooms)} Rooms`)] : []),
          ...(l.sqm != null ? [t(`${l.sqm} מ״ר`, `${l.sqm} m²`)] : []),
          ...(l.floor != null ? [l.floor === 0 ? t('קומת קרקע', 'Ground Floor') : t(`קומה ${l.floor}`, `Floor ${l.floor}`)] : []),
        ],
        address,
        aboutTitle: t('על הנכס', 'About This Property'),
        about: l.description?.trim() || null,
        details: [
          [t('סוג נכס', 'Property Type'), type],
          ...(l.rooms != null ? [[t('חדרים', 'Rooms'), roomsText(l.rooms)] as [string, string]] : []),
          ...(floor ? [[t('קומה', 'Floor'), floor] as [string, string]] : []),
          ...(l.sqm != null ? [[t('שטח', 'Size'), t(`${l.sqm} מ״ר`, `${l.sqm} m²`)] as [string, string]] : []),
        ],
        route: href(`/listing/${l.id}/`),
      },
    });
  }

  for (const lot of lots) {
    const price = lot.is_free === true ? t('חינם', 'Free') : lot.price_note;
    const spaces = lot.capacity == null ? null : t(`${lot.capacity} מקומות`, `${lot.capacity} spaces`);
    pins.push({
      id: 'p-' + lot.id, layer: 'Parkings', lat: lot.latitude, lng: lot.longitude,
      search: [lot.name, lot.name_en ?? '', lot.address ?? ''].join(' ').toLowerCase(),
      slide: {
        photos: lot.image_url ? [lot.image_url] : [],
        badge: t('חניון', 'Car park'), badgeColor: LAYER_LOOK.Parkings.color, badgeIcon: null,
        headline: lotName(lot, lang), perMonth: null, tag: price,
        facts: [...(spaces ? [spaces] : []), ...(lot.hours ? [lot.hours] : [])],
        address: lot.address,
        aboutTitle: t('על החניון', 'About This Car Park'),
        about: lot.notes,
        details: [
          ...(lot.hours ? [[t('שעות', 'Hours'), lot.hours] as [string, string]] : []),
          ...(price ? [[t('מחיר', 'Price'), price] as [string, string]] : []),
          ...(lot.capacity != null ? [[t('מקומות', 'Spaces'), String(lot.capacity)] as [string, string]] : []),
        ],
        // Its own page: Waze, Google Maps and what Google knows about it.
        route: href(`/parking/${lot.id}/`),
        waze: `https://waze.com/ul?ll=${lot.latitude},${lot.longitude}&navigate=yes`,
      },
    });
  }
  return pins;
}
