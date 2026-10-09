import { cache } from 'react';
import { db } from '../supabase';
import { MUNICIPAL_SECTIONS, type MunicipalPlace, type MunicipalSection, type ParkingLot } from './municipal-shared';

export * from './municipal-shared';

// The Municipal page's data (lib/features/municipal): the places behind its
// service tiles, the municipality's forms link and the city's car parks —
// all of them the client's, from the panel.

const text = (v: string | null | undefined) => (v ?? '').trim() || null;

/** The shown places on one tile, in the panel's order and then by name. Row
 *  security returns only the shown ones to the public. */
export const municipalPlaces = cache(async (section: MunicipalSection): Promise<MunicipalPlace[]> => {
  const { data } = await db.from('municipal_places')
    .select('id,category,name,name_en,address,phone,notes,latitude,longitude,source')
    .in('category', [...MUNICIPAL_SECTIONS[section]])
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .order('name', { ascending: true })
    .limit(2000);
  return ((data ?? []) as MunicipalPlace[]).map((p) => ({
    ...p, name: (p.name ?? '').trim(), name_en: text(p.name_en), address: text(p.address),
    phone: text(p.phone), notes: text(p.notes),
  }));
});

/** The municipality's own forms page — "טפסים, הנחיות, חוקים ותקנות" — which
 *  the Forms tile opens, as the client chose (30 Sep). */
export const MUNICIPAL_FORMS_URL = 'https://www.modiin.muni.il/modiinwebsite/ChannelArticle.aspx?PageID=51_108';

/** The forms link the client set in the panel (Remote Config
 *  `municipal_forms_url`), else the municipality's page. */
export async function municipalFormsUrl(): Promise<string> {
  try {
    const { data } = await db.from('remote_config').select('value').eq('key', 'municipal_forms_url').maybeSingle();
    const set = String(data?.value ?? '').trim();
    if (set.startsWith('http')) return set;
  } catch { /* the municipality's own page */ }
  return MUNICIPAL_FORMS_URL;
}

/** The lots the client has entered and not hidden, in his order. A failed
 *  read fails the page (lib/supabase.ts), not "no car parks yet". */
export const parkingLots = cache(async (): Promise<ParkingLot[]> => {
  const { data } = await db.from('parking_lots')
    .select('id,name,name_en,address,hours,price_note,is_free,capacity,notes,latitude,longitude,image_url,google_place_id')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .order('name', { ascending: true });
  return ((data ?? []) as ParkingLot[]).map((r) => ({
    ...r, name_en: text(r.name_en), address: text(r.address), hours: text(r.hours), price_note: text(r.price_note),
    notes: text(r.notes), image_url: text(r.image_url), google_place_id: text(r.google_place_id),
    latitude: Number(r.latitude), longitude: Number(r.longitude),
  }));
});

export async function parkingLot(id: string): Promise<ParkingLot | null> {
  return (await parkingLots()).find((l) => l.id === id) ?? null;
}
