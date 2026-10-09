'use client';
import { useMemo, useState } from 'react';
import { Shop } from 'iconsax-react';
import { BusinessCard, type BizCard } from './BusinessCard';
import { FilterPill, ShowMore } from './ListControls';

/** How many cards show before "Show more": all 232 at once would put the
 *  sections under the grid out of reach. Every card is in the page for
 *  search engines; the rest wait, hidden, for the button. */
const PAGE = 24;

/** The directory's results (web_businesses_screen _buildResultsSection; on a
 *  phone businesses_screen's list): the count, the Kosher and Delivery pills,
 *  and the cards. The search at the top suggests and opens the search
 *  results instead of narrowing these (DirectorySearch). */
export function DirectoryResults({ items, lang }: { items: { card: BizCard; search: string }[]; lang: 'he' | 'en' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [filter, setFilter] = useState<-1 | 0 | 1>(-1);
  const [shown, setShown] = useState(PAGE);

  const visible = useMemo(() => {
    return new Set(items.filter(({ card }) => (filter !== 0 || !!card.kosher) && (filter !== 1 || card.delivery))
      .map(({ card }) => card.id));
  }, [items, filter]);
  const count = visible.size;
  let n = 0;

  return (
    <section className="mt-7 desk:mt-20">
      <div className="hidden desk:block">
        <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{t('כל העסקים במודיעין', 'All Businesses in Modiin')}</h2>
        <p className="mt-2.5 text-sm text-gray-text">{count === 1 ? t('נמצא עסק אחד', '1 business found') : t(`נמצאו ${count} עסקים`, `${count} businesses found`)}</p>
        <div className="mt-6 flex flex-wrap gap-3">
          <FilterPill on={filter === 0} onClick={() => { setFilter(filter === 0 ? -1 : 0); setShown(PAGE); }}>{t('כשר', 'Kosher')}</FilterPill>
          <FilterPill on={filter === 1} onClick={() => { setFilter(filter === 1 ? -1 : 1); setShown(PAGE); }}>{t('משלוחים', 'Delivery')}</FilterPill>
        </div>
      </div>
      <h2 className="font-rubik text-lg font-semibold text-black desk:hidden">{t('כל העסקים', 'All Businesses')}</h2>

      {count === 0 ? (
        <div className="mt-3 flex h-80 flex-col items-center justify-center rounded-xl border border-line px-4 text-center desk:mt-8">
          <Shop size={44} color="#5F5E5A80" />
          <p className="mt-4 text-lg font-semibold text-[#1C1C1E]">{t('לא נמצאו עסקים שתואמים לסינון', 'No businesses match this filter')}</p>
          <p className="mt-2 text-sm text-gray-text">{t('נסו סינון אחר.', 'Try a different filter.')}</p>
          <button type="button" onClick={() => setFilter(-1)} className="mt-5 rounded-full bg-midblue px-7 py-3 text-sm font-medium text-white">{t('איפוס סינון', 'Reset filters')}</button>
        </div>
      ) : (
        <div className="mt-3 flex flex-col gap-3 desk:mt-8 desk:grid desk:grid-cols-3 desk:gap-6 min-[1374px]:grid-cols-4">
          {items.map(({ card }) => {
            const on = visible.has(card.id) && n++ < shown;
            return <div key={card.id} className={on ? '' : 'hidden'}><BusinessCard b={card} lang={lang} variant="tile" /></div>;
          })}
        </div>
      )}
      {count > shown && (
        <ShowMore onClick={() => setShown(shown + PAGE)}>{t(`הצג עוד (נותרו ${count - shown})`, `Show more (${count - shown} left)`)}</ShowMore>
      )}
    </section>
  );
}
