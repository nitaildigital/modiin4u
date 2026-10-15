// How a visitor reaches a place: its number, to show and to dial, its
// WhatsApp, and the way there.
//
// Text copied from a right-to-left page brings invisible direction marks
// with it (U+2066 … U+2069 around it, U+200E/U+200F, U+202A … U+202E): one
// business's number reached the page as "522071905⁩0", garbled on screen and
// in its `tel:` link, and some addresses carry them too. Each helper takes
// the marks out first; the digits and words stay exactly as stored.

/** The direction, isolate and zero-width marks, and the BOM. */
const MARKS = /[؜​-‏‪-‮⁠-⁩﻿]/g;

/** [raw] without the invisible marks, trimmed; '' for none. */
export function withoutMarks(raw: string | null | undefined): string {
  return (raw ?? '').replace(MARKS, '').trim();
}

/** The number as typed, without the invisible marks; '' for none. */
export const shownPhone = withoutMarks;

/** What a `tel:` link takes: the digits, after a + or a * where the number
 *  starts with one (Israel's short numbers, "*3304", are dialled with the
 *  star; "106" and "1230" are numbers too). Null when it has no digits to
 *  dial. */
export function telNumber(raw: string | null | undefined): string | null {
  const s = withoutMarks(raw);
  const digits = s.replace(/\D/g, '');
  if (digits.length < 3) return null;
  const lead = /^[+*]/.exec(s)?.[0] ?? '';
  return lead + digits;
}

/** A number as wa.me takes it: digits only, Israel's 972 in place of a
 *  leading 0. Null when too short to be a mobile number. */
export function waNumber(raw: string | null | undefined): string | null {
  let d = withoutMarks(raw).replace(/\D/g, '');
  if (d.startsWith('0')) d = '972' + d.slice(1);
  return d.length >= 9 ? d : null;
}

/** An address that names only the city — a handful of rows hold just
 *  "מודיעין" — says nothing about where the place is. */
const CITY_ONLY = /^(מודיעין([\s-]+מכבים[\s-]+רעות)?|modi'?in([\s-]+maccabim[\s-]+reut)?)(\s*,\s*(ישראל|israel))?$/i;

/** Directions on Google Maps — the client's choice of maps — to the place's
 *  point, or, without one, to its street address, in Modi'in unless the
 *  address names its own town. Null when the row has neither: sent to the
 *  city's centre, a visitor would be lost rather than helped. */
export function directionsUrl(p: { latitude?: number | null; longitude?: number | null; address?: string | null }): string | null {
  const base = 'https://www.google.com/maps/dir/?api=1&destination=';
  if (p.latitude && p.longitude) return `${base}${p.latitude},${p.longitude}`;
  const address = withoutMarks(p.address);
  if (!address || CITY_ONLY.test(address)) return null;
  const town = /מודיעין|ישראל|modi'?in|israel/i.test(address) ? address : `${address}, מודיעין`;
  return base + encodeURIComponent(town);
}
