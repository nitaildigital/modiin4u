import type { Metadata } from 'next';
import Link from 'next/link';
import { Car } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { lotName, parkingLots } from '@/lib/data/municipal';
import { JsonLd } from '@/components/JsonLd';
import { BackArrow, PhoneBar } from '@/components/municipal/BackLink';
import { ParkingExplorer } from '@/components/municipal/ParkingExplorer';

const PATH = '/parking/';
const heading = (lang: Lang) => tr(lang)('חניה במודיעין', 'Parking in Modiin');
const intro = (lang: Lang) => tr(lang)('כל החניונים בעיר, על המפה.', 'Every car park in the city, on the map.');

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getLang();
  return pageMetadata({ path: PATH, title: heading(lang) + SUFFIX, description: intro(lang) });
}

/** Parking in Modiin (web_parking_screen.dart; parking_screen.dart on the
 *  phone): the car parks the client enters in the panel (חניונים), on a map
 *  and in a list — what he entered, and nothing where he entered nothing. */
export default async function ParkingPage() {
  const lang = await getLang();
  const t = tr(lang);
  const lots = await parkingLots();

  return (
    <div className="wrap">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: heading(lang),
          itemListElement: lots.map((l, i) => ({
            '@type': 'ListItem', position: i + 1,
            item: {
              '@type': 'ParkingFacility', name: lotName(l, lang), url: SITE_URL + href(`/parking/${l.id}/`),
              ...(l.address ? { address: l.address } : {}),
              geo: { '@type': 'GeoCoordinates', latitude: l.latitude, longitude: l.longitude },
              ...(l.is_free != null ? { isAccessibleForFree: l.is_free } : {}),
            },
          })),
        },
        breadcrumb([[SITE_NAME, '/'], [t('שירותים עירוניים במודיעין', 'Municipal Services in Modiin'), '/municipal/'], [heading(lang), PATH]]),
      ]} />
      <div className="pb-8 desk:pb-[100px] desk:pt-12">
        <PhoneBar back="/municipal/" lang={lang}><span className="font-rubik text-lg font-bold text-navy" aria-hidden>{heading(lang)}</span></PhoneBar>
        <Link href="/municipal/" className="hidden items-center gap-2 text-sm font-medium text-navy desk:inline-flex">
          <BackArrow lang={lang} size={22} />{t('שירותי עירייה', 'Municipal Services')}
        </Link>
        <h1 className="font-nunito font-semibold text-midblue max-desk:sr-only desk:mt-5 desk:text-4xl desk:leading-[1.2]">{h1For(PATH, heading(lang))}</h1>
        <p className="mt-2 hidden text-sm leading-[1.21] text-gray-text desk:block">{intro(lang)}</p>
        <div className="desk:mt-10">
          {lots.length === 0 ? (
            <div className="flex h-[300px] flex-col items-center justify-center rounded-2xl border border-line bg-midblue/[0.03] p-8 text-center">
              <Car size={44} color="#123A724D" />
              <p className="mt-4 text-base font-medium text-[#1C1C1E]">{t('החניונים יתווספו בקרוב', 'Car parks will be added soon')}</p>
            </div>
          ) : <ParkingExplorer lots={lots} lang={lang} />}
        </div>
      </div>
    </div>
  );
}
