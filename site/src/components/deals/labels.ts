import type { Lang } from '@/lib/i18n';
import type { Deal } from '@/lib/data/deals';

// How a deal's badge, clock and business read, in either language
// (lib/features/deals/models/offer.dart). Plain functions, shared by the
// server pages and the interactive lists.

/** The business's name in the page's language: its English one where the
 *  panel has it. */
export function businessName(d: Deal, lang: Lang): string | null {
  const b = d.business;
  if (!b?.name) return null;
  return lang === 'en' && b.name_en ? b.name_en : b.name;
}

/** The neighbourhood the business is filed under, in the page's language. */
export function neighborhood(d: Deal, lang: Lang): string | null {
  const b = d.business;
  if (!b?.hood) return null;
  return lang === 'en' && b.hood_en ? b.hood_en : b.hood;
}

/** Who may take it: the admin limited it to verified residents. */
export function residentsOnly(d: Deal): boolean {
  return d.audience === 'verified';
}

/** "2d : 14h", or "14h : 30m" inside the last day, as the website's cards
 *  print it; "Ended" / "הסתיים" once over; null with no end date. */
export function timeLeftLabel(d: Pick<Deal, 'ms_left'>, lang: Lang): string | null {
  const left = d.ms_left;
  if (left == null) return null;
  if (left === 0) return lang === 'he' ? 'הסתיים' : 'Ended';
  const minutes = Math.floor(left / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  const two = (n: number) => String(n).padStart(2, '0');
  if (days >= 1) return `${days}d : ${two(hours % 24)}h`;
  return `${hours}h : ${two(minutes % 60)}m`;
}

/** The phone's clock: the design's "2d : 14h" in English, "2 ימים" in
 *  Hebrew (mDealTimeLeft). */
export function phoneTimeLeft(d: Pick<Deal, 'ms_left'>, lang: Lang): string | null {
  if (lang === 'en') return timeLeftLabel(d, lang);
  const left = d.ms_left;
  if (left == null) return null;
  if (left === 0) return 'הסתיים';
  const minutes = Math.floor(left / 60000);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  if (days >= 1) return `${days} ימים`;
  if (hours >= 1) return `${hours} שעות`;
  return `${minutes} דקות`;
}

// A percentage the title calls a discount: "20% off", "20% הנחה", "הנחה של
// 20%". A bare "ב-50%" ("the second one at 50%") is not a discount on the
// whole, and gets no badge rather than a wrong one.
const PERCENT = /(\d{1,3})\s?%\s*(?:off|הנחה)|הנחה\s+של\s+(\d{1,3})\s?%/i;
const FLAT = /(?:flat\s*)?(₪\s?[\d,]+|[\d,]+\s?₪)\s*(?:off|הנחה)/i;
const BUY_GET = /buy\s*(\d+)\s*get\s*(\d+)/i;
const PLUS_ONE = /(?<![\d.])(\d)\s?\+\s?(\d)(?![\d.])/;
const GIFT = /מתנה|\bfree\b/i;

/** The percentage off, where the title states one. */
export function percentOff(title: string): number | null {
  const m = PERCENT.exec(title);
  if (!m) return null;
  const n = Number(m[1] ?? m[2]);
  return Number.isFinite(n) ? n : null;
}

/** The orange corner label — "20% OFF", "BUY 1 GET 1", "1+1" — read out of
 *  the offer's own title: `offers` has no discount column, and every badge
 *  the design draws restates the headline. Null when the headline states no
 *  discount, rather than one made up. */
export function dealBadge(title: string): string | null {
  const t = title.trim();
  if (!t) return null;
  const hebrew = /[֐-׿]/.test(t);
  const buy = BUY_GET.exec(t);
  if (buy) return `BUY ${buy[1]} GET ${buy[2]}`;
  const plus = PLUS_ONE.exec(t);
  if (plus) return `${plus[1]}+${plus[2]}`;
  const pct = percentOff(t);
  if (pct != null) return hebrew ? `${pct}% הנחה` : `${pct}% OFF`;
  const flat = FLAT.exec(t);
  if (flat) return hebrew ? `${flat[1]} הנחה` : `FLAT ${flat[1].replace(/\s/g, '')} OFF`;
  if (GIFT.test(t)) return hebrew ? 'מתנה' : 'FREE';
  return null;
}

/** The pink strip on a brand tile: "Upto 30% Off" across several percentage
 *  deals, the one deal's badge otherwise, how many deals when no title states
 *  a discount. */
export function brandStrip(deals: Deal[], lang: Lang): string {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const pcts = deals.map((d) => percentOff(d.name)).filter((n): n is number => n != null);
  if (pcts.length > 1) {
    const best = Math.max(...pcts);
    return t(`עד ${best}% הנחה`, `Upto ${best}% Off`);
  }
  for (const d of deals) {
    const b = dealBadge(d.name);
    if (b) return b;
  }
  return deals.length === 1 ? t('מבצע אחד', '1 Deal') : t(`${deals.length} מבצעים`, `${deals.length} Deals`);
}

/** Whether a string is Hebrew, so database text keeps its own direction. */
export function isHebrew(s: string): boolean {
  return /[֐-׿]/.test(s);
}
