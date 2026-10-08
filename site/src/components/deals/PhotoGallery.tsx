'use client';
import { useEffect, useRef, useState } from 'react';

/** "Show all photos" on the phone's deal page: the business's gallery, one
 *  photograph at a time on black, with a close button and a counter
 *  (showMDealPhotos in m_deal_detail_parts.dart). */
export function PhotoGallery({ photos, label, className }: { photos: string[]; label: string; className: string }) {
  const [open, setOpen] = useState(false);
  const [page, setPage] = useState(0);
  const strip = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('keydown', esc);
    document.body.style.overflow = 'hidden';
    return () => { document.removeEventListener('keydown', esc); document.body.style.overflow = ''; };
  }, [open]);

  return (
    <>
      <button type="button" onClick={() => { setPage(0); setOpen(true); }} className={className}>
        <img src="/icons/m_deals_photos.svg" alt="" className="size-3.5" />
        {label}
      </button>
      {open && (
        <div className="fixed inset-0 z-[1200] bg-black" role="dialog" aria-modal="true">
          <div ref={strip} dir="ltr" className="flex h-full snap-x snap-mandatory overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
            onScroll={(e) => setPage(Math.round(e.currentTarget.scrollLeft / Math.max(1, e.currentTarget.clientWidth)))}>
            {photos.map((url) => (
              <div key={url} className="flex h-full w-full shrink-0 snap-center items-center justify-center">
                <img src={url} alt="" className="max-h-full max-w-full object-contain" />
              </div>
            ))}
          </div>
          <button type="button" aria-label="×" onClick={() => setOpen(false)}
            className="absolute end-3 top-[7px] flex size-10 items-center justify-center rounded-full bg-white text-xl leading-none text-[#3D3D3D]">×</button>
          <p dir="ltr" className="absolute inset-x-0 bottom-4 text-center text-sm font-medium text-white">{page + 1} / {photos.length}</p>
        </div>
      )}
    </>
  );
}
