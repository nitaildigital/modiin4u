import type { Lang } from '@/lib/i18n';
import type { EventCard, EventCategory } from '@/lib/data/events';

// How an event's date, time, price and category read, in either language
// (lib/features/events/models/event_labels.dart). Plain functions, so the
// server pages and the interactive lists print them the same way.

const MONTHS_EN = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const MONTHS_HE = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];
const SHORT_HE = ['ינו׳', 'פבר׳', 'מרץ', 'אפר׳', 'מאי', 'יוני', 'יולי', 'אוג׳', 'ספט׳', 'אוק׳', 'נוב׳', 'דצמ׳'];
// Sunday first, as Date.getUTCDay counts.
const WEEKDAYS_EN = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const WEEKDAYS_HE = ['יום ראשון', 'יום שני', 'יום שלישי', 'יום רביעי', 'יום חמישי', 'יום שישי', 'שבת'];

function ymd(date: string) {
  const [y, m, d] = date.slice(0, 10).split('-').map(Number);
  return { y, m, d };
}

/** "OCT" / "אוק׳" on a date badge. */
export function shortMonth(date: string, lang: Lang): string {
  const { m } = ymd(date);
  return lang === 'he' ? SHORT_HE[m - 1] : MONTHS_EN[m - 1].slice(0, 3).toUpperCase();
}

/** The day of the month: "08" on the website's badges, "8" on the phone's. */
export function dayOfMonth(date: string, pad = true): string {
  const { d } = ymd(date);
  return pad ? String(d).padStart(2, '0') : String(d);
}

/** "Tuesday, December 8, 2026" / "יום שלישי, 8 בדצמבר 2026". */
export function longDate(date: string, lang: Lang): string {
  const { y, m, d } = ymd(date);
  const weekday = (lang === 'he' ? WEEKDAYS_HE : WEEKDAYS_EN)[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
  return lang === 'he' ? `${weekday}, ${d} ב${MONTHS_HE[m - 1]} ${y}` : `${weekday}, ${MONTHS_EN[m - 1]} ${d}, ${y}`;
}

/** "8:00 PM" in English, "20:00" in Hebrew, from a `time` column value. */
function clock(value: string | null, lang: Lang): string | null {
  const parts = (value ?? '').split(':');
  if (parts.length < 2) return null;
  const h = Number(parts[0]);
  const m = Number(parts[1]);
  if (!Number.isFinite(h) || !Number.isFinite(m)) return null;
  const mm = String(m).padStart(2, '0');
  if (lang === 'he') return `${String(h).padStart(2, '0')}:${mm}`;
  // A no-break space, so a narrow cell breaks a range at its dash.
  return `${h % 12 === 0 ? 12 : h % 12}:${mm} ${h < 12 ? 'AM' : 'PM'}`;
}

type Timed = Pick<EventCard, 'is_all_day' | 'start_time' | 'end_time'>;

/** When it starts, as a card shows it; null when the row has no time. */
export function startTime(e: Timed, lang: Lang): string | null {
  if (e.is_all_day) return lang === 'he' ? 'כל היום' : 'All day';
  return clock(e.start_time, lang);
}

/** "8:30 PM – 11:00 PM", or just the start when there is no end. */
export function timeRange(e: Timed, lang: Lang): string | null {
  if (e.is_all_day) return lang === 'he' ? 'כל היום' : 'All day';
  const start = clock(e.start_time, lang);
  if (!start) return null;
  const end = clock(e.end_time, lang);
  return end ? `${start} – ${end}` : start;
}

/** "₪50", or "FREE" — capitals on the cards and rows, "Free" in the detail
 *  box. Null when the row says neither. */
export function eventPrice(e: Pick<EventCard, 'is_free' | 'price'>, lang: Lang, upper = true): string | null {
  if (e.is_free) return lang === 'he' ? 'חינם' : upper ? 'FREE' : 'Free';
  const p = e.price;
  if (!p) return null;
  return p.startsWith('₪') ? p : `₪${p}`;
}

type Placed = Pick<EventCard, 'is_online' | 'venue_name' | 'address'>;

/** Where it is, short: the venue, else the address. */
export function venue(e: Placed, lang: Lang): string | null {
  if (e.is_online) return lang === 'he' ? 'אונליין' : 'Online';
  return e.venue_name?.trim() || e.address?.trim() || null;
}

/** Where it is, in full: the address, else the venue. */
export function address(e: Placed, lang: Lang): string | null {
  if (e.is_online) return lang === 'he' ? 'אונליין' : 'Online';
  return e.address?.trim() || e.venue_name?.trim() || null;
}

/** "124 people interested". */
export function peopleInterested(n: number, lang: Lang): string {
  if (n === 1) return lang === 'he' ? '1 מתעניין' : '1 person interested';
  return lang === 'he' ? `${n} מתעניינים` : `${n} people interested`;
}

/** "86 interested" on a card. */
export function interested(n: number, lang: Lang): string {
  return lang === 'he' ? `${n} מתעניינים` : `${n} interested`;
}

// The design's English words for the categories it draws, by slug; the
// panel's English name, else the Hebrew one, for the rest.
const ENGLISH_CATEGORY: Record<string, string> = {
  concerts: 'Music', music: 'Music',
  community: 'Municipal & Community', 'municipal-community': 'Municipal & Community',
  kids: 'Kids & Family', 'kids-family': 'Kids & Family',
  'sports-events': 'Sports', sports: 'Sports',
  workshops: 'Workshops', 'food-drink': 'Food & Drink',
};

export function categoryLabel(c: Pick<EventCategory, 'name' | 'name_en' | 'slug'>, lang: Lang): string {
  if (lang === 'he') return c.name;
  return ENGLISH_CATEGORY[c.slug] ?? (c.name_en?.trim() || c.name);
}

/** An event's description, split as the event page lays it out: paragraphs
 *  under "About This Event", and the "•" list editors write under a line
 *  reading "מה כלול:" drawn as the "What's Included" checklist
 *  (EventDescription in event_labels.dart). */
export function parseDescription(text: string | null | undefined): { paragraphs: string[]; included: string[] } {
  const heading = /^(מה כלול|מה כלול באירוע|what'?s included|what is included)\s*:?\s*$/i;
  const bullet = /^[•·\-*–]\s*/;
  const paragraphs: string[] = [];
  const included: string[] = [];
  for (const block of (text ?? '').split(/\n\s*\n/)) {
    const lines = block.split('\n').map((l) => l.trim()).filter(Boolean);
    if (!lines.length) continue;
    const rest = lines.slice(1);
    if (!included.length && heading.test(lines[0]) && rest.length && rest.every((l) => bullet.test(l))) {
      included.push(...rest.map((l) => l.replace(bullet, '')));
      continue;
    }
    paragraphs.push(lines.join('\n'));
  }
  return { paragraphs, included };
}
