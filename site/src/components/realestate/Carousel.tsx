'use client';
import { useCallback, useEffect, useRef, useState } from 'react';

/** The design's 40px round arrow: white, a hairline border, a soft shadow
 *  (DetailArrowButton). [forward] is the way the row moves; in Hebrew the
 *  row reads from the right, so forward points left. */
function Arrow({ forward, onClick, label }: { forward: boolean; onClick: () => void; label: string }) {
  return (
    <button type="button" onClick={onClick} aria-label={label}
      className="flex size-10 items-center justify-center rounded-full border border-[#F6F6F6] bg-white shadow-[0_1px_5px_rgba(0,0,0,0.1)] hover:bg-[#F8F8F8]">
      <img src="/web/realestate/detail_arrow.svg" alt="" width={20} height={20}
        className={forward ? 'rtl:-scale-x-100' : 'ltr:-scale-x-100'} />
    </button>
  );
}

/**
 * A row of cards that pages sideways, with round arrows straddling its two
 * edges (DetailCarousel). The caller sizes the items (so many to a view);
 * the arrows show only when there is more than one view's worth.
 */
export function Carousel({ children, arrowTop, gapClass = 'gap-4', lang }: {
  children: React.ReactNode; arrowTop: number; gapClass?: string; lang: 'he' | 'en';
}) {
  const row = useRef<HTMLDivElement>(null);
  const [paged, setPaged] = useState(false);

  const measure = useCallback(() => {
    const el = row.current;
    if (el) setPaged(el.scrollWidth > el.clientWidth + 2);
  }, []);
  useEffect(() => {
    measure();
    window.addEventListener('resize', measure);
    return () => window.removeEventListener('resize', measure);
  }, [measure]);

  const page = (forward: boolean) => {
    const el = row.current;
    if (!el) return;
    const rtl = getComputedStyle(el).direction === 'rtl';
    el.scrollBy({ left: (forward !== rtl ? 1 : -1) * el.clientWidth, behavior: 'smooth' });
  };

  return (
    <div className="relative">
      <div ref={row} className={`flex snap-x snap-mandatory overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden ${gapClass}`}>
        {children}
      </div>
      {paged && (
        <>
          <div className="absolute -start-5 z-10" style={{ top: arrowTop }}><Arrow forward={false} onClick={() => page(false)} label={lang === 'he' ? 'הקודם' : 'Previous'} /></div>
          <div className="absolute -end-5 z-10" style={{ top: arrowTop }}><Arrow forward onClick={() => page(true)} label={lang === 'he' ? 'הבא' : 'Next'} /></div>
        </>
      )}
    </div>
  );
}
