import Link from 'next/link';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { getMenus } from '@/lib/menu';
import { LangToggle } from './LangToggle';
import { NavLinks } from './NavLinks';
import { navItems } from './nav-items';
import { MobileMenu } from './MobileMenu';

function Logo({ className = '' }: { className?: string }) {
  return (
    <Link href="/" aria-label="מודיעין בשבילך" className={`shrink-0 ${className}`}>
      {/* The white logo, drawn in the brand's mid blue. */}
      <span
        className="block h-12 w-[90px] bg-midblue"
        style={{ mask: 'url(/brand/logo_white.svg) center / contain no-repeat', WebkitMask: 'url(/brand/logo_white.svg) center / contain no-repeat' }}
      />
    </Link>
  );
}

/** The site's header: a full-width white bar on inner pages, a white pill
 *  floating over the hero on the home page (Figma "Header/07"). Below 1100
 *  the phone layout's top bar instead. The bar is laid out right to left in
 *  both languages, as the design draws it. */
export async function Header({ floating = false }: { floating?: boolean }) {
  const lang = await getLang();
  const t = tr(lang);
  const menus = await getMenus(lang);
  const items = navItems(lang);
  const contact = menus.more.find((m) => m.path.includes('יצירת-קשר'));
  const row = (
    <div dir="rtl" className="flex h-20 items-center gap-5">
      <Logo />
      <nav className="flex min-w-0 flex-1 justify-center" dir={lang === 'he' ? 'rtl' : 'ltr'} aria-label={t('ראשי', 'Main')}>
        <NavLinks items={lang === 'he' ? items : [...items]} menus={menus} floating={floating} />
      </nav>
      <div className="flex shrink-0 items-center gap-3">
        <LangToggle lang={lang} />
        <a href={encodeURI(contact?.path ?? '/יצירת-קשר/')}
          className="flex h-[46px] items-center rounded-full bg-midblue px-6 text-base font-medium text-white hover:bg-midblue/90">
          {t('צור קשר', 'Contact Us')}
        </a>
      </div>
    </div>
  );
  return (
    <>
      <header className={floating ? 'absolute inset-x-0 top-8 z-40 hidden desk:block' : 'sticky top-0 z-40 hidden border-b border-line bg-white desk:block'}>
        {floating ? (
          <div className="wrap">
            <div className="rounded-[50px] bg-white ps-6 pe-5 shadow-[0_4px_20px_rgba(0,0,0,0.06)]">{row}</div>
          </div>
        ) : (
          <div className="wrap">{row}</div>
        )}
      </header>
      {!floating && (
        <header className="sticky top-0 z-40 flex h-14 items-center justify-between border-b border-line bg-white px-4 desk:hidden">
          <Logo className="scale-75" />
          <MobileMenu lang={lang} menus={menus} items={items} />
        </header>
      )}
    </>
  );
}
