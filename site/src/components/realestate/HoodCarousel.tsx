'use client';
import { useState } from 'react';
import Link from 'next/link';
import { Buildings2 } from 'iconsax-react';
import { Carousel } from './Carousel';
import { photo } from './format';

export type HoodCard = { id: string; name: string; image: string | null };

/**
 * "Apartments by Neighborhoods" (web_realestate_screen.dart): the For Rent /
 * For Sale switch decides what a card opens — that neighbourhood's flats to
 * let, or for sale — and the city's neighbourhoods page by in a row, the
 * ones with a photograph first.
 */
export function HoodCarousel({ hoods, lang }: { hoods: HoodCard[]; lang: 'he' | 'en' }) {
  const [kind, setKind] = useState<'rent' | 'sale'>('rent');
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const toggle = (k: 'rent' | 'sale', icon: string, label: string, leading: boolean) => {
    const on = kind === k;
    return (
      <button type="button" aria-pressed={on} onClick={() => setKind(k)}
        className={`flex h-[46px] items-center gap-2 border-2 border-midblue px-6 text-base font-medium leading-6 ${on ? 'bg-midblue text-white' : 'bg-white text-midblue'} ${leading ? 'rounded-s-[60px]' : 'rounded-e-[60px]'}`}>
        <span className={`size-[18px] ${on ? 'bg-white' : 'bg-midblue'}`}
          style={{ mask: `url(${icon}) center / contain no-repeat`, WebkitMask: `url(${icon}) center / contain no-repeat` }} />
        {label}
      </button>
    );
  };
  return (
    <>
      <div className="mt-10 flex justify-center">
        {toggle('rent', '/web/realestate/tab_rent.svg', t('להשכרה', 'For Rent'), true)}
        {toggle('sale', '/web/realestate/tab_sale.svg', t('למכירה', 'For Sale'), false)}
      </div>
      <div className="mt-[41px]">
        <Carousel arrowTop={106} lang={lang}>
          {hoods.map((h) => (
            <Link key={h.id} href={`/realestate/?kind=${kind}&neighborhood=${h.id}`}
              className="block h-[248px] w-[calc((100%-48px)/4)] shrink-0 snap-start overflow-hidden rounded-xl border border-line bg-white min-[1099px]:w-[calc((100%-64px)/5)] min-[1538px]:w-[calc((100%-80px)/6)]">
              {h.image
                ? <img src={photo(h.image, 300)} alt={h.name} loading="lazy" className="h-[150px] w-full object-cover" />
                : <span className="flex h-[150px] items-center justify-center bg-[linear-gradient(135deg,#0058B5,#010A36)] text-white/30"><Buildings2 size={36} color="currentColor" variant="Bold" /></span>}
              <span className="block p-3">
                <span dir="auto" className={`block truncate font-nunito text-lg font-semibold leading-[22px] text-navy ${lang === 'he' ? 'text-right' : 'text-left'}`}>{h.name}</span>
                <span className="mt-1 block truncate text-sm leading-[17px] text-gray-text">{t('שכונה, מודיעין', 'Neighborhood, Modiin')}</span>
                <span className="mt-3 flex items-center gap-1.5 text-sm leading-[17px] text-gray-text">
                  <span className="flex size-4 items-center justify-center"><img src="/web/realestate/card_pin.svg" alt="" width={12} height={16} /></span>
                  {t('מודיעין, ישראל', 'Modiin, Israel')}
                </span>
              </span>
            </Link>
          ))}
        </Carousel>
      </div>
    </>
  );
}
