'use client';
import { useEffect, useState } from 'react';
import { MapView } from '@/components/map/MapView';
import { track } from './stats';

/** The Location & Hours card's map: the business's pin, still, and a click
 *  opens it on Google Maps. Drawn only on the desktop layout — the phone
 *  layout has no map, so a phone never loads one. */
export function BusinessMap({ businessId, lat, lng, lang, label }: { businessId: string; lat: number; lng: number; lang: 'he' | 'en'; label: string }) {
  const [wide, setWide] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia('(min-width: 1100px)');
    const on = () => setWide(mq.matches);
    on();
    mq.addEventListener('change', on);
    return () => mq.removeEventListener('change', on);
  }, []);
  const open = () => {
    track(businessId, 'directions');
    window.open(`https://www.google.com/maps/search/?api=1&query=${lat},${lng}`, '_blank', 'noopener');
  };
  return (
    <div role="link" tabIndex={0} aria-label={label} onClick={open} onKeyDown={(e) => { if (e.key === 'Enter') open(); }}
      className="relative mt-4 h-[231px] cursor-pointer overflow-hidden bg-[#E8EAED] [&_.leaflet-container]:cursor-pointer">
      {wide && (
        <MapView pins={[{ id: businessId, lat, lng, icon: '/web/business/map_marker.svg', size: [48, 52] }]}
          center={[lat, lng]} zoom={15} interactive={false} fit={false} lang={lang} />
      )}
    </div>
  );
}
