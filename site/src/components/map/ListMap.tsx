'use client';
import { useMemo, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, ArrowRight, CloseCircle, Filter, RowVertical, SearchNormal1, SearchStatus } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { useDesk } from '@/components/municipal/useDesk';
import { MapView, type MapPin } from './MapView';

/** One place on a list-and-map page. The server draws its list row and its
 *  map card; the browser only narrows, orders and points. */
export type ListMapItem = {
  id: string; href: string; title: string;
  lat: number | null; lng: number | null; icon: string; size: [number, number];
  /** What the search box looks in, already lower case. */
  text: string;
  /** `<facet>:<value>` for every filter option the place answers. */
  tags: string[];
  /** A number per sort, smaller first. */
  sort: Record<string, number>;
  row: React.ReactNode;
  card: React.ReactNode;
};

/** A filter group: [single] picks one option (a radio), else any of several. */
export type Facet = { id: string; title: string; single?: boolean; options: { value: string; label: string }[] };

type Picked = Record<string, string[]>;

/** The current site's map pages (web_restaurants_map_screen.dart,
 *  web_events_map_screen.dart, web_realestate_map_screen.dart and their
 *  phone screens): on a desktop the filters, the list with its count and
 *  sort, and the map, a row lighting its pin; on a phone the map full size
 *  with a search pill, a filter sheet, the chosen place's card and "List
 *  view". A place with no coordinates stays in the list, marked so. */
export function ListMap({ lang, items, facets = [], sorts = [], heading, sub, listHref, placeholder, initial, emptyTitle, emptyBody }: {
  lang: Lang; items: ListMapItem[]; facets?: Facet[]; sorts?: { id: string; label: string }[];
  heading: [string, string]; sub?: string; listHref: string; placeholder: string;
  initial?: { q?: string; picked?: Picked; sort?: string };
  emptyTitle: string; emptyBody: string;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const desk = useDesk();
  const [q, setQ] = useState(initial?.q ?? '');
  const [picked, setPicked] = useState<Picked>(initial?.picked ?? {});
  const [sort, setSort] = useState(initial?.sort ?? sorts[0]?.id ?? '');
  const [selected, setSelected] = useState<string | null>(null);
  const [hover, setHover] = useState<string | null>(null);
  const [sheet, setSheet] = useState(false);

  const visible = useMemo(() => {
    const needle = q.trim().toLowerCase();
    const rows = items.filter((it) => (!needle || it.text.includes(needle))
      && facets.every((f) => !(picked[f.id]?.length) || picked[f.id].some((v) => it.tags.includes(`${f.id}:${v}`))));
    if (!sort) return rows;
    return rows.map((r, i) => [r, i] as const)
      .sort(([a, ai], [b, bi]) => (a.sort[sort] ?? Infinity) - (b.sort[sort] ?? Infinity) || ai - bi)
      .map(([r]) => r);
  }, [items, facets, picked, q, sort]);

  // Drawn once per result set, so a hover does not re-fit the map.
  const pins: MapPin[] = useMemo(() => visible.filter((it) => it.lat != null && it.lng != null)
    .map((it) => ({ id: it.id, lat: it.lat!, lng: it.lng!, icon: it.icon, size: it.size, label: it.title })), [visible]);

  const chosen = selected ? visible.find((it) => it.id === selected) : undefined;
  const filterCount = facets.reduce((n, f) => n + (picked[f.id]?.length ? 1 : 0), 0);
  const filtering = filterCount > 0 || q.trim() !== '';

  const toggle = (f: Facet, v: string) => setPicked((p) => {
    const cur = p[f.id] ?? [];
    const next = cur.includes(v) ? cur.filter((x) => x !== v) : f.single ? [v] : [...cur, v];
    return { ...p, [f.id]: next };
  });

  const Back = lang === 'he' ? ArrowRight : ArrowLeft;
  const count = t(heading[0], heading[1]).replace('{n}', String(visible.length));

  const empty = (
    <div className="flex flex-col items-center justify-center p-8 text-center">
      <SearchStatus size={44} color="rgba(109,109,109,0.5)" />
      <p className="mt-4 font-nunito text-lg font-semibold text-navy">{filtering ? t('אין תוצאות שתואמות את החיפוש', 'Nothing matches your search') : emptyTitle}</p>
      <p className="mt-2 text-sm text-gray-text">{filtering ? t('נסו להסיר סינון או לחפש משהו אחר.', 'Try clearing a filter or searching for something else.') : emptyBody}</p>
    </div>
  );

  const searchBox = (cls: string) => (
    <label className={`flex items-center gap-2 rounded-full border border-line bg-white px-4 ${cls}`}>
      <SearchNormal1 size={18} color="#6D6D6D" />
      <input value={q} onChange={(e) => { setQ(e.target.value); setSelected(null); }} placeholder={placeholder} aria-label={placeholder}
        className="min-w-0 flex-1 bg-transparent text-sm text-navy outline-none placeholder:text-[#6D6D6D]" />
      {q && <button type="button" onClick={() => setQ('')} aria-label={t('ניקוי', 'Clear')}><CloseCircle size={18} color="#6D6D6D" /></button>}
    </label>
  );

  const facetList = (
    <div className="flex flex-col gap-6">
      {facets.map((f) => (
        <fieldset key={f.id}>
          <legend className="text-sm font-semibold text-navy">{f.title}</legend>
          <div className="mt-3 flex flex-col gap-3">
            <Choice label={t('הכל', 'All')} on={!(picked[f.id]?.length)} round={f.single} onClick={() => setPicked((p) => ({ ...p, [f.id]: [] }))} />
            {f.options.map((o) => (
              <Choice key={o.value} label={o.label} on={!!picked[f.id]?.includes(o.value)} round={f.single} onClick={() => toggle(f, o.value)} />
            ))}
          </div>
        </fieldset>
      ))}
    </div>
  );

  const sortBox = sorts.length > 1 && (
    <label className="flex h-[42px] shrink-0 items-center gap-2 rounded-lg border border-line bg-white px-3 text-sm text-black">
      <span className="text-gray-text">{t('מיון:', 'Sort by:')}</span>
      <select value={sort} onChange={(e) => setSort(e.target.value)} className="bg-transparent font-medium outline-none">
        {sorts.map((s) => <option key={s.id} value={s.id}>{s.label}</option>)}
      </select>
    </label>
  );

  const card = chosen && (
    <div className="absolute inset-x-3 bottom-3 z-[600] mx-auto max-w-[420px] rounded-2xl bg-white p-3 shadow-[0_8px_30px_rgba(0,0,0,0.18)]">
      <button type="button" onClick={() => setSelected(null)} aria-label={t('סגירה', 'Close')} className="absolute end-2 top-2 z-10 rounded-full bg-white">
        <CloseCircle size={26} color="#123A72" />
      </button>
      {chosen.card}
      <Link href={chosen.href} className="mt-3 flex h-11 items-center justify-center rounded-full bg-midblue text-sm font-medium text-white">
        {t('לכל הפרטים', 'View full details')}
      </Link>
    </div>
  );

  const map = desk === null ? <div className="size-full animate-pulse bg-[#E8EAED]" /> : (
    <MapView pins={pins} lang={lang} zoom={13} recenter={desk} zoomButtons={desk} selectedId={selected} hoverId={hover}
      onPick={(p) => setSelected(p.id)} onMapClick={() => setSelected(null)} center={pins.length ? undefined : [31.8969, 35.0095]} />
  );

  return (
    <div className="flex h-[calc(100dvh-132px)] min-h-[480px] desk:h-[calc(100vh-81px)] desk:min-h-[600px]">
      {facets.length > 0 && (
        <aside className="hidden w-[294px] shrink-0 overflow-y-auto border-e border-line bg-surface p-5 desk:block">
          {searchBox('h-[42px] rounded-lg')}
          <div className="mt-5">{facetList}</div>
        </aside>
      )}

      <section className="hidden w-[min(600px,42vw)] shrink-0 flex-col border-e border-line desk:flex">
        <div className="flex items-start gap-4 px-6 pt-6">
          <div className="min-w-0 flex-1">
            <h1 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{count}</h1>
            {sub && <p className="mt-2 text-sm text-gray-text">{sub}</p>}
          </div>
          {sortBox}
          <Link href={listHref} className="flex h-[42px] shrink-0 items-center gap-2 rounded-lg border border-line bg-white px-3 text-sm text-midblue">
            <RowVertical size={18} color="currentColor" />{t('תצוגת רשימה', 'List View')}
          </Link>
        </div>
        {facets.length === 0 && <div className="px-6 pt-5">{searchBox('h-[44px]')}</div>}
        <ul className="mt-4 min-h-0 flex-1 overflow-y-auto px-6 pb-6">
          {visible.length === 0 ? <li>{empty}</li> : visible.map((it) => (
            <li key={it.id} onMouseEnter={() => setHover(it.id)} onMouseLeave={() => setHover((h) => (h === it.id ? null : h))}>
              <Link href={it.href} className={`block border-b border-line py-4 transition-colors ${hover === it.id || selected === it.id ? 'bg-surface' : 'hover:bg-surface'}`}>
                {it.row}
                {(it.lat == null || it.lng == null) && <span className="mt-2 inline-block text-xs text-gray-meta">{t('לא מופיע במפה', 'Not on the map')}</span>}
              </Link>
            </li>
          ))}
        </ul>
      </section>

      <div className="relative isolate min-w-0 flex-1">
        {map}
        {/* The phone's controls over the map. */}
        <div className="absolute inset-x-3 top-3 z-[600] flex items-center gap-2 desk:hidden">
          <Link href={listHref} aria-label={t('חזרה', 'Back')} className="flex size-12 shrink-0 items-center justify-center rounded-full bg-white shadow-md">
            <Back size={22} color="#0F161E" />
          </Link>
          {searchBox('h-12 flex-1 shadow-md')}
          {(facets.length > 0 || sorts.length > 1) && (
            <button type="button" onClick={() => setSheet(true)} aria-label={t('סינון', 'Filter')} className="relative flex size-12 shrink-0 items-center justify-center rounded-full bg-white shadow-md">
              <Filter size={22} color="#0F161E" />
              {filterCount > 0 && <span className="absolute end-1 top-1 size-2.5 rounded-full bg-turquoise" />}
            </button>
          )}
        </div>
        {desk === false && visible.length > 0 && pins.length === 0 && (
          <p className="absolute inset-x-3 top-20 z-[600] rounded-xl bg-white p-3 text-center text-sm text-gray-text shadow-md">{t('לאף תוצאה אין מיקום במפה', 'None of these has a place on the map')}</p>
        )}
        {desk === false && visible.length === 0 && <div className="absolute inset-x-3 top-20 z-[600] rounded-2xl bg-white shadow-md">{empty}</div>}
        {card}
        {!chosen && (
          <Link href={listHref} className="absolute bottom-4 left-1/2 z-[600] flex h-12 -translate-x-1/2 items-center gap-2 rounded-full bg-white px-6 text-sm font-medium text-ink shadow-md desk:hidden">
            <RowVertical size={18} color="currentColor" />{t('תצוגת רשימה', 'List View')}
          </Link>
        )}
      </div>

      {sheet && (
        <div className="fixed inset-0 z-[1000] flex flex-col justify-end desk:hidden" role="dialog" aria-modal aria-label={t('סינון', 'Filter')}>
          <button type="button" className="flex-1 bg-black/40" aria-label={t('סגירה', 'Close')} onClick={() => setSheet(false)} />
          <div className="max-h-[80dvh] overflow-y-auto rounded-t-3xl bg-white p-5 pb-[calc(20px+env(safe-area-inset-bottom))]">
            <div className="mb-5 flex items-center justify-between">
              <p className="font-nunito text-lg font-semibold text-navy">{t('סינון', 'Filters')}</p>
              <button type="button" onClick={() => { setPicked({}); setSort(sorts[0]?.id ?? ''); }} className="text-sm font-medium text-turquoise">{t('איפוס', 'Reset')}</button>
            </div>
            {sorts.length > 1 && (
              <fieldset className="mb-6">
                <legend className="text-sm font-semibold text-navy">{t('מיון', 'Sort')}</legend>
                <div className="mt-3 flex flex-col gap-3">
                  {sorts.map((s) => <Choice key={s.id} label={s.label} on={sort === s.id} round onClick={() => setSort(s.id)} />)}
                </div>
              </fieldset>
            )}
            {facetList}
            <button type="button" onClick={() => setSheet(false)} className="mt-6 flex h-12 w-full items-center justify-center rounded-full bg-midblue text-base font-medium text-white">
              {t(`הצגת ${visible.length} תוצאות`, `Show ${visible.length} results`)}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function Choice({ label, on, round, onClick }: { label: string; on: boolean; round?: boolean; onClick: () => void }) {
  return (
    <button type="button" role={round ? 'radio' : 'checkbox'} aria-checked={on} onClick={onClick} className="flex w-full items-center gap-2 text-start">
      <span className={`flex size-4 shrink-0 items-center justify-center border ${round ? 'rounded-full' : 'rounded-[4px]'} ${on ? 'border-midblue bg-midblue' : 'border-[#BDBDBD] bg-white'}`}>
        {on && (round ? <span className="size-1.5 rounded-full bg-white" /> : <svg width="10" height="10" viewBox="0 0 12 12" aria-hidden><path d="M2 6.5 5 9l5-6" stroke="#fff" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>)}
      </span>
      <span className="min-w-0 flex-1 truncate text-[13px] text-[#3D3D3D]">{label}</span>
    </button>
  );
}
