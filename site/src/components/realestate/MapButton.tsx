'use client';
import { useEffect, useState } from 'react';
import { CloseCircle, Map1 } from 'iconsax-react';
import { MapView, type MapPin } from '@/components/map/MapView';

/** The phone list's floating "View on Map": the listings on show, as pins on
 *  Google's map over the whole screen; a pin opens its listing. */
export function MapButton({ pins, label, lang }: { pins: MapPin[]; label: string; lang: 'he' | 'en' }) {
  const [open, setOpen] = useState(false);
  useEffect(() => {
    if (!open) return;
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('keydown', esc);
    return () => document.removeEventListener('keydown', esc);
  }, [open]);
  if (!pins.length) return null;
  return (
    <>
      <div className="pointer-events-none sticky bottom-[92px] z-30 mt-4 flex justify-center desk:hidden">
        <button type="button" onClick={() => setOpen(true)}
          className="pointer-events-auto flex h-10 items-center gap-1.5 rounded-full bg-white px-4 text-sm font-medium text-navy shadow-[0_4px_12px_rgba(0,0,0,0.25)]">
          <Map1 size={16} color="currentColor" />{label}
        </button>
      </div>
      {open && (
        <div role="dialog" aria-modal aria-label={label} className="fixed inset-0 z-[60] bg-white desk:hidden">
          <MapView pins={pins} lang={lang} zoom={13} />
          <button type="button" aria-label={lang === 'he' ? 'סגירה' : 'Close'} onClick={() => setOpen(false)}
            className="absolute end-4 top-4 z-[1000] flex size-10 items-center justify-center rounded-full bg-white text-ink shadow-[0_2px_8px_rgba(0,0,0,0.2)]">
            <CloseCircle size={24} color="currentColor" />
          </button>
        </div>
      )}
    </>
  );
}
