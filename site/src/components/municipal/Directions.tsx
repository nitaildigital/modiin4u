'use client';
import { useEffect, useRef, useState } from 'react';
import { Map1, Routing2 } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';

/** "Get Directions": Waze or Google Maps, as the person chooses — the client
 *  left it to us, and people here use both (showNavigationChoice). */
export function Directions({ waze, google, lang, variant = 'outline' }: { waze: string; google: string; lang: Lang; variant?: 'outline' | 'filled' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => { if (!box.current?.contains(e.target as Node)) setOpen(false); };
    document.addEventListener('click', close);
    return () => document.removeEventListener('click', close);
  }, [open]);
  const button = variant === 'filled'
    ? 'flex h-[46px] w-full items-center justify-center gap-2 rounded-xl bg-midblue text-[15px] font-semibold text-white'
    : 'flex h-9 items-center gap-2 rounded-full border border-midblue px-3.5 text-[13px] font-semibold text-midblue';
  return (
    <div ref={box} className={`relative z-10 ${variant === 'filled' ? 'flex-1' : 'inline-block'}`}>
      <button type="button" aria-expanded={open} onClick={() => setOpen(!open)} className={button}>
        <Routing2 size={variant === 'filled' ? 18 : 16} color="currentColor" />{t('ניווט', 'Get Directions')}
      </button>
      {open && (
        <div className="absolute start-0 top-full z-20 mt-2 w-56 rounded-2xl bg-white py-2 shadow-[0_8px_30px_rgba(0,0,0,0.15)]">
          <p className="px-5 pb-1 pt-2 text-base font-semibold text-[#1C1C1E]">{t('ניווט עם', 'Navigate with')}</p>
          <a href={waze} target="_blank" rel="noopener" className="flex items-center gap-4 px-5 py-3 text-[15px] font-medium hover:bg-section">
            <Routing2 size={22} color="#123A72" />Waze
          </a>
          <a href={google} target="_blank" rel="noopener" className="flex items-center gap-4 px-5 py-3 text-[15px] font-medium hover:bg-section">
            <Map1 size={22} color="#123A72" />Google Maps
          </a>
        </div>
      )}
    </div>
  );
}
