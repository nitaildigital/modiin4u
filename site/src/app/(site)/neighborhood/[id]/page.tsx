import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { Location } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { breadcrumb, h1For, href, pageMetadata, plain, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import {
  hoodBusinesses, hoodListings, localName, neighborhoodById, neighborhoodFigures, neighborhoodPhotos, neighborhoodRating,
  type Listing, type ListingKind,
} from '@/lib/data/realestate';
import { JsonLd } from '@/components/JsonLd';
import { ListingCard } from '@/components/realestate/ListingCard';
import { BusinessCard } from '@/components/realestate/BusinessCard';
import { Carousel } from '@/components/realestate/Carousel';
import { Mosaic, PhoneGallery } from '@/components/realestate/Gallery';
import { paragraphs } from '@/components/realestate/format';
import { searchHref } from '@/components/realestate/search';

type Props = { params: Promise<{ id: string }> };

const A = '/web/realestate';

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const n = await neighborhoodById(id);
  if (!n) return {};
  return pageMetadata({
    path: `/neighborhood/${id}/`,
    title: n.name + SUFFIX,
    description: plain(n.description, 160) || null,
    image: n.image_url,
  });
}

/**
 * A neighbourhood (web_neighborhood_detail_screen.dart; phone:
 * neighborhood_detail_screen.dart): its name, the client's text, the
 * residents' average rating — read only, rating is the app's — the figures
 * the database can answer, its photographs, and the flats and businesses
 * filed under it. The design's "Parks & Playgrounds" and "Schools &
 * Kindergardens" counts and its four-point checklist have nothing behind
 * them in the database and are not drawn.
 */
export default async function NeighborhoodPage({ params }: Props) {
  const { id } = await params;
  const n = await neighborhoodById(id);
  if (!n) notFound();
  const lang = await getLang();
  const t = tr(lang);
  const path = `/neighborhood/${n.id}/`;
  const name = localName(n.name, n.name_en, lang);
  const [photos, figures, rating, sale, rent, businesses] = await Promise.all([
    neighborhoodPhotos(n), neighborhoodFigures(n.id), neighborhoodRating(n.id),
    hoodListings(n.id, 'sale'), hoodListings(n.id, 'rent'), hoodBusinesses(n.id, lang),
  ]);

  // The client's text, one paragraph per entry: the first is the short
  // introduction under the name on the website, the rest its "About". The
  // phone layout's About carries all of it.
  const paras = paragraphs(n.description);
  const intro = paras[0] ?? null;
  const about = paras.slice(1);
  const align = lang === 'he' ? 'text-right' : 'text-left';
  const dash = (v: number | null) => (v == null ? '—' : String(v));

  const listingStrip = (kind: ListingKind, rows: Listing[]) => {
    const title = kind === 'sale' ? t(`דירות למכירה ב${name}`, `Apartments for Sale in ${name}`) : t(`דירות להשכרה ב${name}`, `Apartments for Rent in ${name}`);
    const phoneTitle = kind === 'sale' ? t(`דירות למכירה ב${name}`, `Apartments for sale in ${name}`) : t(`דירות להשכרה ב${name}`, `Apartments for rent in ${name}`);
    return (
      <>
        {/* Phone: three at most, then "See all"; an empty kind says so. */}
        <section className="mt-8 desk:hidden">
          <h2 className="text-base font-semibold text-[#1F1F1F]">{phoneTitle}</h2>
          {rows.length === 0 ? (
            <p className="py-6 text-sm text-[#6D6D6D]">
              {kind === 'rent' ? t('אין כרגע דירות להשכרה בשכונה הזו', 'No apartments for rent in this neighbourhood right now') : t('אין כרגע דירות למכירה בשכונה הזו', 'No apartments for sale in this neighbourhood right now')}
            </p>
          ) : (
            <div className="mt-3 flex flex-col gap-4">
              {rows.slice(0, 3).map((l) => <ListingCard key={l.id} l={l} lang={lang} variant="phone" />)}
              {rows.length > 3 && (
                <Link href={searchHref({ kind, neighborhood: n.id })} className="mx-auto rounded-[60px] border border-midblue bg-white px-6 py-2 text-sm font-medium text-midblue">
                  {t('ראה הכל', 'See all')}
                </Link>
              )}
            </div>
          )}
        </section>
        {/* Website: a strip, only when there is something in it. */}
        {rows.length > 0 && (
          <section className={`hidden desk:block ${kind === 'sale' && about.length ? 'desk:mt-[88px]' : 'desk:mt-16'}`}>
            <h2 className="line-clamp-2 font-nunito text-2xl font-semibold leading-[30px] text-midblue">{title}</h2>
            <div className="mt-6">
              <Carousel arrowTop={141} lang={lang} gapClass="gap-6">
                {rows.map((l) => (
                  <div key={l.id} className="h-[321px] w-[calc((100%-72px)/4)] shrink-0 snap-start"><ListingCard l={l} lang={lang} variant="desk" detail /></div>
                ))}
              </Carousel>
            </div>
          </section>
        )}
      </>
    );
  };

  return (
    <article className="pb-10 desk:pb-[124px]">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'Place', name: n.name, url: SITE_URL + href(path),
          ...(n.description ? { description: plain(n.description, 300) } : {}),
          ...(photos.length ? { image: photos.slice(0, 6) } : {}),
          containedInPlace: { '@type': 'City', name: 'מודיעין' },
          ...(rating ? { aggregateRating: { '@type': 'AggregateRating', ratingValue: Number(rating.average.toFixed(1)), ratingCount: rating.count, bestRating: 5, worstRating: 1 } } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], ['נדל״ן', '/search-apartments/'], [n.name, path]]),
      ]} />

      {/* PHONE — the photographs */}
      <div className="desk:hidden">
        <PhoneGallery photos={photos} alt={name} back="/search-apartments/" backLabel={t('חזרה לנדל״ן', 'Back to Real Estate')} hood />
      </div>

      <div className="wrap">
        {/* HERO — name, introduction and figures; the photographs beside */}
        <div className="desk:flex desk:items-start desk:gap-[66px] desk:pt-8">
          <div className="min-w-0 desk:flex-[592]">
            <Link href="/search-apartments/" aria-label={t('חזרה לנדל״ן', 'Back to Real Estate')} className="hidden w-fit desk:block">
              <img src={`${A}/detail_back.svg`} alt="" width={24} height={24} className="rtl:-scale-x-100" />
            </Link>
            <h1 dir="auto" className={`pt-6 font-nunito text-[28px] font-semibold text-black desk:mt-10 desk:pt-0 desk:text-[36px] desk:leading-[44px] desk:text-navy ${align}`}>{h1For(path, name)}</h1>
            <p className="mt-3 flex items-center gap-2 text-sm text-[#6D6D6D] desk:mt-4 desk:text-black">
              <Location size={16} color="#888888" className="desk:hidden" />
              <span className="hidden size-4 items-center justify-center desk:flex"><img src={`${A}/detail_pin.svg`} alt="" width={12} height={16} /></span>
              <span className="desk:hidden">{t('מודיעין מכבים רעות', "Modi'in-Maccabim-Re'ut")}</span>
              <span className="hidden desk:inline">{t('מודיעין', 'Modiin')}</span>
            </p>
            {rating && (
              <p className="mt-4 hidden items-center gap-2 text-sm desk:flex">
                <span className="font-medium">{rating.average.toFixed(1)}</span>
                <Stars value={rating.average} size={14} />
                <span className="text-[#6D6D6D]">({ratingCount(rating.count, lang)})</span>
              </p>
            )}
            {intro && <p dir="auto" className={`mt-8 hidden whitespace-pre-line text-base leading-[1.6] text-[#3D3D3D] desk:block ${align}`}>{intro}</p>}

            {/* The figures the database can answer (a dash where a count
                could not be read — a nought would be a claim). */}
            <div className="mt-8 hidden max-w-[541px] rounded-xl border border-line bg-white p-4 desk:flex">
              {[
                ['detail_stat_home', figures.forSale, t('נכסים למכירה', 'Properties for Sale')],
                ['detail_stat_shop', figures.businesses, t('עסקים באזור', 'Businesses in the Area')],
              ].map(([icon, value, label], i) => (
                <div key={String(icon)} className={`flex flex-1 flex-col items-center text-center ${i === 0 ? 'border-e border-line pe-4' : 'ps-4'}`}>
                  <img src={`${A}/${icon}.svg`} alt="" width={24} height={24} />
                  <span className="mt-3 text-lg font-semibold leading-[22px]">{dash(value as number | null)}</span>
                  <span className="mt-1.5 text-xs text-gray-text">{String(label)}</span>
                </div>
              ))}
            </div>
            <div className="mt-5 grid grid-cols-2 gap-3 desk:hidden">
              {[
                ['detail_stat_home', figures.listings, t('נכסים למכירה', 'Properties for Sale')],
                ['detail_stat_shop', figures.businesses, t('עסקים באזור', 'Businesses in the Area')],
              ].map(([icon, value, label]) => (
                <div key={String(icon)} className="flex flex-col items-center rounded-xl border border-line bg-white px-[9px] py-5 text-center">
                  <img src={`${A}/${icon}.svg`} alt="" width={32} height={32} className="size-8" />
                  <span className="mt-3 text-sm font-medium text-black">{dash(value as number | null)}</span>
                  <span className="mt-1 text-sm text-black">{String(label)}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="hidden min-w-0 desk:block desk:flex-[942] desk:pt-[25px]">
            <Mosaic photos={photos} alt={name} fourUp={false} height={425} radius={10} gap={8} inset={12} showAll={t('כל התמונות', 'Show all photos')} hood />
          </div>
        </div>

        {/* ABOUT — the website's after the introduction, the phone's all of it. */}
        {paras.length > 0 && (
          <section className={`mt-8 desk:mt-16 desk:max-w-[931px] ${about.length ? '' : 'desk:hidden'}`}>
            <h2 className="text-base font-semibold text-[#1F1F1F] desk:font-nunito desk:text-2xl desk:leading-[30px] desk:text-midblue">
              <span className="desk:hidden">{t(`אודות ${name}`, `About ${name}`)}</span>
              <span className="hidden desk:inline">{t(`על ${name}`, `About ${name}`)}</span>
            </h2>
            <div className="mt-3 flex flex-col gap-3 text-sm leading-[1.6] text-[#3D3D3D] desk:mt-6 desk:gap-6 desk:text-base">
              {paras.map((p, i) => <p key={i} dir="auto" className={`whitespace-pre-line ${align} ${i === 0 ? 'desk:hidden' : ''}`}>{p}</p>)}
            </div>
          </section>
        )}

        {/* The residents' rating, read only (phone), when anyone has rated. */}
        {rating && (
          <section className="mt-8 rounded-xl border border-line bg-white p-4 desk:hidden">
            <h2 className="text-base font-semibold text-[#1F1F1F]">{t('מה חושבים תושבי העיר?', 'What Locals Are Saying')}</h2>
            <p className="mt-3 flex flex-wrap items-center gap-2">
              <span className="text-xl font-semibold text-black">{rating.average.toFixed(1)}</span>
              <Stars value={rating.average} size={18} />
              <span className="text-sm text-[#6D6D6D]">({ratingCount(rating.count, lang)})</span>
            </p>
          </section>
        )}

        {listingStrip('sale', sale)}
        {listingStrip('rent', rent)}

        {/* The businesses there (website). The design heads this strip
            "Businesses for Sale"; these are the businesses in it. */}
        {businesses.length > 0 && (
          <section className="mt-16 hidden desk:block">
            <h2 className="line-clamp-2 font-nunito text-2xl font-semibold leading-[30px] text-midblue">{t(`עסקים ב${name}`, `Businesses in ${name}`)}</h2>
            <div className="mt-[30px]">
              <Carousel arrowTop={141} lang={lang} gapClass="gap-6">
                {businesses.map((b) => (
                  <div key={b.id} className="h-[348px] w-[calc((100%-72px)/4)] shrink-0 snap-start min-[1648px]:w-[calc((100%-96px)/5)]">
                    <BusinessCard b={b} lang={lang} large />
                  </div>
                ))}
              </Carousel>
            </div>
          </section>
        )}
      </div>
    </article>
  );
}

function ratingCount(n: number, lang: Lang): string {
  return n === 1 ? (lang === 'he' ? 'דירוג אחד' : '1 rating') : (lang === 'he' ? `${n} דירוגים` : `${n} ratings`);
}

/** Five stars filled to the nearest half, from the reading start. */
function Stars({ value, size }: { value: number; size: number }) {
  const halves = Math.round(value * 2) / 2;
  return (
    <span className="flex items-center gap-1" aria-label={`${value.toFixed(1)} / 5`}>
      {[0, 1, 2, 3, 4].map((i) => {
        const fill = Math.max(0, Math.min(1, halves - i));
        return (
          <span key={i} className="relative inline-block" style={{ width: size, height: size }}>
            <img src="/web/business/star14_empty.svg" alt="" className="absolute inset-0 size-full" />
            {fill > 0 && (
              <span className="absolute inset-y-0 start-0 overflow-hidden" style={{ width: `${fill * 100}%` }}>
                <img src="/web/business/star14_full.svg" alt="" className="absolute start-0 top-0 max-w-none" style={{ width: size, height: size }} />
              </span>
            )}
          </span>
        );
      })}
    </span>
  );
}
