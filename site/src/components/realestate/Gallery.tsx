'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, ArrowRight2, ArrowLeft2, Buildings2, CloseCircle, Home2 } from 'iconsax-react';
import { photo } from './format';

/** The brand panel standing in for a photograph that is not there. */
function Fallback({ hood, size }: { hood?: boolean; size: number }) {
  const Icon = hood ? Buildings2 : Home2;
  return (
    <span className="flex size-full items-center justify-center bg-[linear-gradient(135deg,#0058B5,#010A36)] text-white/30">
      <Icon size={size} color="currentColor" variant="Bold" />
    </span>
  );
}

/** Every photograph, one at a time, over a dark page (DetailPhotoViewer).
 *  Photographs page left to right in either language. */
function Viewer({ photos, start, onClose }: { photos: string[]; start: number; onClose: () => void }) {
  const [i, setI] = useState(start);
  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowRight') setI((n) => Math.min(n + 1, photos.length - 1));
      if (e.key === 'ArrowLeft') setI((n) => Math.max(n - 1, 0));
    };
    document.addEventListener('keydown', key);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { document.removeEventListener('keydown', key); document.body.style.overflow = overflow; };
  }, [photos.length, onClose]);
  return (
    <div dir="ltr" role="dialog" aria-modal className="fixed inset-0 z-[60] flex items-center justify-center bg-black/90" onClick={onClose}>
      <img src={photo(photos[i], 1000)} alt="" className="max-h-[calc(100vh-128px)] max-w-[calc(100vw-48px)] object-contain desk:max-w-[calc(100vw-192px)]" onClick={(e) => e.stopPropagation()} />
      <button type="button" aria-label="Close" onClick={onClose} className="absolute end-6 top-6 text-white"><CloseCircle size={32} color="currentColor" /></button>
      {i > 0 && (
        <button type="button" aria-label="Previous" onClick={(e) => { e.stopPropagation(); setI(i - 1); }} className="absolute left-3 top-1/2 -translate-y-1/2 p-3 text-white desk:left-6">
          <ArrowLeft2 size={40} color="currentColor" />
        </button>
      )}
      {i < photos.length - 1 && (
        <button type="button" aria-label="Next" onClick={(e) => { e.stopPropagation(); setI(i + 1); }} className="absolute right-3 top-1/2 -translate-y-1/2 p-3 text-white desk:right-6">
          <ArrowRight2 size={40} color="currentColor" />
        </button>
      )}
      <p className="absolute inset-x-0 bottom-6 text-center text-sm text-white">{i + 1} / {photos.length}</p>
    </div>
  );
}

/**
 * The website's photo block (DetailPhotoMosaic): the listing draws one large
 * panel and, beside it, a wide one over two small ones; the neighbourhood one
 * large and two stacked. Fewer photos draw what there is — two side by side,
 * or one across — and none draws the brand panel once. "Show all photos"
 * opens them full size.
 */
export function Mosaic({ photos, alt, fourUp, height, radius, gap, inset, showAll, hood = false }: {
  photos: string[]; alt: string; fourUp: boolean; height: number; radius: number; gap: number; inset: number; showAll: string; hood?: boolean;
}) {
  const [open, setOpen] = useState<number | null>(null);
  const n = photos.length;
  const panel = (i: number, width: number) => (
    <button type="button" key={i} onClick={() => setOpen(i)} className="block size-full min-h-0 min-w-0 overflow-hidden" aria-label={`${alt} ${i + 1}`}>
      <img src={photo(photos[i], width)} alt={i === 0 ? alt : ''} className="size-full object-cover" loading={i === 0 ? 'eager' : 'lazy'} />
    </button>
  );
  let grid: React.ReactNode;
  if (n === 0) grid = <Fallback hood={hood} size={80} />;
  else if (n === 1) grid = panel(0, 1200);
  else if (n === 2) grid = <div className="grid size-full grid-cols-2" style={{ gap }}>{panel(0, 600)}{panel(1, 600)}</div>;
  else if (n === 3 || !fourUp) {
    grid = (
      <div className="grid size-full grid-cols-2" style={{ gap }}>
        {panel(0, 600)}
        <div className="grid min-h-0 grid-rows-2" style={{ gap }}>{panel(1, 600)}{panel(2, 600)}</div>
      </div>
    );
  } else {
    grid = (
      <div className="grid size-full grid-cols-2" style={{ gap }}>
        {panel(0, 600)}
        <div className="grid min-h-0 grid-rows-2" style={{ gap }}>
          {panel(1, 600)}
          <div className="grid min-h-0 grid-cols-2" style={{ gap }}>{panel(2, 300)}{panel(3, 300)}</div>
        </div>
      </div>
    );
  }
  return (
    <div className="relative overflow-hidden" style={{ height, borderRadius: radius }}>
      {grid}
      {n > 1 && (
        <button type="button" onClick={() => setOpen(0)} style={{ insetInlineEnd: inset, bottom: inset }}
          className="absolute rounded-full bg-white/90 px-4 py-1.5 text-sm font-medium leading-6 text-navy hover:bg-white">
          {showAll}
        </button>
      )}
      {open != null && <Viewer photos={photos} start={open} onClose={() => setOpen(null)} />}
    </div>
  );
}

/** The phone layout's photographs: a 260 hero with the back button, a strip
 *  of 66 × 44 thumbnails under it with the one on show outlined; the hero
 *  opens them full size. [corner] is drawn at the hero's far end (share). */
export function PhoneGallery({ photos, alt, back, backLabel, corner, hood = false }: {
  photos: string[]; alt: string; back: string; backLabel: string; corner?: React.ReactNode; hood?: boolean;
}) {
  const [at, setAt] = useState(0);
  const [open, setOpen] = useState<number | null>(null);
  const shown = photos[Math.min(at, photos.length - 1)];
  return (
    <div>
      <div className="relative h-[260px] w-full overflow-hidden">
        {shown
          ? <button type="button" className="block size-full" onClick={() => setOpen(at)} aria-label={alt}><img src={photo(shown, 430)} alt={alt} className="size-full object-cover" /></button>
          : <Fallback hood={hood} size={80} />}
        <span className="pointer-events-none absolute inset-0 bg-gradient-to-b from-transparent to-black/40" />
        <Link href={back} aria-label={backLabel} className="absolute start-3 top-3 flex size-10 items-center justify-center rounded-full bg-white text-[#3D3D3D]">
          <ArrowLeft size={20} color="currentColor" className="rtl:-scale-x-100" />
        </Link>
        {corner && <div className="absolute end-3 top-3">{corner}</div>}
      </div>
      {photos.length > 1 && (
        <div className="flex gap-2 overflow-x-auto px-4 pt-4 [scrollbar-width:none]">
          {photos.map((p, i) => (
            <button key={p + i} type="button" onClick={() => setAt(i)} aria-label={`${alt} ${i + 1}`}
              className={`h-11 w-[66px] shrink-0 overflow-hidden rounded ${i === at ? 'outline-2 outline-midblue' : ''}`}>
              <img src={photo(p, 66)} alt="" loading="lazy" className="size-full object-cover" />
            </button>
          ))}
        </div>
      )}
      {open != null && <Viewer photos={photos} start={open} onClose={() => setOpen(null)} />}
    </div>
  );
}
