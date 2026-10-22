import Link from 'next/link';
import { CONTACT } from '@/lib/config';
import { tr, type Lang } from '@/lib/i18n';
import { db } from '@/lib/supabase';
import { getMenus } from '@/lib/menu';

/** A store link, only when the panel has given an https address. */
function store(settings: Record<string, unknown>, k: string): string | null {
  const v = settings[k];
  return typeof v === 'string' && v.trim().startsWith('https://') ? v.trim() : null;
}

function FooterLink({ href, children }: { href: string; children: React.ReactNode }) {
  const external = /^(https?:|mailto:|tel:)/.test(href);
  const cls = 'text-sm text-white hover:underline';
  return external ? <a href={href} className={cls}>{children}</a> : <Link href={href} className={cls}>{children}</Link>;
}

function Column({ title, links, more }: { title: string; links: [string, string][]; more?: [string, string] }) {
  return (
    <div className="w-[171px]">
      <h2 className="mb-6 text-base font-semibold text-white">{title}</h2>
      <ul className="flex flex-col gap-5">
        {links.map(([label, href]) => <li key={href + label}><FooterLink href={href}>{label}</FooterLink></li>)}
        {more && (
          <li>
            <Link href={more[1]} className="flex items-center gap-2 text-sm font-medium text-turquoise">
              {more[0]}
              <img src="/icons/footer/arrow_right.svg" alt="" width={16} height={16} className="rtl:-scale-x-100" />
            </Link>
          </li>
        )}
      </ul>
    </div>
  );
}

/** A link group on the phone: closed to its title until tapped, its links
 *  in two columns. The desktop's columns stacked made the phone's footer
 *  ~2,400 px tall — longer than the home page (the client, 14 Oct). The
 *  links stay in the page either way. */
function Fold({ title, links, more }: { title: string; links: [string, string][]; more?: [string, string] }) {
  return (
    <details className="group border-t border-white/15">
      <summary className="flex cursor-pointer list-none items-center justify-between py-4 text-base font-semibold [&::-webkit-details-marker]:hidden">
        {title}
        <img src="/icons/footer/arrow_right.svg" alt="" width={16} height={16} className="rotate-90 transition-transform group-open:-rotate-90" />
      </summary>
      <ul className="grid grid-cols-2 gap-x-4 gap-y-3.5 pb-5">
        {links.map(([label, href]) => <li key={href + label}><FooterLink href={href}>{label}</FooterLink></li>)}
        {more && (
          <li>
            <Link href={more[1]} className="flex items-center gap-2 text-sm font-medium text-turquoise">
              {more[0]}
              <img src="/icons/footer/arrow_right.svg" alt="" width={16} height={16} className="rtl:-scale-x-100" />
            </Link>
          </li>
        )}
      </ul>
    </details>
  );
}

/** The footer (Figma "Frame 1171276559"): contact, three link columns, the
 *  app badges, the about paragraph; the legal links and PersonaAI under it. */
export async function Footer({ lang }: { lang: Lang }) {
  const t = tr(lang);
  // The footer is on every page: a failed read leaves its store links out
  // rather than failing the page.
  const data = await db.from('app_settings').select('key, value').then((r) => r.data, () => null);
  const settings = Object.fromEntries((data ?? []).map((r) => [r.key, r.value]));
  const ios = store(settings, 'store_url_ios');
  const android = store(settings, 'store_url_android');
  const menus = await getMenus(lang);
  const realEstate = menus.more.filter((m) => !m.path.includes('יצירת-קשר'));

  const siteLinks: [string, string][] = [
    [t('בית', 'Home'), '/'], [t('אודותינו', 'About Us'), '/about/'], [t('צור קשר', 'Contact Us'), encodeURI('/יצירת-קשר/')],
    [t('קבלת התראות', 'Get notifications'), '/notifications/'],
    [t('מדיניות פרטיות', 'Privacy Policy'), '/privacy/'], [t('תנאי שימוש', 'Terms of Use'), '/terms/'],
    [t('הצהרת נגישות', 'Accessibility Statement'), '/accessibility/'], [t('מחיקת חשבון', 'Delete account'), '/delete-account/'],
  ];
  const exploreLinks: [string, string][] = [
    [t('חדשות', 'News'), '/news/'], [t('אירועים', 'Events'), '/events/'], [t('עסקים', 'Businesses'), '/business/'],
    [t('בעלי מקצוע', 'Professionals'), '/professionals/'], [t('נדל״ן', 'Real Estate'), '/search-apartments/'], [t('מפה', 'Map'), '/map/'],
    [t('מסעדות', 'Restaurants'), '/search-rest-modiin/'], [t('מבצעים', 'Deals'), '/deals/'], [t('קהילה', 'Community'), '/community/'],
  ];
  const popularLinks: [string, string][] = [
    [t('מסעדות במודיעין', 'Restaurants in Modiin'), '/search-rest-modiin/'],
    [t('בתי קפה', 'Coffee Shops'), '/business-cat/modiin-coffee/'],
    [t('ברים', 'Bars'), encodeURI('/business-cat/ברים/')],
    [t('בעלי מקצוע', 'Professionals'), '/professionals/'],
    ...realEstate.map((m): [string, string] => [m.label, encodeURI(m.path)]),
    [t('עסקים מקומיים', 'Local Businesses'), '/business/'],
  ];
  const viewAll: [string, string] = [t('הצג הכל', 'View all'), '/business/'];
  const about = t('אנחנו לא סתם אתר חדשות – אנחנו הלב הפועם של מודיעין! ארגון מדיה ויחסי ציבור מקומי שחי ונושם את העיר שלנו. עם מגוון רחב של פלטפורמות דיגיטליות, בחיבור ישיר לתושבים, אנחנו מביאים לכם את כל מה שבאמת חשוב.',
    'We are not just a news site – we are the beating heart of Modiin! A local media and public relations organization that lives and breathes our city. With a wide range of digital platforms, connected directly to residents, we bring you everything that really matters.');
  const badges = (
    <>
      <a href={ios ?? undefined} className="flex h-10 w-[120px] items-center gap-2 rounded-md bg-white px-2 text-black">
        <img src="/icons/footer/apple.svg" alt="" width={20} height={24} />
        <span className="leading-none"><span className="block text-[9px] font-medium">Download on the</span><span className="block text-[17px] font-semibold tracking-tight">App Store</span></span>
      </a>
      <a href={android ?? undefined} className="flex h-10 w-[120px] items-center gap-2 rounded-md bg-white px-2 text-black">
        <img src="/icons/footer/playstore.svg" alt="" width={21} height={24} />
        <span className="leading-none"><span className="block text-[9px]">GET IT ON</span><img src="/icons/footer/google_play_word.svg" alt="Google Play" width={74} height={15} className="mt-1 -scale-y-100" /></span>
      </a>
    </>
  );
  const socials = (
    <div className="flex gap-2.5">
      <a href={CONTACT.facebook} aria-label="Facebook" className="relative block size-[38px]"><img src="/icons/footer/ring38.svg" alt="" className="absolute inset-0" /><img src="/icons/footer/facebook_glyph.svg" alt="" className="absolute left-1/2 top-1/2 h-4 -translate-1/2" /></a>
      <a href={CONTACT.instagram} aria-label="Instagram"><img src="/icons/footer/instagram38.svg" alt="" width={38} height={38} /></a>
      <a href={CONTACT.tiktok} aria-label="TikTok" className="relative block size-[38px]"><img src="/icons/footer/ring38.svg" alt="" className="absolute inset-0" /><span className="absolute inset-0 flex items-center justify-center text-sm">♪</span></a>
    </div>
  );

  // The email only: the phone and WhatsApp rows (and the WhatsApp icon among
  // the socials) carried a personal number, taken off on request (22 Oct).
  const contact: [string, string, string, string][] = [
    ['/icons/footer/email40.svg', t('אימייל', 'Email'), CONTACT.email, `mailto:${CONTACT.email}`],
  ];

  return (
    <footer className="bg-midblue pt-10 text-white desk:pt-16">
      <div className="wrap">
        {/* The phone: contact, the three groups folded, the badges side by
            side, a smaller logo — everything aligned to the reading side. */}
        <div className="desk:hidden">
          <p className="text-2xl font-medium leading-[1.21]">{t('אנחנו כאן לכל שאלה.', 'We are here for any questions.')}</p>
          <ul className="mt-6 flex flex-col gap-4">
            {contact.map(([icon, label, value, href]) => (
              <li key={label}>
                <a href={href} className="flex items-center gap-3">
                  {href.startsWith('tel:') ? (
                    <span className="relative block size-9 shrink-0">
                      <img src="/icons/footer/ring40.svg" alt="" className="absolute inset-0 size-full" />
                      <img src="/icons/footer/phone_glyph.svg" alt="" className="absolute left-1/2 top-1/2 size-[15px] -translate-1/2" />
                    </span>
                  ) : <img src={icon} alt="" width={36} height={36} className="shrink-0" />}
                  <span className="min-w-0">
                    <span className="block text-xs font-medium text-white/80">{label}</span>
                    <span className="block truncate text-[15px]" dir="ltr">{value}</span>
                  </span>
                </a>
              </li>
            ))}
          </ul>
          <div className="mt-6">{socials}</div>
          <div className="mt-8">
            <Fold title={t('מודיעין4u', 'Modiin4u')} links={siteLinks} />
            <Fold title={t('גלו את מודיעין', 'Explore Modiin')} links={exploreLinks} more={viewAll} />
            <Fold title={t('קטגוריות פופולריות', 'Popular Categories')} links={popularLinks} more={viewAll} />
          </div>
          <div className="border-t border-white/15 pt-6">
            <h2 className="text-base font-semibold">{t('הורידו את האפליקציה', 'Download Our App')}</h2>
            <div className="mt-4 flex flex-wrap gap-3" dir="ltr">{badges}</div>
          </div>
          <div className="mt-8 border-t border-white/15 pt-6">
            <span className="block h-[52px] w-[100px] bg-white" style={{ mask: 'url(/brand/logo_white.svg) center / contain no-repeat', WebkitMask: 'url(/brand/logo_white.svg) center / contain no-repeat' }} />
            <p className="mt-4 text-xs leading-[1.5] text-white/90">{about}</p>
            <Link href="/about/" className="mt-3 inline-flex items-center gap-2 text-sm font-medium text-turquoise">
              {t('קראו עוד', 'Read more')}
              <img src="/icons/footer/arrow_right.svg" alt="" width={16} height={16} className="rtl:-scale-x-100" />
            </Link>
          </div>
        </div>

        <div className="hidden flex-wrap justify-between gap-x-12 gap-y-10 desk:flex">
          <div className="w-[321px] max-w-full">
            <p className="text-[32px] font-medium leading-[1.21]">{t('אנחנו כאן לכל שאלה.', 'We are here for any questions.')}</p>
            <ul className="mt-10 flex flex-col gap-[34px]">
              {contact.map(([icon, label, value, href]) => (
                <li key={label}>
                  <a href={href} className="flex items-center gap-4">
                    {href.startsWith('tel:') ? (
                      <span className="relative block size-10">
                        <img src="/icons/footer/ring40.svg" alt="" className="absolute inset-0" />
                        <img src="/icons/footer/phone_glyph.svg" alt="" className="absolute left-1/2 top-1/2 size-[17px] -translate-1/2" />
                      </span>
                    ) : <img src={icon} alt="" width={40} height={40} />}
                    <span>
                      <span className="block text-sm font-medium">{label}</span>
                      <span className="mt-1.5 block text-base" dir="ltr">{value}</span>
                    </span>
                  </a>
                </li>
              ))}
            </ul>
            <h2 className="mt-10 text-base font-semibold">{t('הרשתות שלנו', 'Our Socials')}</h2>
            <div className="mt-5">{socials}</div>
          </div>

          <div className="flex flex-col gap-12">
            <Column title={t('מודיעין4u', 'Modiin4u')} links={siteLinks} />
            <div>
              <h2 className="mb-5 text-base font-semibold">{t('הורידו את האפליקציה', 'Download Our App')}</h2>
              <div className="flex flex-col gap-3" dir="ltr">{badges}</div>
            </div>
          </div>

          <Column title={t('גלו את מודיעין', 'Explore Modiin')} more={viewAll} links={exploreLinks} />
          <Column title={t('קטגוריות פופולריות', 'Popular Categories')} more={viewAll} links={popularLinks} />

          <div className="flex w-[328px] max-w-full flex-col items-end text-end">
            <span className="block h-[88px] w-[164px] bg-white" style={{ mask: 'url(/brand/logo_white.svg) center / contain no-repeat', WebkitMask: 'url(/brand/logo_white.svg) center / contain no-repeat' }} />
            <p className="mt-6 text-sm font-medium">{t('מודיעין בשבילך', 'Modiin for You')}</p>
            <p className="mt-4 text-xs leading-[1.4]">{about}</p>
            <Link href="/about/" className="mt-6 flex items-center gap-2 text-sm font-medium text-turquoise">
              {t('קראו עוד', 'Read more')}
              <img src="/icons/footer/arrow_right.svg" alt="" width={16} height={16} className="rtl:-scale-x-100" />
            </Link>
          </div>
        </div>

        <div className="mt-8 flex flex-col items-center gap-3 border-t border-white/15 py-4 text-center text-xs text-line desk:mt-16 desk:flex-row desk:flex-wrap desk:justify-between desk:border-0 desk:text-start desk:text-sm">
          <span>{t('כל הזכויות שמורות ל-modiin4u.co.il, 2026', 'All Rights Reserved to modiin4u.co.il, 2026')}</span>
          <span className="flex gap-3">
            <Link href="/terms/" className="hover:underline">{t('תנאי שימוש', 'Terms of Use')}</Link>|
            <Link href="/privacy/" className="hover:underline">{t('מדיניות פרטיות', 'Privacy Policy')}</Link>|
            <Link href="/delete-account/" className="hover:underline">{t('מחיקת חשבון', 'Delete account')}</Link>
          </span>
        </div>
        <a href="https://personaai.me/" dir="ltr" className="flex justify-center gap-1 pb-4 text-xs text-white/60">
          Powered by <span className="bg-gradient-to-r from-[#9333EA] to-[#EC4899] bg-clip-text font-semibold text-transparent">PersonaAI</span>
        </a>
      </div>
    </footer>
  );
}
