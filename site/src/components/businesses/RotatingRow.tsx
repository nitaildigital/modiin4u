'use client';
import { Children, useState } from 'react';

/** One row of cards that turns by one either way, round and round (the
 *  Restaurants page's banner row and "Explore Categories"). [cols] is a class
 *  setting `--cols`, how many show; the rest wait past the edge. The arrows
 *  appear from [minForArrows] cards on. */
export function RotatingRow({ children, cols, gap, minForArrows = 2, arrowTop = '50%', lang }: {
  children: React.ReactNode; cols: string; gap: number; minForArrows?: number; arrowTop?: string; lang: 'he' | 'en';
}) {
  const items = Children.toArray(children);
  const [start, setStart] = useState(0);
  const n = items.length;
  const rotated = [...items.slice(start), ...items.slice(0, start)];
  const turn = (by: number) => setStart((start + by + n) % n);
  // The arrow's drawing points right; in Hebrew "back" points right.
  const arrow = (back: boolean) => (
    <button type="button" onClick={() => turn(back ? -1 : 1)} aria-label={back ? (lang === 'he' ? 'הקודם' : 'Previous') : (lang === 'he' ? 'הבא' : 'Next')}
      style={{ top: arrowTop }}
      className={`absolute z-10 grid size-10 -translate-y-1/2 place-items-center rounded-full border border-[#F6F6F6] bg-white shadow-[0_1px_5px_rgba(0,0,0,0.1)] ${back ? '-start-5' : '-end-5'}`}>
      <img src="/web/common/arrow20.svg" alt="" className={`size-5 ${back === (lang === 'en') ? 'rotate-180' : ''}`} />
    </button>
  );
  return (
    <div className="relative">
      <div className={`grid grid-flow-col overflow-hidden ${cols}`}
        style={{ gap, gridAutoColumns: `calc((100% - (var(--cols) - 1) * ${gap}px) / var(--cols))` }}>
        {rotated}
      </div>
      {n >= minForArrows && <>{arrow(true)}{arrow(false)}</>}
    </div>
  );
}
