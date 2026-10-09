import Link from 'next/link';
import { tr, type Lang } from '@/lib/i18n';
import { getMenus } from '@/lib/menu';
import type { HomeNotice } from '@/lib/data/home';
import { MobileMenu } from '@/components/chrome/MobileMenu';
import { HeroSearch, PhoneSearch } from './SearchForms';
import { NoticeBar } from './NoticeBar';
import { navItems } from '@/components/chrome/nav-items';
import { israelHour } from './format';

/** Where the 1920 frame places each drawing along the foot of the hero:
 *  [name, x, top, width, height]. */
const ART: [string, number, number, number, number][] = [
  ['palm', 193, 450, 282, 250],
  ['reeds', 786, 572, 348, 121],
  ['stadium', 1304, 562, 293, 140],
  ['cloud', 1534, 498, 48, 27],
  ['torch', 1629, 469, 98, 232],
];

/** The top of the home page, both layouts in one block so the page has one
 *  heading. Desktop (web_home_screen.dart, _buildHeroWithNotice): 700 of
 *  blue with the city drawn along its foot, the headline, the search bar,
 *  the quick chips, and the site notice across its lower edge. Phone
 *  (home_screen.dart, _buildHeader): the greeting, the search bar that asks
 *  the chat, the ☰ — then the notice under it.
 *
 *  The H1 is WordPress's for the address, set small over the headline:
 *  Google has always read it there, and the design's own headline stays as
 *  drawn. `underBar`: the page sits under the white bar rather than the
 *  floating pill (an old address that shows the home page). */
export async function Hero({ h1, lang, notice, underBar = false }: { h1: string; lang: Lang; notice: HomeNotice | null; underBar?: boolean }) {
  const t = tr(lang);
  const hour = israelHour();
  const greeting = hour < 12 ? t('בוקר טוב', 'Good morning') : hour < 17 ? t('צהריים טובים', 'Good afternoon') : t('ערב טוב', 'Good evening');
  const chips: [string, string, string][] = [
    [t('עסקים', 'Businesses'), 'businesses', '/business/'],
    [t('חדשות', 'News'), 'news', '/news/'],
    [t('מפה', 'Map'), 'map', '/map/'],
    [t('נדל״ן', 'Real Estate'), 'realestate', '/search-apartments/'],
    [t('בעלי מקצוע', 'Professionals'), 'professionals', '/professionals/'],
    [t('מבצעים', 'Deals'), 'deals', '/deals/'],
  ];
  const menus = underBar ? null : await getMenus(lang);

  return (
    // The block is as tall with or without a notice, so what follows sits
    // where the design puts it either way.
    <div className={`relative ${underBar ? 'desk:h-[699px]' : 'desk:h-[779px]'}`}>
      <section className={`relative overflow-hidden bg-[linear-gradient(180deg,#010A36,#0058B5)] desk:bg-[linear-gradient(182deg,#010A36_9.1%,#0058B5_100%)] ${underBar ? 'desk:h-[620px]' : 'desk:h-[700px]'}`}>
        {/* The palms, the reeds, the stadium and the torch at half strength,
            where the 1920 frame puts them across whatever width the window
            has. A drawing of the city, so it does not mirror. */}
        <div aria-hidden className="pointer-events-none absolute inset-0 hidden desk:block" dir="ltr">
          {ART.map(([name, x, top, w, h]) => (
            <img key={name} src={`/web/home/hero_${name}.png`} alt="" width={w} height={h}
              className="absolute max-w-none opacity-50" style={{ left: `${(x / 1920) * 100}%`, top: top - (underBar ? 80 : 0), width: w, height: h }} />
          ))}
        </div>
        {/* The phone's palm and cloud, 114 square, cut from the same drawing. */}
        <div aria-hidden className="pointer-events-none absolute end-[37px] top-7 size-[114px] overflow-hidden opacity-50 desk:hidden">
          <img src="/web/home/hero_palm.png" alt="" className="absolute left-0 top-0 h-[122.1px] w-[128.8px] max-w-none" />
        </div>
        {menus && (
          <div className="absolute end-[7px] top-0 z-10 desk:hidden [&>button]:text-white">
            <MobileMenu lang={lang} menus={menus} items={navItems(lang)} />
          </div>
        )}

        <div className={`relative px-0 pb-[21px] pt-3 desk:pb-0 desk:text-center ${underBar ? 'desk:pt-[70px]' : 'desk:pt-[150px]'}`}>
          <h1 className="mx-4 pe-12 text-xs font-medium leading-4 text-white/75 desk:mx-auto desk:mb-4 desk:px-6 desk:text-base desk:leading-6">{h1}</h1>

          {/* Phone: the greeting. */}
          <div className="mt-2 ps-4 pe-14 desk:hidden">
            <p className="font-nunito text-2xl font-semibold leading-[1.25] text-white">{greeting}</p>
            <p className="mt-1.5 text-sm leading-[1.21] text-white">{t('מה אתה מחפש היום?', 'What are you looking for today?')}</p>
          </div>
          <div className="mt-[22px] desk:hidden">
            <PhoneSearch placeholder={t('שאל או חפש במודיעין...', 'Ask or search in Modiin…')} ask={t('שאל', 'Ask')}
              searchLabel={t('חיפוש', 'Search')} closeLabel={t('סגירה', 'Close')} />
          </div>

          {/* Desktop: the headline, the line under it, the bar, the chips. */}
          <div className="hidden desk:block">
            <p className="mx-auto max-w-[743px] px-6 font-nunito text-5xl font-semibold leading-[1.22] text-white">
              {t('כל מה שמודיעין מציעה, הכל במקום אחד', 'Everything Modiin Has to Offer, All in One Place')}
            </p>
            <p className="mt-[15px] px-6 text-base leading-[1.21] text-white">
              {t('עסקים, חדשות, אירועים, נדל״ן ועוד — הכל בפלטפורמה עירונית חכמה אחת.', 'Businesses, news, events, real estate and more — all in one smart city platform.')}
            </p>
            <div className="mt-[38px]">
              <HeroSearch placeholder={t('מה אתה מחפש?', 'What are you looking for?')} ask={t('שאל', 'Ask')} />
            </div>
            <ul className="mx-auto mt-8 flex max-w-[1000px] flex-wrap justify-center gap-2 px-6">
              {chips.map(([label, icon, to]) => (
                <li key={icon}>
                  <Link href={to} className="flex items-center gap-2 rounded-lg border border-white/30 px-3 py-2.5 text-xs leading-[1.21] text-white hover:bg-white/10">
                    <img src={`/web/home/pill_${icon}.svg`} alt="" width={14} height={14} className="size-3.5" />
                    {label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {notice && (
        <>
          <div className={`absolute inset-x-6 z-10 hidden justify-center desk:flex ${underBar ? 'top-[597px]' : 'top-[677px]'}`}>
            <NoticeBar notice={notice} variant="desk" details={t('לפרטים', 'View details')} close={t('סגירה', 'Close')} />
          </div>
          <div className="desk:hidden">
            <NoticeBar notice={notice} variant="phone" details={t('לפרטים', 'View details')} close={t('סגירה', 'Close')} />
          </div>
        </>
      )}
    </div>
  );
}
