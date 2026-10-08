import Link from 'next/link';
import { ArrowLeft2, ArrowRight2, Building3, Calendar1, DocumentText, SearchNormal1, SearchStatus, Shop, TicketDiscount } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import type { Hit, HitKind } from '@/lib/data/search';

const ICON: Record<HitKind, typeof Shop> = { business: Shop, event: Calendar1, deal: TicketDiscount, listing: Building3, news: DocumentText };

/** The kind of a result in the page's language, one or many. */
export function kindLabel(kind: HitKind, lang: Lang, plural = false): string {
  const he = lang === 'he';
  switch (kind) {
    case 'business': return plural ? (he ? 'עסקים' : 'Businesses') : (he ? 'עסק' : 'Business');
    case 'event': return plural ? (he ? 'אירועים' : 'Events') : (he ? 'אירוע' : 'Event');
    case 'deal': return plural ? (he ? 'הטבות' : 'Deals') : (he ? 'הטבה' : 'Deal');
    case 'listing': return he ? 'נדל״ן' : 'Real estate';
    case 'news': return he ? 'חדשות' : 'News';
  }
}

/** The hit's photo, or the tinted square with its kind's glyph, at the same
 *  size either way. */
function HitImage({ hit, size, radius, iconSize }: { hit: Hit; size: number; radius: number; iconSize: number }) {
  const Icon = ICON[hit.kind];
  return hit.image
    ? <img src={hit.image} alt="" loading="lazy" className="shrink-0 object-cover" style={{ width: size, height: size, borderRadius: radius }} />
    : (
      <span className="flex shrink-0 items-center justify-center bg-[linear-gradient(135deg,rgba(23,169,208,.10),rgba(23,169,208,.06))]" style={{ width: size, height: size, borderRadius: radius }}>
        <Icon size={iconSize} color="#17A9D0" />
      </span>
    );
}

/** The box shown in place of results: nothing searched, or nothing found. */
export function SearchNotice({ title, body, icon = 'status' }: { title: string; body: string; icon?: 'search' | 'status' }) {
  const Icon = icon === 'search' ? SearchNormal1 : SearchStatus;
  return (
    <div className="flex h-80 flex-col items-center justify-center rounded-xl border border-line px-6 text-center">
      <Icon size={44} color="rgba(95,94,90,.5)" />
      <p className="mt-4 text-lg font-semibold text-[#1C1C1E]">{title}</p>
      <p className="mt-2 text-sm text-gray-text">{body}</p>
    </div>
  );
}

/** Desktop (web_search_results_screen.dart, _buildGroups): a section per
 *  kind, in the order the search returns them, each a grid of wide cards. */
export function DeskResults({ hits, lang }: { hits: Hit[]; lang: Lang }) {
  const order: HitKind[] = [];
  const by = new Map<HitKind, Hit[]>();
  for (const h of hits) {
    if (!by.has(h.kind)) { order.push(h.kind); by.set(h.kind, []); }
    by.get(h.kind)!.push(h);
  }
  const Chevron = lang === 'he' ? ArrowLeft2 : ArrowRight2;
  // A name reads in its own direction but lines up with the page's.
  const align = lang === 'he' ? 'text-right' : 'text-left';
  return (
    <div className="flex flex-col gap-14">
      {order.map((kind) => {
        const rows = by.get(kind)!;
        return (
          <section key={kind}>
            <h2 className="flex items-center gap-2.5">
              <span className="font-nunito text-2xl font-semibold text-midblue">{kindLabel(kind, lang, rows.length !== 1)}</span>
              <span className="rounded-md bg-midblue/[.06] px-2.5 py-1 text-[13px] font-semibold text-midblue">{rows.length}</span>
            </h2>
            {/* Three across once there is room for a photo, a title and a
                two-line blurb in each; two below that. */}
            <ul className="mt-5 grid grid-cols-2 gap-5 min-[1484px]:grid-cols-3">
              {rows.map((h) => (
                <li key={h.kind + h.href}>
                  <Link href={h.href} className="group flex h-[132px] items-center gap-4 rounded-xl border border-line bg-white p-4 transition-colors hover:border-midblue">
                    <HitImage hit={h} size={96} radius={10} iconSize={32} />
                    <span className="flex min-w-0 flex-1 flex-col justify-center">
                      <span className="w-fit rounded-md bg-midblue/[.06] px-2 py-[3px] text-[11px] font-medium text-midblue">{kindLabel(kind, lang)}</span>
                      <span dir="auto" className={`mt-2 truncate ${align} text-[17px] font-semibold leading-[1.22] text-[#1C1C1E]`}>{h.title}</span>
                      {h.subtitle && <span dir="auto" className={`mt-1 line-clamp-2 ${align} text-[13px] leading-[1.35] text-gray-text`}>{h.subtitle}</span>}
                    </span>
                    <Chevron size={20} color="currentColor" className="shrink-0 text-[#6D6D6D] group-hover:text-midblue" />
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        );
      })}
    </div>
  );
}

/** Phone (search_results_screen.dart): one column of rows — the photo, the
 *  title and its line, and the kind on the end. */
export function PhoneResults({ hits, lang }: { hits: Hit[]; lang: Lang }) {
  const align = lang === 'he' ? 'text-right' : 'text-left';
  return (
    <ul className="divide-y divide-line px-5">
      {hits.map((h) => (
        <li key={h.kind + h.href}>
          <Link href={h.href} className="flex items-center gap-4 py-3.5">
            <HitImage hit={h} size={44} radius={12} iconSize={22} />
            <span className="min-w-0 flex-1">
              <span dir="auto" className={`block truncate ${align} font-rubik text-[15px] font-medium text-ink`}>{h.title}</span>
              {h.subtitle && <span dir="auto" className={`mt-0.5 line-clamp-2 ${align} font-rubik text-xs text-gray-meta`}>{h.subtitle}</span>}
            </span>
            <span className="shrink-0 rounded-md bg-midblue/[.06] px-2 py-[3px] font-rubik text-[11px] text-midblue">{kindLabel(h.kind, lang)}</span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
