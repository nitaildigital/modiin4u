'use client';
import Link from 'next/link';
import { Notification } from 'iconsax-react';
import { usePush } from './usePush';

/** The header's bell (web_chrome.dart, _BellButton): the page where a
 *  visitor turns notifications on and reads them, with the unread count. */
export function Bell({ lang }: { lang: 'he' | 'en' }) {
  const { unread } = usePush();
  const label = lang === 'he' ? 'התראות' : 'Notifications';
  return (
    <Link href="/notifications/" aria-label={unread ? `${label} (${unread})` : label}
      className="relative flex size-[38px] items-center justify-center rounded-full border border-line bg-white text-ink hover:bg-surface">
      <Notification size={20} color="currentColor" />
      {unread > 0 && (
        <span className="absolute -end-1 -top-1 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-error px-1 text-[11px] font-semibold leading-none text-white">
          {unread > 9 ? '9+' : unread}
        </span>
      )}
    </Link>
  );
}
