'use client';
import { useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { Car, Clock, Ticket } from 'iconsax-react';
import { MapView, type MapPin } from '@/components/map/MapView';
import type { Lang } from '@/lib/i18n';
import { googleMapsUrl, lotName, wazeUrl, type ParkingLot } from '@/lib/data/municipal-shared';
import { Directions } from './Directions';
import { useDesk } from './useDesk';

const PIN = '/web/map/pin_parking.svg';

/** Free in green, paid in amber — only when it is known; a lot nobody has
 *  said anything about is not marked either way. */
export function FreeTag({ free, lang, large = false }: { free: boolean; lang: Lang; large?: boolean }) {
  return (
    <span className={`shrink-0 rounded-md font-semibold ${large ? 'px-2.5 py-1' : 'px-2 py-[3px]'} text-xs`}
      style={{ color: free ? '#2ECC71' : '#B26A00', background: free ? '#2ECC711A' : '#B26A001A' }}>
      {free ? (lang === 'he' ? 'חינם' : 'Free') : (lang === 'he' ? 'בתשלום' : 'Paid')}
    </span>
  );
}

/** One car park: its name, where it is, and whatever else the client
 *  entered — hours, price, spaces, his note — each only where he filled it
 *  in (ParkingLotCard). The card opens the car park's page. */
function LotCard({ lot, lang, selected, cardRef }: { lot: ParkingLot; lang: Lang; selected: boolean; cardRef?: (el: HTMLDivElement | null) => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  // Text the client typed reads in its own direction, on the page's side.
  const side = lang === 'he' ? 'text-right' : 'text-left';
  const line = (icon: React.ReactNode, text: string) => (
    <p className="mb-1.5 flex items-start gap-2 text-[13px] leading-[1.35] text-gray-text">
      <span className="mt-px shrink-0">{icon}</span><span dir="auto" className={side}>{text}</span>
    </p>
  );
  return (
    <div ref={cardRef} className={`relative rounded-xl bg-white p-4 ${selected ? 'border-[1.5px] border-midblue' : 'border border-line'}`}>
      <div className="flex items-start gap-3">
        {lot.image_url
          ? <img src={lot.image_url} alt="" className="size-12 shrink-0 rounded-xl object-cover" loading="lazy" />
          : <span className="flex size-12 shrink-0 items-center justify-center rounded-xl bg-[linear-gradient(135deg,#123A7214,#123A720A)]"><Car size={22} color="#123A72" /></span>}
        <div className="min-w-0 flex-1">
          <Link href={`/parking/${lot.id}/`} className="block text-base font-semibold leading-[1.3] text-[#1C1C1E] after:absolute after:inset-0 after:content-['']">
            <span dir="auto" className={`block ${side}`}>{lotName(lot, lang)}</span>
          </Link>
          {lot.address && <p dir="auto" className={`mt-1 text-[13px] leading-[1.35] text-gray-text ${side}`}>{lot.address}</p>}
        </div>
        {lot.is_free != null && <FreeTag free={lot.is_free} lang={lang} />}
      </div>
      {(lot.hours || lot.price_note || lot.capacity != null) && (
        <div className="mt-3">
          {lot.hours && line(<Clock size={15} color="#6D6D6D" />, lot.hours)}
          {lot.price_note && line(<Ticket size={15} color="#6D6D6D" />, lot.price_note)}
          {lot.capacity != null && line(<Car size={15} color="#6D6D6D" />, t(`${lot.capacity} מקומות חניה`, `${lot.capacity} spaces`))}
        </div>
      )}
      {lot.notes && <p dir="auto" className={`mt-2 text-[13px] leading-[1.35] text-gray-text ${side}`}>{lot.notes}</p>}
      <div className="mt-3">
        <Directions waze={wazeUrl(lot.latitude, lot.longitude)} google={googleMapsUrl(lot)} lang={lang} />
      </div>
    </div>
  );
}

/** The car parks on a map beside their list (web_parking_screen.dart), or
 *  above it on a phone (parking_screen.dart). A pin picks its car park out
 *  in the list; a card opens the car park's page. */
export function ParkingExplorer({ lots, lang }: { lots: ParkingLot[]; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [selected, setSelected] = useState<string | null>(null);
  const list = useRef<HTMLDivElement>(null);
  const cards = useRef(new Map<string, HTMLDivElement>());
  const desk = useDesk();
  const pins = useMemo<MapPin[]>(() => lots.map((l) => ({ id: l.id, lat: l.latitude, lng: l.longitude, icon: PIN, size: [40, 43], label: lotName(l, lang) })), [lots, lang]);
  const count = lots.length === 1 ? t('חניון אחד', '1 car park') : t(`${lots.length} חניונים`, `${lots.length} car parks`);
  const credit = <p className="mt-5 text-xs text-gray-text desk:mt-2">{t('נתוני מפה © תורמי OpenStreetMap', 'Map data © OpenStreetMap contributors')}</p>;

  // Scrolls the list alone on the desktop — scrolling the page would take
  // the map off the screen — and the page on the phone.
  function pick(pin: MapPin) {
    setSelected(pin.id);
    const card = cards.current.get(pin.id);
    if (!card) return;
    const box = list.current;
    if (box && box.scrollHeight > box.clientHeight + 1 && getComputedStyle(box).overflowY !== 'visible') {
      box.scrollTo({ top: card.offsetTop - box.offsetTop - 8, behavior: 'smooth' });
    } else {
      card.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
  }

  const map = (
    <MapView pins={pins} lang={lang} onPick={pick} selectedId={selected} wheel={false} fit center={lots.length === 1 ? [lots[0].latitude, lots[0].longitude] : [31.8928, 35.0104]} zoom={lots.length === 1 ? 16 : 14} />
  );

  return (
    <div className="desk:flex desk:h-[640px] desk:gap-7">
      <div className="-mx-[clamp(16px,4.5vw,80px)] h-[260px] bg-[#E8EAED] desk:hidden">{desk === false && map}</div>
      <div className="flex flex-col desk:w-[440px] desk:shrink-0">
        <h2 className="hidden font-nunito text-[28px] font-semibold text-midblue desk:block">{t('חניונים', 'Car Parks')}</h2>
        <p className="mt-4 text-sm text-gray-text desk:mt-1">{count}</p>
        <div ref={list} className="mt-3 flex flex-col gap-3 desk:mt-4 desk:min-h-0 desk:flex-1 desk:overflow-y-auto desk:pe-3">
          {lots.map((lot) => (
            <LotCard key={lot.id} lot={lot} lang={lang} selected={selected === lot.id}
              cardRef={(el) => { if (el) cards.current.set(lot.id, el); else cards.current.delete(lot.id); }} />
          ))}
          {/* The car parks came from OpenStreetMap's data, whose licence asks
              for this credit wherever it is shown. */}
          {credit}
        </div>
      </div>
      <div className="hidden overflow-hidden rounded-2xl border border-line bg-[#E8EAED] desk:block desk:flex-1">{desk && map}</div>
    </div>
  );
}
