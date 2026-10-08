'use client';
import { useState } from 'react';
import { Notification } from 'iconsax-react';
import type { HomeNotice } from '@/lib/data/home';

/** "View details": a page on this site in place, anything else in a new tab. */
function DetailsLink({ notice, fallback, className }: { notice: HomeNotice; fallback: string; className: string }) {
  if (!notice.link) return null;
  const local = notice.link.startsWith('/');
  return (
    <a href={notice.link} className={className} {...(local ? {} : { target: '_blank', rel: 'noopener' })}>
      {notice.linkLabel ?? fallback}
    </a>
  );
}

/** The panel's site notice (a `home_blocks` alert), closed with its × for
 *  this visit. Desktop: the bar laid across the foot of the hero
 *  (_buildSiteNotice); phone: the card under the header (_buildNotice). */
export function NoticeBar({ notice, variant, details, close }: { notice: HomeNotice; variant: 'desk' | 'phone'; details: string; close: string }) {
  const [shut, setShut] = useState(false);
  if (shut) return null;
  const label = notice.label ? (notice.label.endsWith(':') ? notice.label : notice.label + ':') : null;

  if (variant === 'desk') {
    return (
      <div className="flex w-[950px] max-w-full items-center rounded-lg border border-[#FFD89A] bg-[#FEF5E1] px-4 py-3 text-xs leading-[1.21] text-black">
        <img src="/web/home/notice_bell.svg" alt="" width={20} height={20} className="size-5 shrink-0" />
        <p className="ms-[9px] flex min-w-0 flex-1 items-center gap-3">
          {label && <span className="shrink-0 font-medium">{label}</span>}
          {notice.message && <span className="truncate">{notice.message}</span>}
          <DetailsLink notice={notice} fallback={details} className="shrink-0 font-medium text-midblue underline" />
        </p>
        <button type="button" onClick={() => setShut(true)} title={close} aria-label={close} className="ms-3 shrink-0">
          <img src="/web/home/notice_close.svg" alt="" width={16} height={16} className="size-4" />
        </button>
      </div>
    );
  }

  return (
    <div className="mx-4 mt-4 flex items-start rounded-lg border border-[#FFD89A] bg-[#FEF5E1] py-3 ps-3.5 pe-1.5">
      <Notification size={18} color="#DC7600" className="mt-0.5 shrink-0" />
      <div className="ms-2.5 min-w-0 flex-1 text-[13px] leading-[1.4] text-black">
        <p>
          {notice.label && <span className="font-semibold">{notice.message ? label + ' ' : notice.label}</span>}
          {notice.message}
        </p>
        <DetailsLink notice={notice} fallback={details} className="mt-1.5 inline-block font-medium text-midblue underline" />
      </div>
      <button type="button" onClick={() => setShut(true)} aria-label={close} className="shrink-0 p-2 text-ink">
        <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" /></svg>
      </button>
    </div>
  );
}
