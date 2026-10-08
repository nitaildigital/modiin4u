'use client';
import { useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { FilterRemove, SearchNormal1, Setting4, Shop } from 'iconsax-react';
import { BusinessCard, type BizCard } from './BusinessCard';
import { Chip, FilterPill, ShowMore } from './ListControls';

export type ListItem = {
  card: BizCard;
  /** Name and address, lower-cased, for the phone's search. */
  search: string;
  /** Its food categories with their parents, for the cuisine filter. */
  cuisines: string[];
};

type Sort = 'newest' | 'rating' | 'name';
const PAGE = 24;

/** One category's businesses (web_business_list_screen; on a phone
 *  business_list_screen): at desktop width the count, the Kosher and
 *  Delivery pills and the grid; on a phone the search box with the filter
 *  sheet — cuisine on the restaurants list, kosher, rating, delivery and the
 *  order — the count, and one photograph card a row.
 *
 *  `?q=`, `?sort=rating`, `?delivery=1` and `?kosher=kosher` open it
 *  narrowed, for the Restaurants page's "View all" links. */
export function BusinessList({ items, lang, title, cuisines = [] }: {
  items: ListItem[]; lang: 'he' | 'en'; title: string; cuisines?: { slug: string; name: string }[];
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const params = useSearchParams();
  const [query, setQuery] = useState(params.get('q') ?? '');
  const [kosher, setKosher] = useState<'all' | 'kosher' | 'not'>(params.get('kosher') === 'kosher' ? 'kosher' : params.get('kosher') === 'not' ? 'not' : 'all');
  const [delivery, setDelivery] = useState(params.get('delivery') === '1');
  const [minRating, setMinRating] = useState(0);
  const [picked, setPicked] = useState<Set<string>>(new Set());
  const [sort, setSort] = useState<Sort>(params.get('sort') === 'rating' ? 'rating' : params.get('sort') === 'name' ? 'name' : 'newest');
  const [shown, setShown] = useState(PAGE);
  const [sheet, setSheet] = useState(false);

  const filtering = kosher !== 'all' || delivery || minRating > 0 || picked.size > 0;
  const clear = () => { setKosher('all'); setDelivery(false); setMinRating(0); setPicked(new Set()); setSort('newest'); };

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    const kept = items.filter(({ card, search, cuisines: mine }) =>
      (kosher !== 'kosher' || !!card.kosher) && (kosher !== 'not' || !card.kosher)
      && (!delivery || card.delivery) && (minRating === 0 || card.rating >= minRating)
      && (picked.size === 0 || mine.some((c) => picked.has(c)))
      && (!q || search.includes(q)));
    // They arrive newest first; rating ties go to the place with more reviews.
    if (sort === 'rating') kept.sort((a, b) => b.card.rating - a.card.rating || b.card.reviews - a.card.reviews);
    if (sort === 'name') kept.sort((a, b) => a.card.name.localeCompare(b.card.name, lang));
    return kept;
  }, [items, query, kosher, delivery, minRating, picked, sort, lang]);
  const ids = list.map((i) => i.card.id);
  const order = new Map(ids.map((id, i) => [id, i]));

  // Desktop's two pills are the same filters as the sheet's.
  const pill = kosher === 'kosher' && !delivery ? 0 : delivery && kosher === 'all' ? 1 : -1;
  const setPill = (i: 0 | 1) => {
    const off = pill === i;
    setKosher(!off && i === 0 ? 'kosher' : 'all');
    setDelivery(!off && i === 1);
    setShown(PAGE);
  };

  const empty = items.length === 0;
  return (
    <>
      {/* Desktop: the count and the pills. */}
      <div className="hidden desk:block">
        <p className="mt-2.5 text-sm text-gray-text">{list.length === 1 ? t('נמצא עסק אחד', '1 business found') : t(`נמצאו ${list.length} עסקים`, `${list.length} businesses found`)}</p>
        <div className="mt-6 flex flex-wrap gap-3">
          <FilterPill on={pill === 0} onClick={() => setPill(0)}>{t('כשר', 'Kosher')}</FilterPill>
          <FilterPill on={pill === 1} onClick={() => setPill(1)}>{t('משלוחים', 'Delivery')}</FilterPill>
          {/* A search brought from the Restaurants page, shown so it can be undone. */}
          {query.trim() && <FilterPill on onClick={() => setQuery('')}>{`“${query.trim()}” ✕`}</FilterPill>}
        </div>
      </div>

      {/* Phone: the search box with the filter control, then the count. */}
      <div className="desk:hidden">
        <div className="mt-1 flex h-12 items-center gap-2 rounded-full border border-line pe-1 ps-4">
          <SearchNormal1 size={18} color="#6D6D6D" className="shrink-0" />
          <input type="search" enterKeyHint="search" value={query} onChange={(e) => setQuery(e.target.value)}
            placeholder={t(`חיפוש ב${title}...`, `Search ${title}...`)} aria-label={t(`חיפוש ב${title}`, `Search ${title}`)}
            className="h-full min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-[#6D6D6D] [&::-webkit-search-cancel-button]:hidden" />
          <button type="button" onClick={() => setSheet(true)} aria-label={t('סינון', 'Filter')} className="relative grid size-10 place-items-center">
            <Setting4 size={20} color="#123A72" />
            {filtering && <span className="absolute end-2 top-2 size-2 rounded-full bg-turquoise" />}
          </button>
        </div>
        {!empty && (
          <p className="mt-5 flex items-center gap-2">
            <span className="grid size-8 shrink-0 place-items-center rounded-md bg-[#E8EEF7]"><Shop size={18} color="#123A72" /></span>
            <span className="truncate">
              <span className="text-base font-medium text-midblue">{list.length} {title}</span>
              <span className="text-sm text-[#6D6D6D]">{t(' במודיעין', ' in Modiin')}</span>
            </span>
          </p>
        )}
      </div>

      {empty || list.length === 0 ? (
        <div className="mt-8 flex h-80 flex-col items-center justify-center rounded-xl border border-line px-4 text-center">
          {empty ? <Shop size={44} color="#5F5E5A80" /> : <FilterRemove size={44} color="#5F5E5A80" />}
          <p className="mt-4 text-lg font-semibold text-[#1C1C1E]">
            {empty ? t('אין עסקים להצגה', 'No businesses to show') : t('אין תוצאות לסינון הזה', 'Nothing here matches that filter')}
          </p>
          <p className="mt-2 text-sm text-gray-text">
            {empty ? t('עסקים יופיעו כאן ברגע שיתווספו', 'Businesses will appear here as soon as they are added.')
              : t('נקו את הסינון כדי לראות את כל הקטגוריה.', 'Clear the filter to see everything in this category.')}
          </p>
          {!empty && (
            <button type="button" onClick={() => { clear(); setQuery(''); }} className="mt-5 rounded-full bg-midblue px-7 py-3 text-sm font-medium text-white">
              {t('נקו סינון', 'Clear filter')}
            </button>
          )}
        </div>
      ) : (
        <div className="mt-4 flex flex-col gap-6 desk:mt-8 desk:grid desk:grid-cols-3 min-[1374px]:grid-cols-4">
          {/* Every card stays in the page in the directory's order; the
              filters hide and reorder them. */}
          {items.map(({ card }) => {
            const at = order.get(card.id);
            const on = at !== undefined && at < shown;
            return <div key={card.id} style={{ order: at ?? 0 }} className={on ? '' : 'hidden'}><BusinessCard b={card} lang={lang} variant="place" /></div>;
          })}
        </div>
      )}
      {list.length > shown && (
        <ShowMore onClick={() => setShown(shown + PAGE)}>{t(`הצג עוד (נותרו ${list.length - shown})`, `Show more (${list.length - shown} left)`)}</ShowMore>
      )}

      {sheet && (
        <div className="fixed inset-0 z-50 bg-black/40 desk:hidden" onClick={() => setSheet(false)}>
          <div role="dialog" aria-label={t('סינון', 'Filter')} onClick={(e) => e.stopPropagation()}
            className="absolute inset-x-0 bottom-0 max-h-[85vh] overflow-y-auto rounded-t-[20px] bg-white px-4 pb-8 pt-5">
            <div className="flex items-center">
              <p className="flex-1 text-base font-semibold text-black">{t('סינון', 'Filter')}</p>
              {(filtering || sort !== 'newest') && <button type="button" onClick={clear} className="text-sm text-midblue">{t('נקו סינון', 'Clear filter')}</button>}
            </div>
            {cuisines.length > 0 && (
              <Section title={t('סוג מטבח', 'Cuisine')}>
                <Chip on={picked.size === 0} onClick={() => setPicked(new Set())}>{t('כל סוגי המטבח', 'All Cuisines')}</Chip>
                {cuisines.map((c) => (
                  <Chip key={c.slug} on={picked.has(c.slug)} onClick={() => {
                    const next = new Set(picked);
                    if (next.has(c.slug)) next.delete(c.slug); else next.add(c.slug);
                    setPicked(next);
                  }}>{c.name}</Chip>
                ))}
              </Section>
            )}
            <Section title={t('כשרות', 'Kosher')}>
              <Chip on={kosher === 'all'} onClick={() => setKosher('all')}>{t('הכל', 'All')}</Chip>
              <Chip on={kosher === 'kosher'} onClick={() => setKosher('kosher')}>{t('כשר', 'Kosher')}</Chip>
              <Chip on={kosher === 'not'} onClick={() => setKosher('not')}>{t('לא כשר', 'Not Kosher')}</Chip>
            </Section>
            <Section title={t('דירוג', 'Rating')}>
              <Chip on={minRating === 0} onClick={() => setMinRating(0)}>{t('הכל', 'All')}</Chip>
              {[4, 3, 2, 1].map((s) => <Chip key={s} on={minRating === s} onClick={() => setMinRating(s)}>{`${s}★ ${t('ומעלה', '& up')}`}</Chip>)}
            </Section>
            <Section title={t('אפשרויות הגשה', 'Dining Options')}>
              <Chip on={delivery} onClick={() => setDelivery(!delivery)}>{t('משלוחים', 'Delivery')}</Chip>
            </Section>
            <Section title={t('מיון', 'Sort by')}>
              <Chip on={sort === 'newest'} onClick={() => setSort('newest')}>{t('חדש ביותר', 'Newest')}</Chip>
              <Chip on={sort === 'rating'} onClick={() => setSort('rating')}>{t('דירוג', 'Rating')}</Chip>
              <Chip on={sort === 'name'} onClick={() => setSort('name')}>{t('שם', 'Name')}</Chip>
            </Section>
          </div>
        </div>
      )}
    </>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mt-5">
      <p className="text-sm font-semibold text-[#3D3D3D]">{title}</p>
      <div className="mt-3 flex flex-wrap gap-2">{children}</div>
    </div>
  );
}
