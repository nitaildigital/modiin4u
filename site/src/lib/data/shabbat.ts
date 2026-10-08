import { cache } from 'react';
import type { Lang } from '../i18n';

// Shabbat and holiday times for Modi'in, from Hebcal (hebcal.com), exactly
// as the app asks for them (shabbat_providers.dart): by the city's
// coordinates and elevation, candle lighting 20 minutes before sunset and
// Havdalah 30 after — the municipality's own table, as the client asked.
// Nothing here is written into the site; if Hebcal cannot be reached the
// times are left out rather than guessed. Hebcal's licence (CC BY 4.0) asks
// for the credit the pages show.

const LOCATION = 'latitude=31.8969&longitude=35.0095&tzid=Asia/Jerusalem&geo=pos&ue=on&elev=300';
const TIMES = 'b=20&m=30';

/** The times move every week; an hour old is close enough, and a page
 *  costs Hebcal a request an hour at most. */
const REFRESH = 3600;

export type HebcalName = { he: string; en: string };

export type ShabbatWeek = {
  /** yyyy-mm-dd */
  friday: string;
  saturday: string;
  /** "18:03" in Israel's time, read off Hebcal's string. */
  candles: string | null;
  havdalah: string | null;
  parasha: HebcalName | null;
  holidays: HebcalName[];
};

export type HolidayDay = { date: string; name: HebcalName };

type Item = { category?: string; date?: string; title?: string; title_orig?: string; hebrew?: string };

async function items(url: string): Promise<Item[]> {
  const r = await fetch(url, { next: { revalidate: REFRESH }, signal: AbortSignal.timeout(15000) });
  if (!r.ok) throw new Error(`Hebcal answered ${r.status}`);
  const body = await r.json();
  return (body.items ?? []) as Item[];
}

const nameOf = (i: Item): HebcalName => ({
  he: i.hebrew ?? i.title ?? '',
  en: i.title_orig ?? i.title ?? '',
});

const day = (iso: string) => iso.slice(0, 10);
const time = (iso: string) => (iso.length >= 16 ? iso.slice(11, 16) : '');

/** Today in Israel, as yyyy-mm-dd. */
function israelToday(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jerusalem', year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
}

function addDays(ymd: string, n: number): string {
  const d = new Date(ymd + 'T12:00:00Z');
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

/** This week's Shabbat, or null when Hebcal cannot be read. */
export const shabbatWeek = cache(async (): Promise<ShabbatWeek | null> => {
  let list: Item[];
  try {
    list = await items(`https://www.hebcal.com/shabbat?cfg=json&${LOCATION}&${TIMES}&lg=he`);
  } catch {
    return null;
  }
  // The week can hold a holiday's own candle lighting too (the eve of a
  // festival on a Thursday), so Shabbat's are the last before Havdalah.
  const havdalah = [...list].reverse().find((i) => i.category === 'havdalah');
  const candles = [...list].reverse().find((i) => i.category === 'candles'
    && (!havdalah || (i.date ?? '') < (havdalah.date ?? '')));

  let saturday: string;
  if (havdalah?.date) {
    saturday = day(havdalah.date);
  } else {
    const today = israelToday();
    const weekday = new Date(today + 'T12:00:00Z').getUTCDay(); // 0 = Sunday
    saturday = addDays(today, (6 - weekday + 7) % 7);
  }
  const parasha = list.find((i) => i.category === 'parashat');
  return {
    friday: addDays(saturday, -1),
    saturday,
    candles: candles?.date ? time(candles.date) : null,
    havdalah: havdalah?.date ? time(havdalah.date) : null,
    parasha: parasha ? nameOf(parasha) : null,
    holidays: list.filter((i) => i.category === 'holiday' && i.date && day(i.date) === saturday).map(nameOf),
  };
});

/** Holidays in the next three months, as Israel keeps them — the major and
 *  minor ones, the modern Israeli days and the minor fasts; Rosh Chodesh and
 *  the special Shabbatot are not holidays and stay out. Null on failure. */
export const upcomingHolidays = cache(async (): Promise<HolidayDay[] | null> => {
  const start = israelToday();
  const end = addDays(start, 90);
  try {
    const list = await items('https://www.hebcal.com/hebcal?v=1&cfg=json&maj=on&min=on&mod=on&nx=off'
      + `&ss=off&mf=on&c=off&i=on&lg=he&start=${start}&end=${end}`);
    return list.filter((i) => i.category === 'holiday' && i.date).map((i) => ({ date: day(i.date!), name: nameOf(i) }));
  } catch {
    return null;
  }
});

const MONTHS_SHORT = {
  he: ['ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יונ', 'יול', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ'],
  en: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
};

function parts(ymd: string) {
  const [y, m, d] = ymd.split('-').map(Number);
  return { y, m, d };
}

/** "9 Oct" / "9 אוק" — a date badge (monthShort in the app). */
export function dayMonth(ymd: string, lang: Lang): string {
  const { m, d } = parts(ymd);
  return `${d} ${MONTHS_SHORT[lang][m - 1]}`;
}

/** "2–3 Oct 2026", or "31 Oct–1 Nov 2026" across a month's end
 *  (shabbatDates). */
export function shabbatDates(w: ShabbatWeek, lang: Lang): string {
  const f = parts(w.friday), s = parts(w.saturday);
  const from = f.m === s.m ? `${f.d}` : `${f.d} ${MONTHS_SHORT[lang][f.m - 1]}`;
  return `${from}–${s.d} ${MONTHS_SHORT[lang][s.m - 1]} ${s.y}`;
}

/** The coming weekend's dates, for the phone's Shabbat card while Hebcal has
 *  not answered — the dates are the calendar's, the times are left out. */
export function comingWeekendDates(lang: Lang): string {
  const today = israelToday();
  const weekday = new Date(today + 'T12:00:00Z').getUTCDay();
  const friday = addDays(today, weekday === 6 ? -1 : (5 - weekday + 7) % 7);
  const f = parts(friday), s = parts(addDays(friday, 1));
  return `${f.d} ${MONTHS_SHORT[lang][f.m - 1]}–${s.d} ${MONTHS_SHORT[lang][s.m - 1]} ${s.y}`;
}

/** What this Shabbat is: its holiday when one falls on it, else its
 *  parasha. */
export function shabbatName(w: ShabbatWeek, lang: Lang): string | null {
  if (w.holidays.length) return w.holidays.map((h) => h[lang]).join(' · ');
  return w.parasha ? w.parasha[lang] : null;
}
