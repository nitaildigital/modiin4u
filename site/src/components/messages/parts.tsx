'use client';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Messages2 } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb } from '@/lib/session';

/** A round photo, or the name's first letter on the brand's pale blue. */
export function Avatar({ url, name, size }: { url: string | null | undefined; name: string; size: number }) {
  const initial = name.trim().charAt(0) || '?';
  return url ? (
    <img src={url} alt="" loading="lazy" className="shrink-0 rounded-full bg-surface object-cover" style={{ width: size, height: size }} />
  ) : (
    <span className="flex shrink-0 items-center justify-center rounded-full bg-midblue/[0.08] font-semibold text-midblue"
      style={{ width: size, height: size, fontSize: size * 0.38 }}>{initial}</span>
  );
}

/** "14:05" today, "Yesterday", or "8/10" further back — day first, as dates
 *  are written in Israel (the app's _listTime). */
export function listTime(iso: string, lang: Lang): string {
  const d = new Date(iso);
  const now = new Date();
  const day = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const days = Math.round((day(now) - day(d)) / 86_400_000);
  if (days <= 0) return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  if (days === 1) return lang === 'he' ? 'אתמול' : 'Yesterday';
  return `${d.getDate()}/${d.getMonth() + 1}`;
}

/** What a signed-out visitor sees on the Messages pages. */
export function SignInFirst({ lang, next }: { lang: Lang; next: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <div className="flex flex-col items-center py-16 text-center">
      <span className="flex size-[72px] items-center justify-center rounded-full bg-midblue/[0.08]"><Messages2 size={32} color="#123A72" /></span>
      <p className="mt-5 text-lg font-semibold text-ink">{t('התחברו כדי לראות את ההודעות', 'Sign in to see your messages')}</p>
      <p className="mt-2 max-w-sm text-sm text-[#6D6D6D]">{t('השיחות עם עסקים נשמרות בחשבון שלכם.', 'Conversations with businesses are kept with your account.')}</p>
      <Link href={`/signin/?next=${encodeURIComponent(next)}`}
        className="mt-6 flex h-12 items-center rounded-full bg-midblue px-10 text-base font-medium text-white hover:bg-midblue/90">
        {t('התחברות', 'Sign in')}
      </Link>
    </div>
  );
}

export function SignOutLink({ lang }: { lang: Lang }) {
  const router = useRouter();
  return (
    <button type="button" className="text-sm font-medium text-[#6D6D6D] hover:text-midblue"
      onClick={async () => { await sessionDb().auth.signOut().catch(() => {}); router.replace('/'); }}>
      {lang === 'he' ? 'יציאה' : 'Sign out'}
    </button>
  );
}
