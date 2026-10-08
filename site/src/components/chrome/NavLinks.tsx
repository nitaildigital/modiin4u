'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { MenuLink } from '@/lib/menu';

export type NavItem = { id: string; label: string; href: string; menu?: 'businesses' | 'professionals' | 'news'; match: string[] };

/** The bar's links; the current section underlined. A link with a menu opens
 *  it on hover or focus — the menu's links are in the page either way. */
export function NavLinks({ items, menus, floating }: {
  items: NavItem[];
  menus: Record<'businesses' | 'professionals' | 'news', MenuLink[]>;
  floating: boolean;
}) {
  const path = decodeURIComponent(usePathname() || '/');
  return (
    <ul className={`flex items-center ${floating ? 'gap-4' : 'gap-5'}`}>
      {items.map((item) => {
        const active = !floating && item.match.some((m) => path.startsWith(m));
        const entries = item.menu ? menus[item.menu] : [];
        return (
          // The news card hangs under its link; the two wide menus are
          // centred on the page, as the client's site does.
          <li key={item.id} className={`group ${item.menu === 'news' ? 'relative' : ''}`}>
            <Link
              href={item.href}
              className={`flex h-20 items-center border-b-[3px] ${active ? 'border-midblue' : 'border-transparent'}`}
            >
              <span className={`flex h-12 items-center gap-2 whitespace-nowrap rounded-full px-2 text-[15px] leading-relaxed group-hover:bg-black/[.04] ${active ? 'font-semibold text-midblue' : 'font-medium text-ink'}`}>
                {item.label}
                {item.menu && (
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden className={active ? 'text-midblue' : 'text-ink'}>
                    <path d="M19.92 8.95l-6.52 6.52c-.77.77-2.03.77-2.8 0L4.08 8.95" stroke="currentColor" strokeWidth="1.5" strokeMiterlimit="10" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                )}
              </span>
            </Link>
            {entries.length > 0 && (
              <div className={`absolute top-full z-50 hidden pt-1 group-focus-within:block group-hover:block ${item.menu === 'news' ? 'start-0' : 'inset-x-0 mx-auto w-fit'}`}>
                <div className={`rounded-xl bg-white shadow-[0_1px_5px_rgba(0,0,0,0.1)] ${item.menu === 'news' ? 'w-66 p-4' : 'w-[min(1130px,calc(100vw-48px))] p-8'}`}>
                  <ul className={item.menu === 'news' ? 'flex flex-col gap-5' : item.menu === 'businesses' ? 'grid grid-flow-col grid-cols-3 gap-x-6 gap-y-5' : 'grid grid-flow-col grid-cols-2 gap-x-6 gap-y-5'}
                    style={item.menu === 'news' ? undefined : { gridTemplateRows: `repeat(${Math.ceil(entries.length / (item.menu === 'businesses' ? 3 : 2))}, auto)` }}>
                    {entries.map((e) => (
                      <li key={e.path}>
                        <a href={encodeURI(e.path)} className="block truncate text-sm text-black hover:text-midblue">{e.label}</a>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}
          </li>
        );
      })}
    </ul>
  );
}
