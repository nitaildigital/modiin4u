import type { Metadata } from 'next';
import Link from 'next/link';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { parks, parkKinds, parkName } from '@/lib/data/parks';
import { JsonLd } from '@/components/JsonLd';
import { BackArrow, PhoneBar } from '@/components/municipal/BackLink';
import { ParksList, type ParkItem } from '@/components/municipal/ParksList';

const PATH = '/parks/';
const heading = (lang: Lang) => tr(lang)('פארקים במודיעין', 'Parks in Modiin');

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getLang();
  return pageMetadata({ path: PATH, title: heading(lang) + SUFFIX });
}

/** The city's parks — where the Municipal page's Parks tile leads: the
 *  directory's listing of the businesses the client files as a park
 *  (BusinessListScreen with `parks: true`). No Kosher or Delivery filters,
 *  which mean nothing for a park. */
export default async function ParksPage() {
  const lang = await getLang();
  const t = tr(lang);
  const rows = await parks(lang);
  const kinds = await parkKinds(rows.map((p) => p.id));
  const local = (he: string | null | undefined, en: string | null | undefined) => (lang === 'en' && en?.trim() ? en.trim() : he ?? '') || '';

  const items: ParkItem[] = rows.map((p) => {
    const kind = kinds[p.id] ? local(kinds[p.id].name, kinds[p.id].name_en) : '';
    const description = (p.short_description ?? p.full_description ?? '').trim();
    const address = (p.address ?? '').trim();
    return {
      id: p.id,
      href: href(`/business/${p.slug || p.id}/`),
      name: parkName(p, lang),
      subtitle: description || kind,
      kind: kind || description,
      deskAddress: address || local(p.neighborhoods?.name, p.neighborhoods?.name_en),
      address,
      photo: p.cover_url || p.og_image_url || p.logo_url,
      rating: Number(p.rating ?? 0),
      reviews: Number(p.review_count ?? 0),
    };
  });

  return (
    <div className="wrap">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: heading(lang),
          itemListElement: items.map((p, i) => ({
            '@type': 'ListItem', position: i + 1,
            item: { '@type': 'Park', name: p.name, url: SITE_URL + p.href, ...(p.address ? { address: p.address } : {}), ...(p.photo ? { image: p.photo } : {}) },
          })),
        },
        breadcrumb([[SITE_NAME, '/'], [t('שירותים עירוניים במודיעין', 'Municipal Services in Modiin'), '/municipal/'], [heading(lang), PATH]]),
      ]} />
      <div className="mx-auto max-w-[430px] pt-1 desk:max-w-none desk:pb-[100px] desk:pt-12">
        <PhoneBar back="/municipal/" lang={lang}><span className="text-base font-semibold text-black" aria-hidden>{t('פארקים', 'Parks')}</span></PhoneBar>
        <Link href="/municipal/" className="hidden items-center gap-2 text-sm font-medium text-navy desk:inline-flex">
          <BackArrow lang={lang} size={22} />{t('שירותי עירייה', 'Municipal Services')}
        </Link>
        <h1 className="font-nunito font-semibold text-midblue max-desk:sr-only desk:mt-5 desk:text-[28px] desk:leading-[34px]">{h1For(PATH, heading(lang))}</h1>
        <p className="mt-2.5 hidden text-sm leading-[1.21] text-gray-text desk:block">
          {items.length === 1 ? t('פארק אחד', '1 park') : t(`${items.length} פארקים`, `${items.length} parks`)}
        </p>
        <div className="pb-8 pt-1 desk:pt-14">
          <ParksList parks={items} lang={lang} title={t('פארקים', 'Parks')} />
        </div>
      </div>
    </div>
  );
}
