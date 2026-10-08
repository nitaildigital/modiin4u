import type { Metadata } from 'next';
import { redirect } from 'next/navigation';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { slugParam } from '@/lib/params';
import { pageMetadata, h1For, breadcrumb, SITE_NAME, SUFFIX } from '@/lib/seo';
import { isMunicipalSection, municipalPlaces, placeName, type MunicipalSection } from '@/lib/data/municipal';
import { JsonLd } from '@/components/JsonLd';
import { BackLink, PhoneBar } from '@/components/municipal/BackLink';
import { PlacesList } from '@/components/municipal/PlacesList';

type Props = { params: Promise<{ section: string }> };

function title(s: MunicipalSection, lang: Lang): string {
  const t = tr(lang);
  switch (s) {
    case 'institutions': return t('מוסדות ציבור', 'Public Institutions');
    case 'health': return t('בריאות', 'Health');
    case 'education': return t('חינוך', 'Education');
    case 'transport': return t('תחבורה', 'Transportation');
    default: return t('חירום', 'Emergency');
  }
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const section = slugParam((await params).section);
  if (!isMunicipalSection(section)) return {};
  const lang = await getLang();
  return pageMetadata({ path: `/municipal/${section}/`, title: title(section, lang) + SUFFIX });
}

/** One of the Municipal page's service tiles (municipal_places_screen.dart):
 *  the client's places under it, from the panel's מוסדות עירוניים, with
 *  Call and Navigate where a place has a phone or a location. An unknown
 *  section goes back to the Municipal page, as in the app. */
export default async function MunicipalSectionPage({ params }: Props) {
  const section = slugParam((await params).section);
  if (!isMunicipalSection(section)) redirect('/municipal/');
  const lang = await getLang();
  const t = tr(lang);
  const path = `/municipal/${section}/`;
  const places = await municipalPlaces(section);
  const name = title(section, lang);

  return (
    <div className="wrap">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name,
          itemListElement: places.slice(0, 100).map((p, i) => ({
            '@type': 'ListItem', position: i + 1,
            item: {
              '@type': 'Place', name: placeName(p, lang),
              ...(p.address ? { address: p.address } : {}),
              ...(p.phone ? { telephone: p.phone } : {}),
              ...(p.latitude != null && p.longitude != null ? { geo: { '@type': 'GeoCoordinates', latitude: p.latitude, longitude: p.longitude } } : {}),
            },
          })),
        },
        breadcrumb([[SITE_NAME, '/'], [t('שירותים עירוניים במודיעין', 'Municipal Services in Modiin'), '/municipal/'], [name, path]]),
      ]} />
      <div className="mx-auto max-w-[430px] pb-6 pt-2.5 desk:max-w-[820px] desk:pb-[100px] desk:pt-14">
        <PhoneBar back="/municipal/" lang={lang}><span className="text-sm font-semibold text-[#1F1F1F]" aria-hidden>{name}</span></PhoneBar>
        <BackLink href="/municipal/" label={t('חזרה', 'Back')} lang={lang} className="hidden desk:block" />
        <h1 className="pt-2 font-nunito text-2xl font-semibold text-[#1C1C1E] desk:mt-6 desk:px-0 desk:pt-0 desk:text-[40px] max-desk:sr-only">
          {h1For(path, name)}
        </h1>
        <div className="mt-4 desk:mt-7">
          <PlacesList places={places} lang={lang} />
        </div>
      </div>
    </div>
  );
}
