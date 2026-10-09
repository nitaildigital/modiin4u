'use client';
import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, Calendar1, SearchStatus } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import type { EventCard, EventCategory } from '@/lib/data/events';
import { MEventCard, WebEventCard } from './EventCards';
import { categoryLabel } from './labels';

/** One circle in "Event Categories": All, each category with something
 *  coming up, then Free. [filter] is what follows `?category=`. */
export type Circle = { label: string; count: number; filter: string; image: string | null };

// The design's photographs for the circles, by category slug. The editor's
// own picture (`categories.image_url`) wins where there is one.
const CIRCLE_ALL = '/web/events/cat_all.webp';
const CIRCLE_FREE = '/web/events/cat_free.webp';
const CIRCLE_BY_SLUG: Record<string, string> = {
  community: '/web/events/cat_community.webp', 'municipal-community': '/web/events/cat_community.webp',
  concerts: '/web/events/cat_music.webp', music: '/web/events/cat_music.webp',
  kids: '/web/events/cat_kids.webp', 'kids-family': '/web/events/cat_kids.webp',
  'sports-events': '/web/events/cat_sports.webp', sports: '/web/events/cat_sports.webp',
};

/** "All Events", each category that has something coming, and "Free", with
 *  the number of upcoming events each opens. A category with nothing coming
 *  is left out; with nothing coming at all there are no circles. */
export function eventCircles(upcoming: EventCard[], categories: EventCategory[], byEvent: Record<string, EventCategory[]>, lang: Lang): Circle[] {
  if (!upcoming.length) return [];
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const circles: Circle[] = [{ label: t('כל האירועים', 'All Events'), count: upcoming.length, filter: 'all', image: CIRCLE_ALL }];
  for (const c of categories) {
    const inIt = upcoming.filter((e) => (byEvent[e.id] ?? []).some((x) => x.id === c.id));
    if (!inIt.length) continue;
    // The editor's picture; else the design's; else the photograph of the
    // category's next event, so a category the design never drew still
    // shows a picture of itself.
    const image = c.image_url || CIRCLE_BY_SLUG[c.slug] || inIt.find((e) => e.image)?.image || null;
    circles.push({ label: categoryLabel(c, lang), count: inIt.length, filter: c.slug, image });
  }
  const free = upcoming.filter((e) => e.is_free).length;
  if (free) circles.push({ label: t('חינם', 'Free'), count: free, filter: 'free', image: CIRCLE_FREE });
  return circles;
}

function matches(e: EventCard, filter: string, byEvent: Record<string, EventCategory[]>): boolean {
  if (filter === 'all') return true;
  if (filter === 'free') return e.is_free;
  return (byEvent[e.id] ?? []).some((c) => c.slug === filter);
}

/** How many rows the website's grid opens with, and how many "Load More" adds. */
const FIRST_ROWS = 4;
const ROWS_PER_LOAD = 2;

/** The events page (web_events_screen.dart above 1100, events_screen.dart
 *  below): the hero with the heading and the search, the category circles,
 *  and the upcoming events — a grid of cards on the website, a list on the
 *  phone. The search narrows both as it is typed.
 *
 *  [phoneOnly] draws only the phone layout: with `?category=` in the address
 *  the website shows the category browser instead, and the phone this list
 *  opened on that category. */
export function EventsHome({ lang, heading, headingIsH1, events, categories, byEvent, initialFilter, phoneOnly = false }: {
  lang: Lang; heading: string; headingIsH1: boolean; events: EventCard[]; categories: EventCategory[];
  byEvent: Record<string, EventCategory[]>; initialFilter: string; phoneOnly?: boolean;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [typed, setTyped] = useState('');
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState(initialFilter || 'all');
  const [extraRows, setExtraRows] = useState(0);
  const [cols, setCols] = useState(4);
  const debounce = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Four across once the column has room for four 300-wide cards, three below
  // (webEventGridColumns); the server draws four.
  useEffect(() => {
    const mq = window.matchMedia('(min-width: 1398px)');
    const set = () => setCols(mq.matches ? 4 : 3);
    set();
    mq.addEventListener('change', set);
    return () => mq.removeEventListener('change', set);
  }, []);

  const onType = (v: string) => {
    setTyped(v);
    if (debounce.current) clearTimeout(debounce.current);
    debounce.current = setTimeout(() => { setQuery(v); setExtraRows(0); }, 250);
  };
  const searchNow = () => {
    if (debounce.current) clearTimeout(debounce.current);
    setQuery(typed);
    setExtraRows(0);
  };

  // The search looks at the title, the venue and the address.
  const found = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return events;
    return events.filter((e) => e.title.toLowerCase().includes(q) || (e.venue_name ?? '').toLowerCase().includes(q) || (e.address ?? '').toLowerCase().includes(q));
  }, [events, query]);
  const searching = query.trim().length > 0;

  const circles = useMemo(() => eventCircles(events, categories, byEvent, lang), [events, categories, byEvent, lang]);
  const active = circles.find((c) => c.filter === filter);
  const phoneList = active ? found.filter((e) => matches(e, active.filter, byEvent)) : found;
  const firstCategory = (e: EventCard) => {
    const c = (byEvent[e.id] ?? [])[0];
    return c ? categoryLabel(c, lang) : null;
  };

  const visibleCount = cols * (FIRST_ROWS + extraRows);
  const hasMore = found.length > visibleCount;
  const Heading = headingIsH1 ? 'h1' : 'p';

  return (
    <div className={phoneOnly ? 'desk:hidden' : ''}>
      {/* ── The hero: on the website the photograph in its dotted band with
             the heading and the search over it; on the phone the title bar
             and the search pill. ── */}
      <section className="relative desk:h-[662px]">
        <div className="pointer-events-none absolute inset-0 hidden desk:block" aria-hidden>
          <div className="absolute inset-0" style={{ background: 'linear-gradient(to top, rgba(191,231,246,0.08), rgba(196,196,196,0))' }} />
          <div className="absolute inset-0 opacity-20" style={{ backgroundImage: 'url(/web/common/dots_tile.png)', backgroundSize: '154px 154px', backgroundPosition: 'top center' }} />
        </div>
        <div className="relative desk:px-6 desk:pt-12">
          <div className="relative mx-auto desk:h-[551px] desk:max-w-[1200px] desk:overflow-hidden desk:rounded-3xl desk:bg-[#43270F]">
            <img src="/web/events/hero.webp" alt="" className="absolute inset-0 hidden size-full object-cover desk:block" />
            <div className="pointer-events-none absolute left-1/2 top-[-154px] hidden h-[767px] w-[846px] -translate-x-1/2 desk:block"
              style={{ background: 'radial-gradient(circle 383.5px at center, rgba(0,0,0,0.35) 45%, rgba(0,0,0,0) 100%)' }} aria-hidden />
            <div className="relative flex flex-col items-center desk:pt-[152px]">
              <div className="flex h-[52px] w-full items-center px-[15px] desk:h-auto desk:justify-center desk:px-6">
                <Link href="/" aria-label={t('חזרה', 'Back')} className="flex size-6 shrink-0 items-center justify-center text-[#3D3D3D] desk:hidden">
                  <span className="rtl:-scale-x-100"><ArrowLeft size={24} color="currentColor" /></span>
                </Link>
                <Heading className="min-w-0 flex-1 text-center text-base font-medium text-black desk:flex-none desk:font-nunito desk:text-[44px] desk:font-semibold desk:leading-[1.25] desk:text-white">
                  {heading}
                </Heading>
                <span className="w-[39px] shrink-0 desk:hidden" />
              </div>
              <p className="mt-2 hidden w-[584px] max-w-full text-center text-base text-white desk:block">
                {t('גלו הופעות, אירועי קהילה, חיי לילה, פעילויות למשפחה ועוד — הכל סביב מודיעין.',
                  'Discover concerts, community events, nightlife, family activities and more happening around Modiin.')}
              </p>
              <form role="search" onSubmit={(ev) => { ev.preventDefault(); searchNow(); }}
                className="flex h-12 w-[calc(100%-32px)] items-center gap-2 rounded-[50px] border border-line bg-white px-4 desk:mt-[23px] desk:h-[70px] desk:w-[calc(100%-48px)] desk:max-w-[751px] desk:gap-4 desk:border-0 desk:py-3 desk:pe-3 desk:ps-6">
                <img src="/web/common/search24.svg" alt="" className="size-[18px] shrink-0 desk:size-6" />
                <input type="search" value={typed} onChange={(ev) => onType(ev.target.value)}
                  placeholder={t('חפשו אירועים, הופעות, פעילויות...', 'Search events, concerts, activities...')}
                  aria-label={t('חיפוש אירועים', 'Search events')}
                  className="min-w-0 flex-1 bg-transparent text-sm text-black outline-none placeholder:text-[#6D6D6D] desk:text-base desk:placeholder:text-[#4F4F4F]" />
                <button type="submit" className="hidden h-[46px] shrink-0 items-center gap-2 rounded-[60px] bg-midblue px-6 text-base font-medium text-white desk:flex">
                  <img src="/web/common/search_white.svg" alt="" className="size-[18px]" />
                  {t('חיפוש', 'Search')}
                </button>
              </form>
            </div>
          </div>
        </div>
      </section>

      {/* ── The website: the circles open the category browser ── */}
      {!phoneOnly && circles.length > 0 && (
        <section className="wrap hidden pt-[59px] desk:block">
          <h2 className="text-center font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{t('קטגוריות אירועים', 'Event Categories')}</h2>
          <p className="mt-[15px] text-center text-sm leading-[17px] text-gray-text">{t('ממוזיקה ועד כיף משפחתי — מצאו את החוויה הבאה שלכם.', 'From music to family fun, find your next experience.')}</p>
          <div className="mx-auto mt-[42px] flex min-h-[203px] max-w-[1200px] items-start justify-center"
            style={{ columnGap: circles.length > 1 ? `clamp(0px, calc((100% - ${circles.length * 160}px) / ${circles.length - 1}), 48px)` : 0 }}>
            {circles.map((c) => (
              <Link key={c.filter} href={`/events/?category=${encodeURIComponent(c.filter)}`} className="group flex w-[160px] min-w-0 shrink flex-col items-center">
                <span className="block size-[116px] overflow-hidden rounded-full transition-transform duration-150 group-hover:scale-[1.04]">
                  <CirclePhoto url={c.image} size={116} />
                </span>
                <span className="mt-5 line-clamp-2 px-2.5 text-center text-lg font-semibold leading-[22px] text-[#1C1C1E] group-hover:text-midblue">{c.label}</span>
                <span className="mt-1.5 text-sm leading-[17px] text-gray-text">{c.count}</span>
              </Link>
            ))}
          </div>
        </section>
      )}

      {/* ── The website: the grid, four rows, more on "Load More" ── */}
      {!phoneOnly && (
        <section className="wrap hidden pb-[90px] pt-20 desk:block">
          <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{t('אירועים במודיעין', 'Events in Modiin')}</h2>
          <p className="mt-2.5 text-sm leading-[17px] text-gray-text">{t('מצאו משהו שקורה לידכם.', 'Find something happening near you.')}</p>
          <div className="mt-8">
            {found.length === 0 ? (
              <div className="flex flex-col items-center rounded-xl border border-line px-6 py-[72px] text-center">
                {searching ? <SearchStatus size={44} color="rgba(95,94,90,0.5)" /> : <Calendar1 size={44} color="rgba(95,94,90,0.5)" />}
                <p className="mt-4 font-nunito text-xl font-semibold text-navy">
                  {searching ? t('אין אירועים שתואמים לחיפוש', 'No events match your search') : t('עדיין לא פורסמו אירועים', 'No events listed yet')}
                </p>
                <p className="mt-2 text-sm text-gray-text">
                  {searching ? t('נסו מילה אחרת, או נקו את החיפוש.', 'Try a different word, or clear the search.') : t('אירועים חדשים יופיעו כאן עם פרסומם.', 'New events will appear here as they are published.')}
                </p>
              </div>
            ) : (
              <div className="relative">
                <div className="grid grid-cols-3 gap-6 min-[1398px]:grid-cols-4">
                  {found.map((e, i) => (
                    <div key={e.id} className={i < visibleCount ? '' : 'hidden'}>
                      <WebEventCard event={e} lang={lang} category={firstCategory(e)} />
                    </div>
                  ))}
                </div>
                {hasMore && (
                  <>
                    <div className="pointer-events-none absolute inset-x-[-1px] bottom-[-1px] h-[389px]"
                      style={{ background: 'linear-gradient(to bottom, rgba(255,255,255,0) 1.675%, #fff 75.644%)' }} />
                    <div className="absolute inset-x-0 bottom-[78px] flex justify-center">
                      <button type="button" onClick={() => setExtraRows((n) => n + ROWS_PER_LOAD)}
                        className="h-[46px] rounded-[60px] border border-midblue bg-white px-8 text-base font-medium leading-6 text-midblue">
                        {t('טען עוד', 'Load More')}
                      </button>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>
        </section>
      )}

      {/* ── The phone: circles that narrow the list, then the cards ── */}
      <div className="desk:hidden">
        {circles.length > 0 && (
          <section className="pt-5">
            <h2 className="px-4 text-base font-semibold text-[#1F1F1F]">{t('קטגוריות אירועים', 'Event Categories')}</h2>
            <div className="mt-4 flex overflow-x-auto [scrollbar-width:none]">
              {circles.map((c) => {
                const on = c.filter === filter && filter !== 'all';
                return (
                  <button key={c.filter} type="button" onClick={() => setFilter(on ? 'all' : c.filter)} aria-pressed={on}
                    className="flex w-[100px] shrink-0 flex-col items-center">
                    <span className={`block size-16 overflow-hidden rounded-full ${on ? 'ring-2 ring-midblue' : ''}`}>
                      <CirclePhoto url={c.image} size={64} />
                    </span>
                    <span className={`mt-3 w-full truncate px-1 text-center text-sm font-medium leading-[1.21] ${on ? 'text-midblue' : 'text-black'}`}>{c.label}</span>
                    <span className="mt-1 text-sm leading-[1.21] text-gray-text">{c.count}</span>
                  </button>
                );
              })}
            </div>
          </section>
        )}
        <section className="px-4 pb-20 pt-8">
          <h2 className="text-base font-semibold text-[#1F1F1F]">{!active || active.filter === 'all' ? t('אירועים במודיעין', 'Events in Modiin') : active.label}</h2>
          <div className="mt-3">
            {phoneList.length === 0 ? (
              <div className="flex flex-col items-center px-6 py-12 text-center">
                {searching ? <SearchStatus size={48} color="#9E9E9E" /> : <Calendar1 size={48} color="#9E9E9E" />}
                <p className="mt-4 text-base font-semibold text-[#1F1F1F]">{searching ? t('לא נמצאו אירועים מתאימים', 'No events match your search') : t('אין אירועים קרובים', 'No upcoming events')}</p>
                {!searching && <p className="mt-2 text-sm text-gray-meta">{t('אירועים חדשים יופיעו כאן', 'New events will appear here')}</p>}
              </div>
            ) : (
              <div className="flex flex-col gap-3">
                {phoneList.map((e) => <MEventCard key={e.id} event={e} lang={lang} category={firstCategory(e)} />)}
              </div>
            )}
          </div>
        </section>
        {/* "View on Map", floating over the list above the bottom menu. */}
        <div className="pointer-events-none fixed inset-x-0 bottom-[92px] z-30 flex justify-center">
          <Link href="/events-map/" className="pointer-events-auto flex h-10 items-center gap-1.5 rounded-[50px] bg-white px-4 text-sm font-medium text-navy shadow-[0_4px_4px_rgba(0,0,0,0.15)]">
            <img src="/icons/m_events_map.svg" alt="" className="size-4" />
            {t('הצג במפה', 'View on Map')}
          </Link>
        </div>
      </div>
    </div>
  );
}

function CirclePhoto({ url, size }: { url: string | null; size: number }) {
  if (url) return <img src={url} alt="" width={size} height={size} loading="lazy" className="size-full object-cover" />;
  return (
    <span className="flex size-full items-center justify-center" style={{ background: 'linear-gradient(135deg, #0058B5, #010A36)' }}>
      <Calendar1 size={size > 100 ? 32 : 22} color="rgba(255,255,255,0.28)" variant="Bold" />
    </span>
  );
}
