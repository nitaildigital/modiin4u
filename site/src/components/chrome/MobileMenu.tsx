'use client';
import Link from 'next/link';
import { useState } from 'react';
import { CloseCircle, HambergerMenu } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import type { Menus } from '@/lib/menu';
import type { NavItem } from './NavLinks';
import { LangToggle } from './LangToggle';

/** The phone layout's menu: the sections, then the old site's menu groups. */
export function MobileMenu({ lang, menus, items }: { lang: Lang; menus: Menus; items: NavItem[] }) {
  const [open, setOpen] = useState(false);
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const groups: [string, Menus[keyof Menus]][] = [
    [t('עסקים', 'Businesses'), menus.businesses],
    [t('בעלי מקצוע', 'Professionals'), menus.professionals],
    [t('חדשות', 'News'), menus.news],
    [t('עוד', 'More'), menus.more],
  ];
  return (
    <>
      <button type="button" onClick={() => setOpen(true)} aria-label={t('תפריט', 'Menu')} className="p-2 text-ink">
        <HambergerMenu size={26} color="currentColor" />
      </button>
      {open && (
        <div className="fixed inset-0 z-50 flex" role="dialog" aria-modal>
          <button type="button" className="flex-1 bg-black/40" aria-label={t('סגירה', 'Close')} onClick={() => setOpen(false)} />
          <div className="h-full w-[86%] max-w-sm overflow-y-auto bg-white p-5">
            <div className="mb-5 flex items-center justify-between">
              <LangToggle lang={lang} />
              <button type="button" onClick={() => setOpen(false)} aria-label={t('סגירה', 'Close')}><CloseCircle size={28} color="#123A72" /></button>
            </div>
            <ul className="mb-6 flex flex-col gap-4">
              {items.map((i) => (
                <li key={i.id}><Link href={i.href} onClick={() => setOpen(false)} className="text-lg font-medium text-ink">{i.label}</Link></li>
              ))}
              {/* Where a visitor turns notifications on and reads them. */}
              <li><Link href="/notifications/" onClick={() => setOpen(false)} className="text-lg font-medium text-ink">{t('התראות', 'Notifications')}</Link></li>
              {/* Messages with businesses (9 Oct); the sign-in page when signed out. */}
              <li><Link href="/messages/" onClick={() => setOpen(false)} className="text-lg font-medium text-ink">{t('הודעות', 'Messages')}</Link></li>
            </ul>
            {groups.map(([title, links]) => links.length > 0 && (
              <details key={title} className="border-t border-line py-3">
                <summary className="cursor-pointer text-base font-semibold text-midblue">{title}</summary>
                <ul className="mt-3 flex flex-col gap-3">
                  {links.map((l) => (
                    <li key={l.path}><a href={encodeURI(l.path)} className="text-sm text-ink">{l.label}</a></li>
                  ))}
                </ul>
              </details>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
