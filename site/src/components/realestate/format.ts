import type { Lang } from '@/lib/i18n';
import type { ContactOption } from './Menus';
import { localName, type Listing, type ListingKind, type PropertyType } from '@/lib/data/realestate';

// Small things every real estate card and page says the same way, as the
// app's screens say them (web_realestate_screen.dart, web_detail_parts.dart).

/** ₪2,450,000 — grouped in threes (formatShekels). */
export function shekels(n: number): string {
  return '₪' + String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

/** Whichever of the two prices applies; null when the listing carries none,
 *  which is "price on request", not free. */
export function priceOf(l: Pick<Listing, 'kind' | 'price' | 'price_per_month'>): number | null {
  return l.kind === 'rent' ? l.price_per_month : l.price;
}

/** Half rooms are normal here: 3.5 prints as 3.5, 4.0 as 4. */
export function roomsText(r: number): string {
  return String(r);
}

/** Posted in the last fortnight — the app's own rule for the "New" badge. */
export function isNew(l: Pick<Listing, 'created_at'>): boolean {
  return (Date.now() - new Date(l.created_at).getTime()) / 86_400_000 < 14;
}

export function hoodName(l: Pick<Listing, 'neighborhoods'>, lang: Lang): string | null {
  const h = l.neighborhoods;
  return h ? localName(h.name, h.name_en, lang) : null;
}

export function typeLabel(t: PropertyType, lang: Lang): string {
  const he = lang === 'he';
  switch (t) {
    case 'apartment': return he ? 'דירה' : 'Apartment';
    case 'penthouse': return he ? 'פנטהאוז' : 'Penthouse';
    case 'garden': return he ? 'דירת גן' : 'Garden Apartment';
    case 'duplex': return he ? 'דופלקס' : 'Duplex';
    case 'villa': return he ? 'וילה' : 'Villa';
    case 'studio': return he ? 'סטודיו' : 'Studio';
    default: return he ? 'אחר' : 'Other';
  }
}

/** The six types a reader picks from, with the design's line drawing.
 *  `other` is what the model falls back to, not a choice. */
export const BROWSE_TYPES: [PropertyType, string][] = [
  ['apartment', '/web/realestate/type_apartment.svg'],
  ['penthouse', '/web/realestate/type_penthouse.svg'],
  ['garden', '/web/realestate/type_garden.svg'],
  ['duplex', '/web/realestate/type_duplex.svg'],
  ['villa', '/web/realestate/type_villa.svg'],
  ['studio', '/web/realestate/type_studio.svg'],
];

export function kindLabel(k: ListingKind, lang: Lang, caps = true): string {
  if (lang === 'he') return k === 'rent' ? 'להשכרה' : 'למכירה';
  if (caps) return k === 'rent' ? 'FOR RENT' : 'FOR SALE';
  return k === 'rent' ? 'For Rent' : 'For Sale';
}

/** The ways to reach a listing's advertiser, as the menus list them: the
 *  number (Call), Copy number, WhatsApp, e-mail. */
export function contactOptions(c: { phone?: string | null; whatsapp?: string | null; email?: string | null }, lang: Lang, copy = true): ContactOption[] {
  const out: ContactOption[] = [];
  const phone = c.phone?.trim();
  const tel = phone?.replace(/[^\d+]/g, '');
  if (phone && tel) {
    out.push({ kind: 'phone', label: phone, href: `tel:${tel}` });
    if (copy) out.push({ kind: 'copy', label: lang === 'he' ? 'העתקת המספר' : 'Copy number', href: phone, done: lang === 'he' ? 'המספר הועתק' : 'Number copied' });
  }
  let wa = (c.whatsapp ?? '').replace(/\D/g, '');
  if (wa.startsWith('0')) wa = '972' + wa.slice(1);
  if (wa.length >= 9) out.push({ kind: 'whatsapp', label: 'WhatsApp', href: `https://wa.me/${wa}` });
  const mail = c.email?.trim();
  if (mail) out.push({ kind: 'email', label: mail, href: `mailto:${mail}` });
  return out;
}

/** A photo from our storage at about the size it is drawn (sizedPhotoUrl in
 *  network_photo.dart): storage resizes on the way out, so a 380-wide card
 *  asks for an 800-wide copy rather than the 4 MB original. Anything else
 *  is left as it is. */
export function photo(url: string, width: number): string {
  const stored = '/storage/v1/object/public/';
  if (!url.includes('.supabase.co' + stored)) return url;
  const path = url.split('?')[0].toLowerCase();
  if (!/\.(jpe?g|png|webp)$/.test(path)) return url;
  const px = width * 2;
  const step = [200, 400, 600, 800, 1200, 1600, 2000, 2500].find((s) => s >= px) ?? 2500;
  return url.replace(stored, '/storage/v1/render/image/public/') + (url.includes('?') ? '&' : '?')
    + `width=${step}&height=2500&resize=contain&quality=75`;
}

/** A description as the client wrote it, one entry per paragraph. */
export function paragraphs(text: string | null | undefined): string[] {
  return (text ?? '').split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
}
