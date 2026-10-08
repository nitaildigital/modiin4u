import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { breadcrumb, h1For, pageMetadata, SITE_NAME, SUFFIX } from '@/lib/seo';
import { search } from '@/lib/data/search';
import { JsonLd } from '@/components/JsonLd';
import { DeskSearchBox, PhoneSearchBox } from '@/components/search/SearchBox';
import { DeskResults, PhoneResults, SearchNotice } from '@/components/search/SearchResults';

type Props = { searchParams: Promise<{ q?: string | string[] }> };

const PATH = '/search/';

const queryOf = async (sp: Props['searchParams']) => {
  const q = (await sp).q;
  return (Array.isArray(q) ? q[0] : q ?? '').trim().slice(0, 100);
};

/** A results page is not a page for Google: noindex, whatever was asked. */
export async function generateMetadata({ searchParams }: Props): Promise<Metadata> {
  const q = await queryOf(searchParams);
  const t = tr(await getLang());
  return pageMetadata({ path: PATH, title: t('תוצאות חיפוש', 'Search Results') + (q ? ` "${q}"` : '') + SUFFIX, noindex: true });
}

/** /search/?q=… (web_search_results_screen.dart on a desktop,
 *  search_results_screen.dart on a phone): businesses, events, deals,
 *  listings and news matching the words, read on the server. */
export default async function SearchPage({ searchParams }: Props) {
  const q = await queryOf(searchParams);
  const lang = await getLang();
  const t = tr(lang);
  const hits = q ? await search(q, lang) : [];
  const n = hits.length;
  const heading = h1For(PATH, t('תוצאות חיפוש', 'Search Results'));

  return (
    <div className="pb-10 desk:pb-[100px]">
      <JsonLd data={[
        { '@context': 'https://schema.org', '@type': 'SearchResultsPage', name: heading },
        breadcrumb([[SITE_NAME, '/'], ['תוצאות חיפוש', PATH]]),
      ]} />

      <div className="wrap pt-4 desk:pt-14">
        <h1 className="text-center font-rubik text-xl font-bold text-navy desk:text-start desk:font-nunito desk:text-4xl desk:font-semibold desk:leading-[1.2] desk:text-midblue">{heading}</h1>

        {/* Desktop: the line under the heading, and the bar. */}
        <div className="hidden desk:block">
          <p className="mt-2 text-sm leading-[1.21] text-gray-text">
            {!q
              ? t('חפשו עסקים, אירועים וחדשות במודיעין.', 'Search businesses, events and news across Modiin.')
              : n === 1 ? t(`תוצאה אחת עבור "${q}"`, `1 result for "${q}"`) : t(`${n} תוצאות עבור "${q}"`, `${n} results for "${q}"`)}
          </p>
          <div className="mt-7">
            <DeskSearchBox q={q} placeholder={t('חפשו עסקים, אירועים, חדשות...', 'Search businesses, events, news...')} button={t('חיפוש', 'Search')} />
          </div>
          <div className="mt-10">
            {!q
              ? <SearchNotice icon="search" title={t('עדיין לא חיפשתם', 'Nothing searched yet')} body={t('הקלידו שם, מקום או מילה בשורה שלמעלה.', 'Type a name, a place or a word above.')} />
              : n === 0
                ? <SearchNotice title={t('לא נמצאו תוצאות', 'No results found')}
                    body={t(`לא נמצא דבר במדריך, באירועים או בחדשות שתואם ל"${q}".`, `Nothing in the directory, the events or the news matches "${q}".`)} />
                : <DeskResults hits={hits} lang={lang} />}
          </div>
        </div>
      </div>

      {/* Phone: the pill with the words and the count, then the rows. */}
      <div className="mt-2 desk:hidden">
        <PhoneSearchBox q={q} placeholder={t('הכל', 'All')} count={q ? t(`${n} תוצאות`, `${n} results`) : ''} />
        {n > 0
          ? <PhoneResults hits={hits} lang={lang} />
          : (
            <div className="flex flex-col items-center px-8 py-16 text-center">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" aria-hidden><path d="M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16ZM21 21l-4.3-4.3M8.5 8.5l5 5m0-5-5 5" stroke="rgba(136,135,128,.4)" strokeWidth="1.6" strokeLinecap="round" /></svg>
              <p className="mt-4 font-rubik text-base font-semibold text-navy">{t('לא נמצאו תוצאות', 'No results found')}</p>
              <p className="mt-2 font-rubik text-sm text-gray-meta">{t('נסו חיפוש אחר', 'Try a different search')}</p>
            </div>
          )}
      </div>
    </div>
  );
}
