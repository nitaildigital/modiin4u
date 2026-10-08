import type { Lang } from '@/lib/i18n';
import type { Business } from '@/lib/data/business';

const HEBREW = /[֐-׿]/;

/** Text from the directory reads in its own direction, whatever the page
 *  does: Hebrew right to left, anything else left to right. */
export function dirOf(s: string): 'rtl' | 'ltr' {
  return HEBREW.test(s) ? 'rtl' : 'ltr';
}

/** Two letters for an avatar, from the first two names. */
export function initials(name: string): string {
  const parts = name.trim().split(/\s+/);
  if (parts.length >= 2 && parts[0] && parts[1]) return parts[0][0] + parts[1][0];
  return name ? name[0] : '?';
}

const HE_MONTHS = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];
const EN_MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

/** "12 בספטמבר 2026" / "September 12, 2026", as the review rows print it,
 *  on Israel's calendar. */
export function reviewDate(iso: string | null | undefined, lang: Lang): string {
  if (!iso) return '';
  const parts = new Intl.DateTimeFormat('en-GB', { timeZone: 'Asia/Jerusalem', day: 'numeric', month: 'numeric', year: 'numeric' })
    .formatToParts(new Date(iso));
  const get = (t: string) => Number(parts.find((p) => p.type === t)?.value ?? 0);
  const d = get('day'), m = get('month'), y = get('year');
  if (!m) return '';
  return lang === 'he' ? `${d} ב${HE_MONTHS[m - 1]} ${y}` : `${EN_MONTHS[m - 1]} ${d}, ${y}`;
}

/** The kosher certificate as it reads on screen, or null for none. */
export function kosherLabel(level: string | null): string | null {
  switch (level) {
    case 'rabbanut': return 'רבנות';
    case 'mehadrin': return 'מהדרין';
    case 'badatz': return 'בד״ץ';
    case 'other': return 'כשר';
    default: return null;
  }
}

/** What the row says the place offers — only the true ones. */
export function highlights(b: Business, t: (he: string, en: string) => string): string[] {
  return [
    kosherLabel(b.kosher_level) ? t('כשר', 'Kosher') : null,
    b.has_delivery ? t('משלוחים', 'Delivery') : null,
    b.has_outdoor ? t('ישיבה בחוץ', 'Outdoor seating') : null,
    b.is_accessible ? t('נגיש', 'Accessible') : null,
    b.has_parking ? t('חניה', 'Parking') : null,
    b.pet_friendly ? t('ידידותי לחיות מחמד', 'Pet friendly') : null,
    b.open_on_shabbat ? t('פתוח בשבת', 'Open on Shabbat') : null,
  ].filter((s): s is string => !!s);
}

/** One day's opening, as the page prints it: 1 = Monday … 7 = Sunday. */
export type Hours = { day: number; open: string | null; close: string | null };

const hhmm = (raw: string | null) => {
  if (!raw) return null;
  const p = raw.split(':');
  return p.length >= 2 ? `${p[0]}:${p[1]}` : raw;
};

/** The table keeps 0 = Sunday … 6 = Saturday; the page counts Monday first
 *  (BusinessHours.fromJson). */
export function hoursOf(b: Business): Hours[] {
  return (b.business_hours ?? []).map((h) => ({
    day: h.day_of_week == null ? 1 : h.day_of_week === 0 ? 7 : h.day_of_week,
    open: hhmm(h.open_time),
    close: hhmm(h.close_time),
  }));
}

/** Now, in Modi'in: the weekday (1 = Monday) and the minute of the day. */
function israelNow(): { day: number; minutes: number } {
  const parts = new Intl.DateTimeFormat('en-GB', { timeZone: 'Asia/Jerusalem', weekday: 'short', hour: '2-digit', minute: '2-digit', hourCycle: 'h23' })
    .formatToParts(new Date());
  const wd = parts.find((p) => p.type === 'weekday')?.value ?? 'Mon';
  const day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].indexOf(wd) + 1 || 1;
  const h = Number(parts.find((p) => p.type === 'hour')?.value ?? 0);
  const m = Number(parts.find((p) => p.type === 'minute')?.value ?? 0);
  return { day, minutes: h * 60 + m };
}

/** Whether it is open now, and when today's opening closes (Business.isOpenNow). */
export function openNow(hours: Hours[]): { open: boolean; closes: string | null } {
  const now = israelNow();
  const today = hours.filter((h) => h.day === now.day && h.open && h.close);
  const mins = (s: string) => { const [a, b] = s.split(':'); return Number(a) * 60 + Number(b); };
  for (const h of today) {
    const o = mins(h.open!), c = mins(h.close!);
    const inside = c > o ? now.minutes >= o && now.minutes < c : now.minutes >= o || now.minutes < c;
    if (inside) return { open: true, closes: today[0].close };
  }
  return { open: false, closes: null };
}

/** "21:30" in Hebrew; "9:30 PM" in English, as the design prints it. */
export function clock(time: string, lang: Lang): string {
  if (lang === 'he') return time;
  const [hs, m = '00'] = time.split(':');
  const h = Number(hs) || 0;
  return `${h % 12 === 0 ? 12 : h % 12}:${m} ${h >= 12 ? 'PM' : 'AM'}`;
}

/** "₪32" for whole shekels, "₪32.50" otherwise; null for no fixed price. */
export function price(agorot: number | null): string | null {
  if (agorot == null) return null;
  return agorot % 100 === 0 ? `₪${agorot / 100}` : `₪${(agorot / 100).toFixed(2)}`;
}

/** An address as typed, ready to open: the scheme added where it is missing. */
export function webLink(url: string): string {
  return /^https?:\/\//i.test(url) ? url : `https://${url}`;
}

/** A website as the card prints it: no scheme, no www, no trailing slash. */
export function shownUrl(url: string): string {
  return url.replace(/^https?:\/\/(www\.)?/i, '').replace(/\/$/, '');
}

/** A WhatsApp number as wa.me takes it: digits, Israel's 972 for a leading 0. */
export function waNumber(raw: string): string {
  let d = raw.replace(/\D/g, '');
  if (d.startsWith('0')) d = '972' + d.slice(1);
  return d;
}

/** A stored photo at about the size it is drawn (sizedPhotoUrl): Supabase
 *  resizes a JPEG, PNG or WebP on the way out, so a 4 MB cover reaches a
 *  200-pixel thumbnail as a few kilobytes. Anything else is left as it is. */
export function sized(url: string, width: number): string {
  const stored = '/storage/v1/object/public/';
  if (!url.includes('.supabase.co' + stored)) return url;
  const path = url.split('?')[0].toLowerCase();
  if (!/\.(jpe?g|png|webp)$/.test(path)) return url;
  const steps = [200, 400, 600, 800, 1200, 1600, 2000, 2500];
  const w = steps.find((s) => s >= width * 2) ?? 2500;
  return `${url.replace(stored, '/storage/v1/render/image/public/')}${url.includes('?') ? '&' : '?'}width=${w}&height=2500&resize=contain&quality=75`;
}
