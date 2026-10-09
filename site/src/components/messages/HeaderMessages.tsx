'use client';
import Link from 'next/link';
import { MessageText, Profile } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { useSession, useUnreadMessages } from '@/lib/session';

/** The header's Messages icon, beside the bell: the conversations with the
 *  unread count when signed in, the sign-in page otherwise. Drawn only once
 *  the stored session has been read, so it does not flicker between them. */
export function HeaderMessages({ lang }: { lang: Lang }) {
  const { session, ready } = useSession();
  const unread = useUnreadMessages(!!session);
  if (!ready) return <span className="size-[38px]" aria-hidden />;
  const label = session ? (lang === 'he' ? 'הודעות' : 'Messages') : (lang === 'he' ? 'התחברות' : 'Sign in');
  const Icon = session ? MessageText : Profile;
  return (
    <Link href={session ? '/messages/' : '/signin/'} aria-label={unread ? `${label} (${unread})` : label} title={label}
      className="relative flex size-[38px] items-center justify-center rounded-full border border-line bg-white text-ink hover:bg-surface">
      <Icon size={20} color="currentColor" />
      {unread > 0 && (
        <span className="absolute -end-1 -top-1 flex h-[18px] min-w-[18px] items-center justify-center rounded-full bg-error px-1 text-[11px] font-semibold leading-none text-white">
          {unread > 9 ? '9+' : unread}
        </span>
      )}
    </Link>
  );
}
