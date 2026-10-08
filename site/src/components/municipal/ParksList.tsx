'use client';
import { useState } from 'react';
import Link from 'next/link';
import { Location, SearchNormal1, Setting4, Star1, Tree } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';

export type ParkItem = {
  id: string; href: string; name: string;
  /** The desktop card's line under the name: its description, else its
   *  category. */
  subtitle: string;
  /** The phone card's: its category, else its description. */
  kind: string;
  /** The desktop card's address falls back to the neighbourhood. */
  deskAddress: string;
  address: string;
  photo: string | null;
  rating: number;
  reviews: number;
};

type Sort = 'newest' | 'rating' | 'name';

/** The city's parks: the desktop's grid of the directory's cards, 24 at a
 *  time (web_business_list_screen.dart), and the phone's list with its
 *  search and filters (business_list_screen.dart). Every park is in the page;
 *  the controls only hide some. */
export function ParksList({ parks, lang, title }: { parks: ParkItem[]; lang: Lang; title: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  // Text the client typed reads in its own direction, on the page's side.
  const side = lang === 'he' ? 'text-right' : 'text-left';
  const [shown, setShown] = useState(24);
  const [q, setQ] = useState('');
  const [open, setOpen] = useState(false);
  const [minRating, setMinRating] = useState(0);
  const [sort, setSort] = useState<Sort>('newest');

  const needle = q.trim().toLowerCase();
  let list = parks.filter((p) => (!minRating || p.rating >= minRating)
    && (!needle || p.name.toLowerCase().includes(needle) || p.address.toLowerCase().includes(needle)));
  if (sort === 'rating') list = [...list].sort((a, b) => b.rating - a.rating || b.reviews - a.reviews);
  if (sort === 'name') list = [...list].sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
  const filtering = minRating > 0;

  const chip = (label: string, on: boolean, onClick: () => void) => (
    <button key={label} type="button" onClick={onClick}
      className={`rounded-full border px-4 py-2.5 text-sm font-medium ${on ? 'border-midblue bg-midblue text-white' : 'border-line bg-white text-[#3D3D3D]'}`}>
      {label}
    </button>
  );

  if (!parks.length) {
    return (
      <div className="flex h-80 flex-col items-center justify-center rounded-xl text-center desk:border desk:border-line">
        <Tree size={44} color="#5F5E5A80" />
        <p className="mt-4 text-lg font-semibold text-[#1C1C1E]">{t('עדיין לא נוספו פארקים', 'No parks listed yet')}</p>
        <p className="mt-2 text-sm text-gray-text">{t('פארקים יופיעו כאן ברגע שיתווספו', 'Parks will appear here as soon as they are added.')}</p>
      </div>
    );
  }

  return (
    <>
      {/* The phone's search and filter control. */}
      <div className="desk:hidden">
        <div className="flex h-12 items-center gap-2 rounded-full border border-line pe-1 ps-4">
          <SearchNormal1 size={18} color="#6D6D6D" />
          <input type="search" value={q} onChange={(e) => setQ(e.target.value)} placeholder={t(`חיפוש ב${title}...`, `Search ${title}...`)}
            className="min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-[#6D6D6D]" />
          <button type="button" onClick={() => setOpen(!open)} aria-expanded={open} aria-label={t('סינון', 'Filter')} className="relative p-2.5">
            <Setting4 size={20} color="#123A72" />
            {filtering && <span className="absolute end-2 top-2 size-2 rounded-full bg-turquoise" />}
          </button>
        </div>
        {open && (
          <div className="mt-3 rounded-2xl border border-line p-4">
            <div className="flex items-center justify-between">
              <span className="text-base font-semibold text-black">{t('סינון', 'Filter')}</span>
              {(filtering || sort !== 'newest') && (
                <button type="button" className="text-sm text-midblue" onClick={() => { setMinRating(0); setSort('newest'); }}>{t('נקו סינון', 'Clear filter')}</button>
              )}
            </div>
            <p className="mt-5 text-sm font-semibold text-[#3D3D3D]">{t('דירוג', 'Rating')}</p>
            <div className="mt-3 flex flex-wrap gap-2">
              {chip(t('הכל', 'All'), minRating === 0, () => setMinRating(0))}
              {[4, 3, 2, 1].map((s) => chip(`${s}★ ${t('ומעלה', '& up')}`, minRating === s, () => setMinRating(s)))}
            </div>
            <p className="mt-5 text-sm font-semibold text-[#3D3D3D]">{t('מיון', 'Sort by')}</p>
            <div className="mt-3 flex flex-wrap gap-2">
              {chip(t('חדש ביותר', 'Newest'), sort === 'newest', () => setSort('newest'))}
              {chip(t('דירוג', 'Rating'), sort === 'rating', () => setSort('rating'))}
              {chip(t('שם', 'Name'), sort === 'name', () => setSort('name'))}
            </div>
          </div>
        )}
        <p className="mt-5 flex items-center gap-2">
          <span className="flex size-8 items-center justify-center rounded-md bg-[#E8EEF7]"><Tree size={18} color="#123A72" /></span>
          <span className="truncate">
            <span className="text-base font-medium text-midblue">{list.length === 1 ? t('פארק אחד', '1 park') : t(`${list.length} פארקים`, `${list.length} parks`)}</span>
            <span className="text-sm text-[#6D6D6D]">{t(' במודיעין', ' in Modiin')}</span>
          </span>
        </p>
        {list.length === 0 && (
          <div className="py-10 text-center">
            <p className="text-sm text-[#3D3D3D]">{t('אין תוצאות לסינון הזה', 'Nothing here matches that filter')}</p>
            <button type="button" className="mt-3 text-sm text-midblue" onClick={() => { setMinRating(0); setSort('newest'); setQ(''); }}>{t('נקו סינון', 'Clear filter')}</button>
          </div>
        )}
      </div>

      <ul className="mt-4 grid grid-cols-1 gap-6 desk:mt-0 desk:grid-cols-3 min-[1250px]:grid-cols-4">
        {list.map((p, i) => (
          <li key={p.id} className={`min-w-0 ${i >= shown ? 'desk:hidden' : ''}`}>
            <Link href={p.href} className="block desk:h-[404px] desk:overflow-hidden desk:rounded-xl desk:border desk:border-line desk:bg-white">
              {p.photo
                ? <img src={p.photo} alt={p.name} loading="lazy" className="h-[200px] w-full rounded-xl object-cover desk:rounded-none" />
                : <span className="flex h-[200px] items-center justify-center rounded-xl bg-[linear-gradient(135deg,#123A7214,#123A720A)] desk:rounded-none"><Tree size={40} color="#123A72" /></span>}
              <span className="block pt-4 desk:p-4">
                <span dir="auto" className={`${side} block truncate font-nunito text-xl font-semibold leading-[1.25] text-navy desk:text-[#0A1230]`}>{p.name}</span>
                {p.kind && <span dir="auto" className={`${side} mt-2 block truncate text-sm text-gray-text desk:hidden`}>{p.kind}</span>}
                {p.subtitle && <span dir="auto" className={`${side} mt-2 hidden truncate text-sm text-gray-text desk:block`}>{p.subtitle}</span>}
                {p.address && (
                  <span className="mt-3 flex items-center gap-2 text-sm text-gray-text desk:hidden">
                    <Location size={16} color="#17A9D0" variant="Bold" className="shrink-0" /><span dir="auto" className={`${side} min-w-0 flex-1 truncate`}>{p.address}</span>
                  </span>
                )}
                {p.deskAddress && (
                  <span className="mt-4 hidden items-center gap-2 text-sm text-gray-text desk:flex">
                    <img src="/web/home/card_pin.svg" alt="" width={12} height={16} className="mx-0.5 shrink-0" /><span dir="auto" className={`${side} min-w-0 flex-1 truncate`}>{p.deskAddress}</span>
                  </span>
                )}
                {p.reviews === 0
                  ? <span className="mt-3 block text-sm text-[#6D6D6D] desk:mt-4">{t('אין דירוג עדיין', 'Not rated yet')}</span>
                  : (
                    <span className="mt-3 flex items-center gap-2 text-sm desk:mt-4">
                      <Star1 size={16} color="#FFC107" variant="Bold" />
                      <span className="font-medium text-black">{p.rating.toFixed(1)}</span>
                      <span className="text-[#6D6D6D]">({p.reviews})</span>
                    </span>
                  )}
              </span>
            </Link>
          </li>
        ))}
      </ul>

      {list.length > shown && (
        <div className="mt-8 hidden justify-center desk:flex">
          <button type="button" onClick={() => setShown(Math.min(shown + 24, list.length))}
            className="rounded-full border border-midblue px-10 py-4 text-base font-medium text-midblue">
            {t(`הצג עוד (נותרו ${list.length - shown})`, `Show more (${list.length - shown} left)`)}
          </button>
        </div>
      )}
    </>
  );
}
