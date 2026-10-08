import Link from 'next/link';
import { ArrowLeft, ArrowRight } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';

/** The arrow that points back in the page's direction: right in Hebrew,
 *  left in English (arrow_right_3 / arrow_left in the app). */
export function BackArrow({ lang, size = 20, color = 'currentColor' }: { lang: Lang; size?: number; color?: string }) {
  return lang === 'he' ? <ArrowRight size={size} color={color} /> : <ArrowLeft size={size} color={color} />;
}

/** "← Back" above a page's title, as the site's inner pages draw it. */
export function BackLink({ href, label, lang, className = '' }: { href: string; label: string; lang: Lang; className?: string }) {
  return (
    <div className={className}>
      <Link href={href} className="inline-flex items-center gap-2 text-[15px] font-medium text-midblue">
        <BackArrow lang={lang} />
        {label}
      </Link>
    </div>
  );
}

/** The phone layout's bar under the site's own: the back arrow, and the
 *  page's name in the middle (MBackArrow and the title in the app). */
export function PhoneBar({ back, lang, children }: { back?: string; lang: Lang; children: React.ReactNode }) {
  return (
    <div className="relative flex h-11 items-center justify-center desk:hidden">
      {back && (
        <Link href={back} aria-label={lang === 'he' ? 'חזרה' : 'Back'} className="absolute start-0 text-[#3D3D3D]">
          <BackArrow lang={lang} size={24} />
        </Link>
      )}
      <div className="px-10 text-center">{children}</div>
    </div>
  );
}
