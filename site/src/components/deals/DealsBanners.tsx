'use client';
import { useState } from 'react';
import type { Banner } from '@/lib/data/banners';

function Creative({ banner, className }: { banner: Banner; className: string }) {
  const img = <img src={banner.image_url} alt={banner.name} loading="lazy" className={`block w-full rounded-xl object-cover ${className}`} />;
  return banner.destination_url
    ? <a href={banner.destination_url} target="_blank" rel="noopener sponsored" className="block min-w-0 flex-1">{img}</a>
    : <span className="block min-w-0 flex-1">{img}</span>;
}

/** The campaigns booked for DEALS_TOP. On the website three across at the
 *  design's 520 × 300 (web_banner_row.dart), with a round arrow on either edge
 *  from three on that turns the row by one, round and round; on the phone one
 *  200 tall at a time with a bar per banner under it (MDealsBanner). Nothing
 *  booked, nothing drawn — the page leaves the slot out before this. */
export function DealsBanners({ banners }: { banners: Banner[] }) {
  const [start, setStart] = useState(0);
  const [page, setPage] = useState(0);
  const n = banners.length;
  const shown = Array.from({ length: Math.min(3, n) }, (_, i) => banners[(start + i) % n]);
  const arrow = 'absolute top-1/2 z-10 flex size-10 -translate-y-1/2 items-center justify-center rounded-full border border-[#F6F6F6] bg-white shadow-[0_1px_5px_rgba(0,0,0,0.1)]';
  return (
    <>
      <div className="wrap relative hidden pt-12 desk:block">
        <div className="relative">
          <div className="flex gap-5">
            {shown.map((b, i) => <Creative key={`${b.id}-${i}`} banner={b} className="aspect-[520/300]" />)}
            {Array.from({ length: Math.max(0, 3 - n) }, (_, i) => <span key={`gap-${i}`} className="min-w-0 flex-1" />)}
          </div>
          {n >= 3 && (
            <>
              <button type="button" aria-label="‹" onClick={() => setStart((s) => (s - 1 + n) % n)} className={`${arrow} start-[-20px]`}>
                <img src="/web/common/arrow20.svg" alt="" className="size-5 ltr:-scale-x-100" />
              </button>
              <button type="button" aria-label="›" onClick={() => setStart((s) => (s + 1) % n)} className={`${arrow} end-[-20px]`}>
                <img src="/web/common/arrow20.svg" alt="" className="size-5 rtl:-scale-x-100" />
              </button>
            </>
          )}
        </div>
      </div>
      <div className="pb-6 desk:hidden">
        <div className="flex snap-x snap-mandatory gap-4 overflow-x-auto px-4 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          onScroll={(e) => {
            const el = e.currentTarget;
            setPage(Math.round(Math.abs(el.scrollLeft) / Math.max(1, el.clientWidth - 16)));
          }}>
          {banners.map((b) => (
            <div key={b.id} className="w-full shrink-0 snap-center">
              <Creative banner={b} className="h-[200px]" />
            </div>
          ))}
        </div>
        {n > 1 && (
          <div className="mt-3 flex justify-center gap-[3px]">
            {banners.map((b, i) => <span key={b.id} className={`h-1 w-5 rounded-full ${i === page ? 'bg-midblue' : 'bg-[#D9D9D9]'}`} />)}
          </div>
        )}
      </div>
    </>
  );
}
