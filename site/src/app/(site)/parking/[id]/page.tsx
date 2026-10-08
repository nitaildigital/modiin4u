import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowCircleLeft, ArrowCircleRight } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { isUuid, slugParam } from '@/lib/params';
import { pageMetadata, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { lotName, parkingLot } from '@/lib/data/municipal';
import { JsonLd } from '@/components/JsonLd';
import { PhoneBar } from '@/components/municipal/BackLink';
import { ParkingDetail } from '@/components/municipal/ParkingDetail';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const id = slugParam((await params).id);
  const lot = isUuid(id) ? await parkingLot(id) : null;
  if (!lot) return {};
  const lang = await getLang();
  return pageMetadata({ path: `/parking/${id}/`, title: lotName(lot, lang) + SUFFIX, description: lot.address ?? undefined, image: lot.image_url });
}

/** One car park (parking_detail_screen.dart): what the client entered, what
 *  Google Maps knows where the car park is linked to it, a small map and
 *  the way there. */
export default async function ParkingLotPage({ params }: Props) {
  const id = slugParam((await params).id);
  const lot = isUuid(id) ? await parkingLot(id) : null;
  if (!lot) notFound();
  const lang = await getLang();
  const t = tr(lang);
  const path = `/parking/${id}/`;
  const name = lotName(lot, lang);
  const Back = lang === 'he' ? ArrowCircleRight : ArrowCircleLeft;

  return (
    <div className="wrap">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ParkingFacility', name, url: SITE_URL + href(path),
          ...(lot.address ? { address: lot.address } : {}),
          geo: { '@type': 'GeoCoordinates', latitude: lot.latitude, longitude: lot.longitude },
          ...(lot.is_free != null ? { isAccessibleForFree: lot.is_free } : {}),
          ...(lot.image_url ? { image: lot.image_url } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], [t('חניה במודיעין', 'Parking in Modiin'), '/parking/'], [name, path]]),
      ]} />
      <div className="mx-auto max-w-[430px] pb-8 desk:max-w-[760px] desk:pb-[100px] desk:pt-12">
        <PhoneBar back="/parking/" lang={lang}><span className="font-nunito text-lg font-bold text-[#1C1C1E]">{t('חניה במודיעין', 'Parking in Modiin')}</span></PhoneBar>
        <Link href="/parking/" className="mb-3 hidden items-center gap-2 px-3 py-2 text-sm font-medium text-midblue desk:inline-flex">
          <Back size={18} color="currentColor" />{t('חניה במודיעין', 'Parking in Modiin')}
        </Link>
        <div className="pt-1 desk:pt-0">
          <ParkingDetail lot={lot} lang={lang} />
        </div>
      </div>
    </div>
  );
}
