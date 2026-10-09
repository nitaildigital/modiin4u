'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Bank, Clipboard, Home2, Map, Shop } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';

/** The phone layout's bottom menu (shell_scaffold.dart): home, businesses,
 *  map, news, municipal — the current one filled in blue. */
export function MobileTabBar({ lang }: { lang: Lang }) {
  const path = decodeURIComponent(usePathname() || '/');
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const tabs = [
    { href: '/', label: t('בית', 'Home'), Icon: Home2, on: path === '/' },
    { href: '/business/', label: t('עסקים', 'Businesses'), Icon: Shop, on: path.startsWith('/business') },
    { href: '/map/', label: t('מפה', 'Map'), Icon: Map, on: path.startsWith('/map') },
    { href: '/news/', label: t('חדשות', 'News'), Icon: Clipboard, on: path.startsWith('/news') || path.startsWith('/new/') },
    { href: '/municipal/', label: t('עירייה', 'Municipal'), Icon: Bank, on: path.startsWith('/municipal') },
  ];
  return (
    <>
      <div className="h-[76px] desk:hidden" aria-hidden />
      <nav className="fixed inset-x-0 bottom-0 z-40 grid grid-cols-5 border-t border-line bg-white pb-[env(safe-area-inset-bottom)] desk:hidden" aria-label={t('תפריט תחתון', 'Bottom menu')}>
        {tabs.map(({ href, label, Icon, on }) => (
          <Link key={href} href={href} className={`relative flex h-[76px] flex-col items-center justify-center gap-1 text-[13px] ${on ? 'font-medium text-midblue' : 'text-gray-meta'}`}>
            {on && <span className="absolute inset-x-3 top-0 h-[3px] rounded-b bg-midblue" />}
            <Icon size={26} color="currentColor" variant={on ? 'Bold' : 'Linear'} />
            {label}
          </Link>
        ))}
      </nav>
    </>
  );
}
