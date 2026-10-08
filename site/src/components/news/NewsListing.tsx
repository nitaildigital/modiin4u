import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { breadcrumb, href, SITE_NAME } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { banners as bannersIn, type Banner } from '@/lib/data/banners';
import {
  PER_PAGE, categoryStories, chipCategories, newsCards, newsCategoryName, newsFront,
  type NewsCard, type NewsCategory, type FrontSection,
} from '@/lib/data/news';
import { JsonLd } from '@/components/JsonLd';
import { BannerImage } from '@/components/ui/Banner';
import {
  DeskGrid, DeskHeading, DeskHero, EmptyNews, PageTitle, Pager, PhoneFeatured, PhoneList, PhoneSection,
} from './NewsParts';

type Search = Promise<Record<string, string | string[] | undefined>>;

/** `?page=N` as a page number: none is the first page; anything that is not
 *  a whole number from 1 up is no page at all. */
export async function pageParam(searchParams: Search): Promise<number> {
  const raw = (await searchParams).page;
  if (raw === undefined) return 1;
  const n = Number(Array.isArray(raw) ? raw[0] : raw);
  if (!Number.isInteger(n) || n < 1) notFound();
  return n;
}

/** A list's later pages are pages of their own for a search engine: each
 *  names itself as the canonical, under the first page's title. */
export function pagedMetadata(meta: Metadata, path: string, page: number): Metadata {
  if (page <= 1) return meta;
  const url = `${SITE_URL}${href(path)}?page=${page}`;
  return { ...meta, alternates: { canonical: url }, openGraph: { ...meta.openGraph, url } };
}

function listLd(name: string, path: string, page: number, cards: NewsCard[]) {
  return {
    '@context': 'https://schema.org', '@type': 'CollectionPage', name,
    url: SITE_URL + href(path) + (page > 1 ? `?page=${page}` : ''),
    mainEntity: {
      '@type': 'ItemList',
      itemListElement: cards.map((c, i) => ({ '@type': 'ListItem', position: i + 1, url: `${SITE_URL}${href(`/news/${c.slug}/`)}`, name: c.title })),
    },
  };
}

/** The tall banners down the side of the desktop's sections, 370 wide at
 *  their own height. The design hangs the first beside the first section
 *  and starts the rest 17 below the second's top, 32 apart (the grid's
 *  rows are the sections, so the rest span from the second down). */
function DeskSections({ sections, cards, banners, lang }: { sections: FrontSection[]; cards: Map<string, NewsCard>; banners: Banner[]; lang: Lang }) {
  const side = banners.length > 0;
  const n = sections.length;
  return (
    <div className={`grid gap-y-[72px] ${side ? 'min-[1320px]:grid-cols-[370px_minmax(0,1fr)] min-[1320px]:gap-x-12' : ''}`}>
      {side && (n < 2 ? (
        <div className="hidden flex-col gap-8 min-[1320px]:flex" style={{ gridColumn: 1, gridRow: 1 }}>
          {banners.map((b) => <BannerImage key={b.id} banner={b} />)}
        </div>
      ) : (
        <>
          <div className="hidden min-[1320px]:block" style={{ gridColumn: 1, gridRow: 1 }}>
            <BannerImage banner={banners[0]} />
          </div>
          {banners.length > 1 && (
            <div className="hidden flex-col gap-8 pt-[17px] min-[1320px]:flex" style={{ gridColumn: 1, gridRow: `2 / span ${n - 1}` }}>
              {banners.slice(1).map((b) => <BannerImage key={b.id} banner={b} />)}
            </div>
          )}
        </>
      ))}
      {sections.map((s, i) => (
        <section key={s.category.id} className={`min-w-0 ${side ? 'min-[1320px]:col-start-2' : ''}`} style={{ gridRow: i + 1 }}>
          <DeskHeading title={newsCategoryName(s.category, lang)} link={href(`/new/${s.category.slug}/`)} />
          <DeskGrid cards={s.ids.map((id) => cards.get(id)!).filter(Boolean)} lang={lang} />
        </section>
      ))}
    </div>
  );
}

/** The news (/news/, and WordPress's /modiin-news/): on the first page the
 *  hero and a section per category beside the paid banners
 *  (web_news_screen.dart) — on the phone the hero and a sideways row per
 *  category (news_screen.dart); on the pages after it every other story,
 *  newest first. */
export async function NewsListing({ path, page, h1 }: { path: string; page: number; h1: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const front = await newsFront();
  if (page > front.pages) notFound();

  if (page > 1) {
    const ids = front.archive.slice((page - 2) * PER_PAGE, (page - 1) * PER_PAGE);
    const cards = await newsCards(ids);
    return (
      <div className="pb-8 desk:pb-[103px] desk:pt-12">
        <JsonLd data={[listLd(h1, path, page, cards), breadcrumb([[SITE_NAME, '/'], [h1, path]])]} />
        <PageTitle>{lang === 'he' ? h1 : t('חדשות', 'News')}</PageTitle>
        <div className="wrap hidden desk:block">
          <DeskHeading title={t('חדשות', 'News')} />
          <DeskGrid cards={cards} lang={lang} />
        </div>
        <div className="desk:hidden"><PhoneList cards={cards} lang={lang} /></div>
        <Pager base={path} page={page} pages={front.pages} lang={lang} />
      </div>
    );
  }

  const shownIds = [...new Set([
    ...(front.hero ? [front.hero] : []), ...front.side,
    ...front.desk.flatMap((s) => s.ids), ...front.phone.flatMap((s) => s.ids), ...front.phoneLatest,
  ])];
  const [list, chips, side] = await Promise.all([
    newsCards(shownIds), chipCategories([front.hero, ...front.side].filter(Boolean) as string[]), bannersIn('NEWS_SIDEBAR'),
  ]);
  const cards = new Map(list.map((c) => [c.id, c]));
  const hero = front.hero ? cards.get(front.hero) : undefined;
  const pick = (ids: string[]) => ids.map((id) => cards.get(id)).filter(Boolean) as NewsCard[];

  return (
    <div className="pb-8 desk:pb-[103px] desk:pt-12">
      <JsonLd data={[listLd(h1, path, page, pick(shownIds)), breadcrumb([[SITE_NAME, '/'], [h1, path]])]} />
      <PageTitle>{lang === 'he' ? h1 : t('חדשות', 'News')}</PageTitle>
      {!hero ? (
        <div className="wrap"><EmptyNews lang={lang} category={false} /></div>
      ) : (
        <>
          <div className="wrap hidden desk:block">
            <DeskHero lead={hero} side={pick(front.side)} chips={chips} lang={lang} />
            {front.desk.length > 0 && (
              <div className="mt-16"><DeskSections sections={front.desk} cards={cards} banners={side} lang={lang} /></div>
            )}
          </div>
          <div className="pt-2 desk:hidden">
            <PhoneFeatured card={hero} lang={lang} />
            <div className="mt-6 flex flex-col gap-10">
              {front.phone.map((s) => (
                <PhoneSection key={s.category.id} title={newsCategoryName(s.category, lang)} link={href(`/new/${s.category.slug}/`)} cards={pick(s.ids)} lang={lang} />
              ))}
              {front.phoneLatest.length > 0 && <PhoneSection title={t('הכתבות האחרונות', 'Latest Stories')} cards={pick(front.phoneLatest)} lang={lang} />}
            </div>
          </div>
        </>
      )}
      <Pager base={path} page={page} pages={front.pages} lang={lang} />
    </div>
  );
}

/** A news category (/new/<slug>/): its stories, its sub-categories' too —
 *  on the desktop the hero and a grid under the category's name
 *  (web_news_screen.dart with a category), on the phone a full-width card
 *  each, newest first (news_screen.dart, _CategoryList). */
export async function CategoryListing({ path, category, page, h1 }: { path: string; category: NewsCategory; page: number; h1: string }) {
  const lang = await getLang();
  const all = await categoryStories(category);
  const pages = Math.max(1, Math.ceil(all.length / PER_PAGE));
  if (page > pages) notFound();
  const ids = all.slice((page - 1) * PER_PAGE, page * PER_PAGE);
  const top = page === 1 ? ids.slice(0, 3) : [];
  const [cards, chips] = await Promise.all([newsCards(ids), chipCategories(top)]);
  const name = newsCategoryName(category, lang);
  const grid = page === 1 ? cards.slice(3) : cards;
  const phone = [...cards].sort((a, b) => (b.published_at ?? '').localeCompare(a.published_at ?? ''));

  return (
    <div className="pb-8 desk:pb-[103px] desk:pt-12">
      <JsonLd data={[listLd(h1, path, page, cards), breadcrumb([[SITE_NAME, '/'], ['חדשות', '/news/'], [h1, path]])]} />
      <PageTitle>{lang === 'he' ? h1 : name}</PageTitle>
      {!cards.length ? (
        <div className="wrap"><EmptyNews lang={lang} category /></div>
      ) : (
        <>
          <div className="wrap hidden desk:block">
            {page === 1 && <DeskHero lead={cards[0]} side={cards.slice(1, 3)} chips={chips} lang={lang} />}
            {grid.length > 0 && (
              <div className={page === 1 ? 'mt-16' : ''}>
                <DeskHeading title={name} />
                <DeskGrid cards={grid} lang={lang} />
              </div>
            )}
          </div>
          <div className="desk:hidden"><PhoneList cards={phone} lang={lang} /></div>
        </>
      )}
      <Pager base={path} page={page} pages={pages} lang={lang} />
    </div>
  );
}
