import type { Lang } from '../i18n';

// What the Municipal pages share with their interactive parts in the
// browser: the tiles' categories and their names, without the database.

/** The Municipal page's tiles that list places, and the categories each
 *  shows (MunicipalSection in municipal_place.dart). */
export const MUNICIPAL_SECTIONS = {
  institutions: ['institution', 'synagogue'],
  health: ['health'],
  education: ['school', 'kindergarten'],
  transport: ['train_station', 'bus_stop'],
  emergency: ['emergency'],
} as const;

export type MunicipalSection = keyof typeof MUNICIPAL_SECTIONS;

export function isMunicipalSection(s: string): s is MunicipalSection {
  return Object.prototype.hasOwnProperty.call(MUNICIPAL_SECTIONS, s);
}

/** The categories a place can be filed under, in the order the pages list
 *  them (kMunicipalCategories). */
export const MUNICIPAL_CATEGORIES: [string, { he: string; en: string }][] = [
  ['institution', { he: 'מוסדות ציבור', en: 'Public institutions' }],
  ['synagogue', { he: 'בתי כנסת', en: 'Synagogues' }],
  ['health', { he: 'מרפאות ובריאות', en: 'Clinics & health' }],
  ['school', { he: 'בתי ספר', en: 'Schools' }],
  ['kindergarten', { he: 'גני ילדים', en: 'Kindergartens' }],
  ['train_station', { he: 'תחנות רכבת', en: 'Train stations' }],
  ['bus_stop', { he: 'תחנות אוטובוס', en: 'Bus stops' }],
  ['emergency', { he: 'מספרי חירום', en: 'Emergency numbers' }],
];

export type MunicipalPlace = {
  id: string; category: string; name: string; name_en: string | null;
  address: string | null; phone: string | null; notes: string | null;
  latitude: number | null; longitude: number | null; source: string | null;
};

/** The English name where one is set, the Hebrew one otherwise. */
export function placeName(p: Pick<MunicipalPlace, 'name' | 'name_en'>, lang: Lang): string {
  return lang === 'en' && p.name_en ? p.name_en : p.name;
}


/** A car park the client entered in the panel (חניונים, migration 00030).
 *  A field left empty is null, so the pages leave it out. */
export type ParkingLot = {
  id: string; name: string; name_en: string | null; address: string | null; hours: string | null;
  price_note: string | null; is_free: boolean | null; capacity: number | null; notes: string | null;
  image_url: string | null; latitude: number; longitude: number; google_place_id: string | null;
};

export function lotName(lot: Pick<ParkingLot, 'name' | 'name_en'>, lang: Lang): string {
  return lang === 'en' && lot.name_en ? lot.name_en : lot.name;
}

/** Waze, which people here drive with, to the car park's point. */
export function wazeUrl(lat: number, lng: number): string {
  return `https://waze.com/ul?ll=${lat},${lng}&navigate=yes`;
}

/** Directions in Google Maps — to the place itself when Google lists it. */
export function googleMapsUrl(lot: Pick<ParkingLot, 'latitude' | 'longitude' | 'google_place_id'>): string {
  return `https://www.google.com/maps/dir/?api=1&destination=${lot.latitude},${lot.longitude}`
    + (lot.google_place_id ? `&destination_place_id=${lot.google_place_id}` : '');
}
