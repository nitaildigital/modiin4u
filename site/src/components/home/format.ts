import type { Lang } from '@/lib/i18n';
import { href } from '@/lib/seo';
import { bizDescription, bizImage, bizName, bizNeighborhood, catName, kosherLabel, type Biz, type Kind } from '@/lib/data/home';
import type { BizCardData } from './Cards';

const HE_MONTHS = ['ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני', 'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר'];
const EN_MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const HE_SHORT = ['ינו', 'פבר', 'מרץ', 'אפר', 'מאי', 'יונ', 'יול', 'אוג', 'ספט', 'אוק', 'נוב', 'דצמ'];
const EN_SHORT = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/** The parts of a moment on the clock in Modi'in. */
function israel(iso: string) {
  const p = Object.fromEntries(new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Jerusalem', year: 'numeric', month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  }).formatToParts(new Date(iso)).map((x) => [x.type, x.value]));
  return { y: +p.year, m: +p.month, d: +p.day, h: +p.hour, min: p.minute as string };
}

/** The hour now in Israel, for the phone's greeting. */
export function israelHour(): number {
  return israel(new Date().toISOString()).h;
}

/** "5 באוגוסט 2026 | 16:36", or "August 5, 2026 | 4:36 p.m." as the design
 *  writes it — the desktop news rows (_dateLine). */
export function newsDateLine(iso: string | null, lang: Lang): string {
  if (!iso) return '';
  const { y, m, d, h, min } = israel(iso);
  if (lang === 'he') return `${d} ב${HE_MONTHS[m - 1]} ${y} | ${String(h).padStart(2, '0')}:${min}`;
  return `${EN_MONTHS[m - 1]} ${d}, ${y} | ${h % 12 === 0 ? 12 : h % 12}:${min} ${h < 12 ? 'a.m.' : 'p.m.'}`;
}

/** "25 ספטמבר 2026 | 10:47" — the phone's news cards (_NewsData). */
export function phoneDateLine(iso: string | null, lang: Lang): string {
  if (!iso) return '';
  const { y, m, d, h, min } = israel(iso);
  return `${d} ${(lang === 'he' ? HE_MONTHS : EN_MONTHS)[m - 1]} ${y} | ${String(h).padStart(2, '0')}:${min}`;
}

/** An event's calendar date ("2026-10-08") as the badge's month and day. */
export function dayBadge(date: string | null, lang: Lang): { month: string; day: string } {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(date ?? '');
  if (!m) return { month: '', day: '' };
  return { month: (lang === 'he' ? HE_SHORT : EN_SHORT)[+m[2] - 1], day: String(+m[3]) };
}

/** A business as the desktop cards draw it. */
export function cardOf(b: Biz, kind: Kind | undefined, lang: Lang): BizCardData {
  const category = kind ? catName(kind.category, lang) : '';
  const description = bizDescription(b);
  return {
    id: b.id,
    href: href(`/business/${b.slug || b.id}/`),
    name: bizName(b, lang),
    subtitle: description || category,
    address: b.address?.trim() || bizNeighborhood(b, lang),
    image: bizImage(b),
    logo: b.logo_url,
    category,
    kosher: kosherLabel(b.kosher_level),
    rating: b.rating ?? 0,
    reviews: b.review_count ?? 0,
    phone: b.phone,
    whatsapp: b.whatsapp,
    email: b.email,
    badge: kind?.rootSlug === 'cafe-bakery' ? 'cafe' : kind?.rootSlug === 'restaurants' ? 'restaurant' : null,
  };
}

/** A stable tint for a card with no photograph, from its id — the same row
 *  always looks the same (_gradientFor). */
const TINTS = [['#8B6914', '#C49B2C'], ['#2D6A4F', '#40916C'], ['#1A4B6E', '#2980B9'], ['#5B2C6F', '#8E44AD'], ['#7B341E', '#C0563A'], ['#0F5257', '#17A9D0']];
export function tintOf(id: string): string {
  let h = 0;
  for (const c of id) h = (h * 31 + c.charCodeAt(0)) | 0;
  const [a, b] = TINTS[Math.abs(h) % TINTS.length];
  return `linear-gradient(135deg, ${a}, ${b})`;
}
