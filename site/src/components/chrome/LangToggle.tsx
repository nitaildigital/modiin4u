'use client';
import { useRouter } from 'next/navigation';
import { Global } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';

/** Hebrew or English, kept in a cookie for a year; the page draws again in
 *  the other language without leaving it. */
export function LangToggle({ lang }: { lang: Lang }) {
  const router = useRouter();
  return (
    <button
      type="button"
      dir="ltr"
      onClick={() => {
        document.cookie = `lang=${lang === 'he' ? 'en' : 'he'}; path=/; max-age=31536000; samesite=lax`;
        router.refresh();
      }}
      className="flex h-9 items-center gap-1.5 rounded-full border border-line px-3 text-[13px] font-medium text-midblue hover:bg-black/[.03]"
      aria-label={lang === 'he' ? 'Switch to English' : 'מעבר לעברית'}
    >
      <Global size={16} color="currentColor" />
      {lang === 'he' ? 'EN' : 'עב'}
    </button>
  );
}
