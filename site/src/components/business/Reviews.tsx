'use client';
import { useEffect, useRef, useState } from 'react';

export type ReviewView = {
  id: string; author: string; initials: string; date: string; rating: number; body: string;
  avatar: string | null; photos: string[];
  replies: { id: string; author: string; date: string; body: string }[];
};

const HEBREW = /[֐-׿]/;
const dirOf = (s: string) => (HEBREW.test(s) ? 'rtl' : 'ltr');

/** Five stars, [value] of them full (web_business_detail_screen _Stars). */
export function Stars({ value, big = false }: { value: number; big?: boolean }) {
  const s = big ? 24 : 14;
  return (
    <span className={`flex ${big ? 'gap-[7px]' : 'gap-1'}`} dir="ltr" aria-label={`${value} / 5`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <img key={i} src={`/web/business/star${s}_${i <= value ? 'full' : 'empty'}.svg`} alt="" width={s} height={s} />
      ))}
    </span>
  );
}

type Order = 'recent' | 'highest' | 'lowest';

/** "Sort By: Most Recent ⌄": a 40-tall ringed box opening its choices under it. */
function Dropdown<T extends string | number | null>({ label, options, selected, onSelect }: {
  label: string; options: [T, string][]; selected: T; onSelect: (v: T) => void;
}) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const down = (e: MouseEvent) => { if (!box.current?.contains(e.target as Node)) setOpen(false); };
    document.addEventListener('mousedown', down);
    return () => document.removeEventListener('mousedown', down);
  }, [open]);
  return (
    <div ref={box} className="relative">
      <button type="button" onClick={() => setOpen(!open)}
        className="flex h-10 items-center gap-2 rounded-lg border border-line bg-white px-3 text-sm font-medium text-[#3D3D3D]">
        {label}<img src="/web/business/chevron14.svg" alt="" width={14} height={14} />
      </button>
      {open && (
        <ul role="listbox" className="absolute start-0 top-full z-20 mt-1.5 min-w-full rounded-lg border border-line bg-white py-1 shadow-[0_6px_16px_rgba(0,0,0,0.12)]">
          {options.map(([v, text]) => (
            <li key={String(v)}>
              <button type="button" role="option" aria-selected={v === selected} onClick={() => { onSelect(v); setOpen(false); }}
                className={`flex h-10 w-full items-center whitespace-nowrap px-4 text-start text-sm ${v === selected ? 'font-semibold text-midblue' : 'font-medium text-[#3D3D3D]'} hover:bg-section`}>
                {text}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

/** The desktop review list: the score and its spread, sorting, a filter by
 *  stars, five at a time with the last fading under "Load More". */
export function DesktopReviews({ reviews, he }: { reviews: ReviewView[]; he: boolean }) {
  const t = (h: string, e: string) => (he ? h : e);
  const [order, setOrder] = useState<Order>('recent');
  const [stars, setStars] = useState<number | null>(null);
  const [shown, setShown] = useState(5);

  const total = reviews.length;
  const avg = total ? reviews.reduce((s, r) => s + r.rating, 0) / total : 0;
  const share = (score: number) => (total ? reviews.filter((r) => r.rating === score).length / total : 0);

  const filtered = reviews.filter((r) => stars == null || r.rating === stars);
  // Newest first as they arrive; a stable sort keeps that within a score.
  if (order === 'highest') filtered.sort((a, b) => b.rating - a.rating);
  if (order === 'lowest') filtered.sort((a, b) => a.rating - b.rating);
  const list = filtered.slice(0, shown);
  const more = filtered.length > list.length;

  const orders: [Order, string][] = [['recent', t('האחרונות', 'Most Recent')], ['highest', t('הדירוג הגבוה', 'Highest Rated')], ['lowest', t('הדירוג הנמוך', 'Lowest Rated')]];
  const ratingLabel = (s: number | null) => (s == null ? t('הכל', 'All') : `${s} ★`);

  return (
    <>
      <div className="flex items-stretch">
        <div className="flex w-60 shrink-0 flex-col justify-center border-e border-line py-4">
          <p className="text-[48px] font-semibold leading-[1.21] text-black">{avg.toFixed(1)}</p>
          <div className="mt-4"><Stars value={Math.round(avg)} big /></div>
          <p className="mt-4 text-base leading-[1.19] text-[#3D3D3D]">{t(`מבוסס על ${total} ביקורות`, `Based on ${total} reviews`)}</p>
        </div>
        <div className="ms-[81px] flex w-[393px] flex-col justify-center gap-3">
          {[5, 4, 3, 2, 1].map((score) => (
            <div key={score} className="flex items-center">
              <span className="flex h-[22px] w-[42px] shrink-0 items-center gap-2 text-base font-medium text-black">
                {score}<img src="/web/business/star16.svg" alt="" width={16} height={16} />
              </span>
              <span className="ms-[11px] h-1.5 flex-1 overflow-hidden rounded-md bg-line">
                <span className="block h-full bg-turquoise" style={{ width: `${Math.round(share(score) * 100)}%` }} />
              </span>
              <span className="ms-[11px] w-[38px] shrink-0 text-end text-sm font-medium text-[#6D6D6D]">{Math.round(share(score) * 100)}%</span>
            </div>
          ))}
        </div>
      </div>

      <div className="mt-[30px] flex gap-3">
        <Dropdown label={t(`מיון: ${orders.find((o) => o[0] === order)![1]}`, `Sort By: ${orders.find((o) => o[0] === order)![1]}`)}
          options={orders} selected={order} onSelect={(v) => { setOrder(v); setShown(5); }} />
        <Dropdown<number | null> label={t(`דירוג: ${ratingLabel(stars)}`, `Rating: ${ratingLabel(stars)}`)}
          options={[null, 5, 4, 3, 2, 1].map((v) => [v, ratingLabel(v)] as [number | null, string])} selected={stars}
          onSelect={(v) => { setStars(v); setShown(5); }} />
      </div>

      <div className="relative mt-[30px]">
        {filtered.length === 0 ? (
          <p className="py-4 text-base text-[#3D3D3D]">{t('אין ביקורות בדירוג הזה.', 'No reviews with this rating.')}</p>
        ) : (
          <ul>{list.map((r) => <ReviewRow key={r.id} r={r} />)}</ul>
        )}
        {more && (
          <>
            <div className="pointer-events-none absolute inset-x-0 -bottom-0.5 h-[222px] bg-gradient-to-b from-white/0 to-white to-[98%]" />
            <div className="absolute inset-x-0 bottom-0.5 flex justify-center">
              <button type="button" onClick={() => setShown(shown + 5)}
                className="h-[46px] rounded-full border border-midblue bg-white px-8 text-base font-medium text-midblue">
                {t('טען עוד', 'Load More')}
              </button>
            </div>
          </>
        )}
      </div>
    </>
  );
}

/** The author's photo when they agreed to show it (00076), else initials. */
export function ReviewAvatar({ r, className }: { r: ReviewView; className: string }) {
  return r.avatar
    ? <img src={r.avatar} alt="" className={`${className} shrink-0 rounded-full object-cover`} loading="lazy" />
    : <span className={`${className} flex shrink-0 items-center justify-center rounded-full bg-turquoise font-semibold uppercase text-white`}>{r.initials}</span>;
}

/** Photographs attached to a review, each opening full size. */
export function ReviewPhotos({ photos, size }: { photos: string[]; size: number }) {
  if (!photos.length) return null;
  return (
    <div className="mt-2.5 flex flex-wrap gap-2">
      {photos.map((u) => (
        <a key={u} href={u} target="_blank" rel="noopener">
          <img src={u} alt="" width={size} height={size} style={{ width: size, height: size }} className="rounded-[10px] object-cover" loading="lazy" />
        </a>
      ))}
    </div>
  );
}

function ReviewRow({ r }: { r: ReviewView }) {
  return (
    <li className="flex gap-[15px] border-b border-line py-4">
      <ReviewAvatar r={r} className="size-10 text-sm" />
      <div className="min-w-0 flex-1">
        <p className="flex items-center gap-3">
          <span dir={dirOf(r.author)} className="text-base font-medium text-black">{r.author}</span>
          <span className="text-xs text-[#6D6D6D]">{r.date}</span>
        </p>
        <div className="mt-[7px]"><Stars value={r.rating} /></div>
        {r.body && <p dir={dirOf(r.body)} className="mt-[7px] whitespace-pre-line text-sm leading-[1.4] text-[#3D3D3D]">{r.body}</p>}
        <ReviewPhotos photos={r.photos} size={96} />
        {r.replies.map((x) => (
          <div key={x.id} className="mt-3 border-s-2 border-line ps-3.5">
            <p className="flex items-center gap-3">
              <span className="text-sm font-medium text-black">{x.author}</span>
              <span className="text-xs text-[#6D6D6D]">{x.date}</span>
            </p>
            <p dir={dirOf(x.body)} className="mt-[5px] whitespace-pre-line text-sm leading-[1.4] text-[#3D3D3D]">{x.body}</p>
          </div>
        ))}
      </div>
    </li>
  );
}
