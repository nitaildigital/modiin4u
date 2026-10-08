'use client';
import { useRef, type ReactNode } from 'react';

/** "You May Also Like" on the website: the events page's cards in a row that
 *  scrolls sideways, with a round arrow on either edge once there are more
 *  cards than fit — four across from 1398 px, three below
 *  (web_event_detail_screen.dart). */
export function Carousel({ count, children }: { count: number; children: ReactNode }) {
  const row = useRef<HTMLDivElement>(null);
  const step = (next: boolean) => {
    const el = row.current;
    if (!el) return;
    const card = el.firstElementChild as HTMLElement | null;
    const by = (card?.offsetWidth ?? 300) + 24;
    // Along the reading direction: in Hebrew "next" is to the left.
    const rtl = getComputedStyle(el).direction === 'rtl';
    el.scrollBy({ left: (next ? by : -by) * (rtl ? -1 : 1), behavior: 'smooth' });
  };
  const arrows = count > 4 ? 'flex' : count > 3 ? 'flex min-[1398px]:hidden' : 'hidden';
  const arrow = 'absolute top-[162px] z-10 size-10 items-center justify-center rounded-full border border-[#F6F6F6] bg-white shadow-[0_1px_5px_rgba(0,0,0,0.1)]';
  return (
    <div className="relative">
      <div ref={row} className="flex gap-6 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {children}
      </div>
      <button type="button" aria-label="‹" onClick={() => step(false)} className={`${arrow} start-[-19px] ${arrows}`}>
        <img src="/web/events/carousel_arrow.svg" alt="" className="size-5 ltr:-scale-x-100" />
      </button>
      <button type="button" aria-label="›" onClick={() => step(true)} className={`${arrow} end-[-19px] ${arrows}`}>
        <img src="/web/events/carousel_arrow.svg" alt="" className="size-5 rtl:-scale-x-100" />
      </button>
    </div>
  );
}
