'use client';
import { useMemo, useRef, useState, useEffect } from 'react';
import Link from 'next/link';
import { Calendar1, SearchStatus } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import type { EventCard, EventCategory } from '@/lib/data/events';
import { MapView, type MapPin } from '@/components/map/MapView';
import { useDebounced } from '@/lib/useDebounced';
import { Photo } from './Photo';
import { address, categoryLabel, dayOfMonth, eventPrice, shortMonth, timeRange } from './labels';

type Sort = 'newest' | 'soonest';

function bySoonest(a: EventCard, b: EventCard): number {
  // Rows without a date sort last, rather than jumping to the top.
  if (a.starts == null || b.starts == null) return a.starts == null ? (b.starts == null ? 0 : 1) : -1;
  return a.starts - b.starts;
}

/** The website's events browser that a category circle opens
 *  (web_events_category_screen.dart, `/events/?category=`): the filters on
 *  the start side, the matching upcoming events in the middle, and each one
 *  pinned on the map. Every count is of the upcoming events that option
 *  would show. */
export function EventsCategoryBrowser({ lang, events, categories, byEvent, initialFilter, headingOverride, eventHref }: {
  lang: Lang; events: EventCard[]; categories: EventCategory[]; byEvent: Record<string, EventCategory[]>;
  initialFilter: string; headingOverride?: string | null; eventHref: Record<string, string>;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [picked, setPicked] = useState<Set<string>>(() =>
    initialFilter && initialFilter !== 'all' && initialFilter !== 'free' ? new Set([initialFilter]) : new Set());
  const [price, setPrice] = useState<'all' | 'free' | 'paid'>(initialFilter === 'free' ? 'free' : 'all');
  const [sort, setSort] = useState<Sort>('newest');
  const [sortOpen, setSortOpen] = useState(false);
  const [place, setPlace] = useState('');
  const sortRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!sortOpen) return;
    const close = (ev: MouseEvent) => { if (!sortRef.current?.contains(ev.target as Node)) setSortOpen(false); };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [sortOpen]);

  const inCategory = (e: EventCard, id: string) => (byEvent[e.id] ?? []).some((c) => c.id === id);
  const free = events.filter((e) => e.is_free).length;
  // A category with nothing coming is left off, unless it is the one the
  // page was opened on.
  const shown = categories
    .map((c) => ({ c, n: events.filter((e) => inCategory(e, c.id)).length }))
    .filter(({ c, n }) => n > 0 || picked.has(c.slug));

  // The list and the map follow the location box when typing pauses.
  const placeQuery = useDebounced(place);
  const visible = useMemo(() => {
    const q = placeQuery.trim().toLowerCase();
    const rows = events.filter((e) =>
      (picked.size === 0 || (byEvent[e.id] ?? []).some((c) => picked.has(c.slug))) &&
      (price === 'all' || (price === 'free' ? e.is_free : !e.is_free)) &&
      // "Search by location" looks at the venue and the address, nothing else.
      (!q || (e.venue_name ?? '').toLowerCase().includes(q) || (e.address ?? '').toLowerCase().includes(q)));
    return rows.sort((a, b) => {
      if (sort === 'soonest') return bySoonest(a, b);
      // Newest: the most recently published first.
      const x = a.published_at ? Date.parse(a.published_at) : null;
      const y = b.published_at ? Date.parse(b.published_at) : null;
      if (x == null || y == null) return x == null ? (y == null ? bySoonest(a, b) : 1) : -1;
      return y - x || bySoonest(a, b);
    });
  }, [events, byEvent, picked, price, placeQuery, sort]);

  const only = picked.size === 1 ? categories.find((c) => picked.has(c.slug)) : undefined;
  const name = only ? categoryLabel(only, lang) : null;
  const headline = headingOverride || (name
    ? t(`נמצאו ${visible.length} אירועים בקטגוריית ${name}`, `${visible.length} ${name} Events found`)
    : t(`נמצאו ${visible.length} אירועים`, `${visible.length} Events found`));
  const filtering = place.trim() !== '' || price !== 'all' || picked.size > 0;

  // An online event, or one with no coordinates, gets no pin. Made again only
  // when the results change: the map re-frames (and loads tiles) on a new set
  // of pins, and was doing so on every render — opening the sort, a hover.
  const pins: MapPin[] = useMemo(() => visible
    .filter((e) => !e.is_online && e.latitude && e.longitude)
    .map((e) => ({ id: e.id, lat: e.latitude!, lng: e.longitude!, icon: '/web/events/map_pin.svg', size: [40, 43] as [number, number], href: eventHref[e.id], label: e.title })),
  [visible, eventHref]);

  const toggle = (slug: string) => setPicked((s) => {
    const next = new Set(s);
    if (!next.delete(slug)) next.add(slug);
    return next;
  });

  return (
    <div className="hidden h-[calc(100vh-81px)] min-h-[600px] desk:flex">
      {/* ── Filters ── */}
      <aside className="w-[294px] shrink-0 overflow-y-auto border-e border-line bg-surface p-5">
        <label className="flex h-[42px] items-center gap-2 rounded-lg border border-line bg-white px-3">
          <img src="/web/events/search_location.svg" alt="" className="size-4" />
          <input value={place} onChange={(e) => setPlace(e.target.value)} placeholder={t('חיפוש לפי מיקום...', 'Search by location...')}
            className="min-w-0 flex-1 bg-transparent text-sm text-navy outline-none placeholder:text-[#6D6D6D]" />
        </label>
        <p className="mt-4 text-sm font-semibold leading-[17px] text-navy">{t('קטגוריית אירוע', 'Event Category')}</p>
        <div className="mt-[17px] flex flex-col gap-3.5">
          <Check label={t('כל האירועים', 'All Events')} count={events.length} on={picked.size === 0} onClick={() => setPicked(new Set())} />
          {shown.map(({ c, n }) => <Check key={c.id} label={categoryLabel(c, lang)} count={n} on={picked.has(c.slug)} onClick={() => toggle(c.slug)} />)}
        </div>
        <p className="mt-6 text-sm font-semibold leading-[17px] text-navy">{t('מחיר', 'Price')}</p>
        <div className="mt-[17px] flex flex-col gap-3.5">
          <Check label={t('הכל', 'All')} count={events.length} on={price === 'all'} onClick={() => setPrice('all')} />
          <Check label={t('חינם', 'Free')} count={free} on={price === 'free'} onClick={() => setPrice(price === 'free' ? 'all' : 'free')} />
          <Check label={t('בתשלום', 'Paid')} count={events.length - free} on={price === 'paid'} onClick={() => setPrice(price === 'paid' ? 'all' : 'paid')} />
        </div>
      </aside>

      {/* ── Results: 900 of 1626 as drawn; the map gives way first ── */}
      <section className="flex min-h-0 shrink-0 flex-col border-e border-line"
        style={{ width: 'clamp(min(720px, calc(100vw - 654px)), calc((100vw - 294px) * 900 / 1626), calc(100vw - 654px))' }}>
        <div className="flex items-center gap-4 pe-[25px] ps-6 pt-6">
          <div className="min-w-0 flex-1">
            <h1 className="truncate font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{headline}</h1>
            <p className="mt-2 text-sm leading-[17px] text-gray-text">{t('במודיעין מכבים רעות', 'in Modiin Maccabim Reut')}</p>
          </div>
          <div ref={sortRef} className="relative">
            <button type="button" onClick={() => setSortOpen((o) => !o)} aria-expanded={sortOpen}
              className="flex h-[42px] min-w-[166px] items-center justify-between gap-[13px] rounded-lg border border-line bg-white px-3 text-sm text-black">
              {sort === 'newest' ? t('מיון: החדשים ביותר', 'Sort by: Newest') : t('מיון: הקרובים ביותר', 'Sort by: Soonest')}
              <img src="/web/events/chevron_down.svg" alt="" className="size-5" />
            </button>
            {sortOpen && (
              <div className="absolute end-0 top-[46px] z-[500] min-w-full overflow-hidden rounded-lg border border-line bg-white py-1 shadow-lg">
                {(['newest', 'soonest'] as Sort[]).map((s) => (
                  <button key={s} type="button" onClick={() => { setSort(s); setSortOpen(false); }}
                    className={`block w-full px-4 py-2.5 text-start text-sm hover:bg-surface ${s === sort ? 'font-semibold text-midblue' : 'text-black'}`}>
                    {s === 'newest' ? t('החדשים ביותר', 'Newest') : t('הקרובים ביותר', 'Soonest')}
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
        <div className="mt-[26px] min-h-0 flex-1 overflow-y-auto pb-6 pe-[25px] ps-6">
          {visible.length === 0 ? (
            <div className="flex h-full flex-col items-center justify-center p-8 text-center">
              {filtering ? <SearchStatus size={48} color="rgba(109,109,109,0.5)" /> : <Calendar1 size={48} color="rgba(109,109,109,0.5)" />}
              <p className="mt-4 font-nunito text-xl font-semibold text-navy">{filtering ? t('אין אירועים שתואמים את הסינון', 'No events match your filters') : t('עדיין לא פורסמו אירועים', 'No events listed yet')}</p>
              <p className="mt-2 text-sm text-gray-text">{filtering ? t('נסו להסיר סינון או לחפש מקום אחר.', 'Try clearing a filter or searching for somewhere else.') : t('אירועים חדשים יופיעו כאן עם פרסומם.', 'New events will appear here as they are published.')}</p>
            </div>
          ) : visible.map((e) => <Row key={e.id} event={e} lang={lang} link={eventHref[e.id]} />)}
        </div>
      </section>

      {/* ── The map ── */}
      {/* Its own stacking context, so Leaflet's layers stay under the header. */}
      <div className="relative isolate min-w-0 flex-1">
        <MapView pins={pins} lang={lang} zoom={pins.length === 1 ? 15 : 14} center={pins.length ? undefined : [31.8928, 35.0104]} />
      </div>
    </div>
  );
}

function Check({ label, count, on, onClick }: { label: string; count: number; on: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} aria-pressed={on} className="flex w-full items-center gap-2 text-start">
      <img src={on ? '/web/events/check_on.svg' : '/web/events/check_off.svg'} alt="" className="size-4 shrink-0" />
      <span className="min-w-0 flex-1 truncate text-[13px] leading-4 text-[#3D3D3D]">{label}</span>
      <span className="w-[68px] shrink-0 text-end text-[13px] leading-4 text-[#3D3D3D]">{count}</span>
    </button>
  );
}

/** One result, 203 tall: the photo with its date, then the title, time and
 *  place, the price, the interest count and "View Detail". */
function Row({ event: e, lang, link }: { event: EventCard; lang: Lang; link: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const time = timeRange(e, lang);
  const place = address(e, lang);
  const price = eventPrice(e, lang);
  return (
    <Link href={link} className="flex border-b border-line py-5 transition-colors hover:bg-surface">
      <div className="relative h-[162px] w-[261px] shrink-0">
        <Photo url={e.image} alt={e.title} className="size-full rounded-xl" icon={Calendar1} iconSize={30} />
        {e.start_date && (
          <span className="absolute start-2 top-2 flex w-[52px] flex-col items-center gap-1 rounded-lg bg-white px-1 py-2">
            <span className="text-xs font-medium leading-[15px] text-midblue">{shortMonth(e.start_date, lang)}</span>
            <span className="text-lg font-semibold leading-[22px] text-black">{dayOfMonth(e.start_date)}</span>
          </span>
        )}
      </div>
      <div className="ms-6 flex h-[162px] min-w-0 flex-1 flex-col justify-between">
        <div className="min-w-0">
          <p className="truncate font-nunito text-lg font-semibold leading-[22px] text-navy">{e.title}</p>
          {time && <RowMeta icon="/web/events/row_clock.svg" text={time} ltr />}
          {place && <RowMeta icon="/web/events/row_pin.svg" text={place} />}
        </div>
        <div className="flex items-center">
          {price && (
            <span className="flex shrink-0 flex-col">
              <span className="text-sm leading-[17px] text-gray-text">{t('מחיר', 'Price')}</span>
              <span className={`mt-1 whitespace-nowrap font-nunito text-[22px] font-semibold leading-[27px] ${e.is_free ? 'text-midblue' : 'text-navy'}`}>{price}</span>
            </span>
          )}
          <span className="mx-5 flex min-w-0 flex-1 items-center justify-end gap-2">
            {e.rsvp_count > 0 && (
              <>
                <img src="/web/events/row_people.svg" alt="" className="size-3.5 shrink-0" />
                <span className="truncate text-xs leading-[15px] text-[#3D3D3D]">
                  <span className="text-black">{e.rsvp_count} </span>
                  {e.rsvp_count === 1 ? t('מתעניין', 'person interested') : t('מתעניינים', 'people interested')}
                </span>
              </>
            )}
          </span>
          <span className="flex h-10 shrink-0 items-center gap-2 rounded-[60px] border border-midblue bg-white px-4 text-sm font-medium leading-6 text-midblue">
            <img src="/web/events/row_eye.svg" alt="" className="size-4" />
            {t('לפרטים', 'View Detail')}
          </span>
        </div>
      </div>
    </Link>
  );
}

function RowMeta({ icon, text, ltr = false }: { icon: string; text: string; ltr?: boolean }) {
  return (
    <span className="mt-3 flex items-center gap-2">
      <img src={icon} alt="" className="size-3.5 shrink-0" />
      <span dir={ltr ? 'ltr' : undefined} className="truncate text-xs leading-[15px] text-[#3D3D3D]">{text}</span>
    </span>
  );
}
