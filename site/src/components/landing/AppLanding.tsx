import Link from 'next/link';
import type { CSSProperties } from 'react';
import { tr, type Lang } from '@/lib/i18n';
import { LandingMenu } from './LandingMenu';

const A = '/web/app-landing';

/** A phone from the design: the app's screen under an iPhone frame, with the
 *  camera island on top. Every measure is a share of the frame's width
 *  (`--w`), as all the design's phones are one frame at different sizes. */
function Phone({ screen, frame, w, className = '', style }: {
  screen: string; frame: string; w: number; className?: string; style?: CSSProperties;
}) {
  return (
    // Placed by the caller (absolute) or in the flow (relative); never both,
    // or the later rule wins and the phone drops below its siblings.
    <div className={`${/\babsolute\b/.test(className) ? '' : 'relative '}${className}`} style={{ '--w': `${w}px`, width: 'var(--w)', ...style } as CSSProperties}>
      <img src={`${A}/${screen}.webp`} alt="" loading="lazy" className="absolute left-[4.617%] w-[90.644%] object-cover"
        style={{ top: 'calc(var(--w) * 0.0389)', height: 'calc(var(--w) * 1.966)', borderRadius: 'calc(var(--w) * 0.1337)' }} />
      <img src={`${A}/${frame}.png`} alt="" loading="lazy" className="relative block h-auto w-full" />
      <span className="absolute left-[35.36%] w-[28.92%] rounded-full bg-black"
        style={{ top: 'calc(var(--w) * 0.0656)', height: 'calc(var(--w) * 0.0838)' }}>
        <img src={`${A}/camera.png`} alt="" className="absolute rounded-full opacity-60"
          style={{ left: 'calc(var(--w) * 0.2248)', top: 'calc(var(--w) * 0.0207)', width: 'calc(var(--w) * 0.0413)', height: 'calc(var(--w) * 0.0413)' }} />
      </span>
    </div>
  );
}

/** The App Store and Google Play badges, linked where the panel holds the
 *  stores' addresses (store_url_ios / store_url_android). */
function Badges({ ios, android }: { ios: string | null; android: string | null }) {
  const badge = (href: string | null, src: string, alt: string) => {
    const img = <img src={`${A}/${src}`} alt={alt} width={179} height={56} className="block h-11 w-auto desk:h-14" />;
    return href ? <a href={href} target="_blank" rel="noopener">{img}</a> : <span>{img}</span>;
  };
  return (
    <div dir="ltr" className="flex flex-wrap gap-3 desk:gap-[18px]">
      {badge(ios, 'badge_app_store.svg', 'Download on the App Store')}
      {badge(android, 'badge_google_play.svg', 'Get it on Google Play')}
    </div>
  );
}

const title = 'font-bold text-[#202124] text-[28px] leading-[1.25] desk:text-[44px] desk:leading-[55px]';
const lead = 'text-base leading-6 text-[#5D5D5D] desk:text-lg';
const column = 'mx-auto w-full max-w-[1315px] px-4';

/** The app's landing page (Figma "App Landing Page", node 613:791): its own
 *  bar, the hero with both stores, three features, the city's services, the
 *  app's screens and the stores again. The site's footer follows, from the
 *  root layout. The design is drawn at 1920 wide; below 1100 the sections
 *  stack, as the rest of the site's phone layout does. */
export function AppLanding({ lang, ios, android }: { lang: Lang; ios: string | null; android: string | null }) {
  const t = tr(lang);
  const nav: [string, string][] = [
    [t('בית', 'Home'), '/'],
    [t('יכולות', 'Features'), '#features'],
    [t('צילומי מסך', 'Screenshots'), '#screenshots'],
    [t('צור קשר', 'Contact Us'), encodeURI('/יצירת-קשר/')],
  ];
  const cards = [
    {
      icon: 'icon_home', heading: t('גלו מה סביבכם', 'Discover What’s Around You'),
      text: t('מצאו עסקים מקומיים, מסעדות, אירועים ומקומות בכל רחבי מודיעין. גלו מה קרוב אליכם ומצאו משהו חדש.',
        'Find local businesses, restaurants, events, and places across Modiin. Explore what’s nearby and discover something new.'),
      phone: <Phone screen="screen_home" frame="frame_card_around" w={332} className="absolute start-[104px] top-[312px] -rotate-15" />,
    },
    {
      icon: 'icon_map', heading: t('מצאו את מה שאתם צריכים', 'Find What You Need'),
      text: t('מחפשים דירה, עבודה, מבצע טוב או שירות מקומי? ב-M4U קל למצוא את מה שאתם מחפשים.',
        'Looking for a home, a job, a great deal, or a local service? M4U makes it easy to find what you’re looking for.'),
      phone: <Phone screen="screen_map" frame="frame_card_find" w={332} className="absolute start-[35px] top-[273px]" />,
    },
    {
      icon: 'icon_note', heading: t('מחוברים למודיעין', 'Stay Connected to Modiin'),
      text: t('התעדכנו בחדשות המקומיות, בעדכוני העיר, באירועים ובשירותי העירייה החיוניים — הכול מאפליקציה אחת.',
        'Keep up with local news, city updates, events, and essential municipal services — all from one app.'),
      phone: <Phone screen="screen_news" frame="frame_card_news" w={332} className="absolute start-[-21px] top-[312px] rotate-15" />,
    },
  ];
  const services: [string, string, string][][] = [
    [
      ['icon_find', t('מצאו את מה שאתם צריכים', 'Find What You Need'),
        t('חפשו שירותים עירוניים והגיעו מהר למידע ולטפסים שאתם צריכים.', 'Search municipal services and quickly access the information and forms you need.')],
      ['icon_access', t('גישה קלה', 'Easy Access'),
        t('חפשו שירותים, עיינו במידע ומצאו טפסים חשובים בכמה הקשות.', 'Search services, explore information, and find important forms in just a few taps.')],
    ],
    [
      ['icon_services', t('גלו את שירותי העיר', 'Explore City Services'),
        t('חניה, בריאות, חינוך, תחבורה, פארקים, שירותי חירום ועוד.', 'Find parking, health, education, transportation, parks, emergency services, and more.')],
      ['icon_info', t('מידע מהיר', 'Quick Information'),
        t('מידע עירוני שימושי במבט אחד, בדיוק כשצריך אותו.', 'Get useful municipal information at a glance, right when you need it.')],
    ],
  ];
  // The strip of screens, drawn left to right in both languages, as designed.
  const strip = ['screen_municipal', 'screen_chat', 'screen_jobs', 'screen_realestate', null, 'screen_news', 'screen_deal', 'screen_events', 'screen_municipal'];

  return (
    <div className="relative overflow-x-clip">

      <header className={`${column} relative flex h-[72px] items-center justify-between gap-3 pt-4 desk:h-[84px] desk:pt-7`}>
        <Link href="/" aria-label="מודיעין בשבילך" className="shrink-0">
          <img src={`${A}/logo.svg`} alt="" width={106} height={56} className="h-10 w-auto desk:h-14" />
        </Link>
        <nav className="hidden items-center gap-2 desk:flex" aria-label={t('ראשי', 'Main')}>
          {nav.map(([label, href]) => (
            <a key={href} href={href} className="p-4 text-[15px] font-medium text-[#3D3D3D] hover:text-midblue">{label}</a>
          ))}
        </nav>
        <div className="flex items-center gap-1">
          <a href="#download" className="flex h-10 items-center rounded-full bg-midblue px-5 text-sm font-medium uppercase text-white hover:bg-midblue/90 desk:h-[46px] desk:px-6 desk:text-base">
            {t('הורידו את האפליקציה', 'Download App')}
          </a>
          <LandingMenu links={nav} label={t('תפריט', 'Menu')} />
        </div>
      </header>

      {/* Hero */}
      <section className={`${column} flex flex-col gap-6 pt-10 desk:flex-row desk:items-start desk:justify-between desk:pt-[95px]`}>
        <div className="max-w-[528px] desk:mt-[78px]">
          <h1 className="text-[36px] font-bold leading-[1.25] text-black desk:text-[56px] desk:leading-[1.4]">
            {t('כל מודיעין, במקום אחד.', 'Everything Modiin, in One Place.')}
          </h1>
          <p className={`mt-4 max-w-[509px] desk:mt-7 ${lead}`}>
            {t('עסקים מקומיים, מסעדות, אירועים, חדשות, דירות, משרות, מבצעים ושירותי העירייה — הכול באפליקציה אחת, שנבנתה בשביל מודיעין.',
              'Discover local businesses, restaurants, events, news, homes, jobs, deals, and city services — all in one app, made for Modiin.')}
          </p>
          <div className="mt-8 desk:mt-[51px]"><Badges ios={ios} android={android} /></div>
        </div>
        <div className="relative h-[340px] w-full desk:h-[554px] desk:w-[580px] desk:shrink-0">
          <div className="absolute left-1/2 top-0 h-[554px] w-[580px] origin-top -translate-x-1/2 scale-[.6] desk:scale-100">
            <img src={`${A}/glow_hero.svg`} alt="" aria-hidden className="pointer-events-none absolute left-[-91px] top-[-130px] w-[783px] max-w-none" />
            <Phone screen="screen_business" frame="frame_hero_right" w={249} className="absolute left-[268px] top-[24px] rotate-15" />
            <Phone screen="screen_home" frame="frame_hero_left" w={249} className="absolute left-[61px] top-[24px] -rotate-15" />
          </div>
        </div>
      </section>

      {/* Discover More */}
      <section id="features" className={`${column} scroll-mt-6 pt-16 text-center desk:pt-[125px]`}>
        <h2 className={title}>{t('לגלות יותר. לעשות יותר. לחיות את מודיעין.', 'Discover More. Do More. Live Modiin.')}</h2>
        <p className={`mx-auto mt-4 max-w-[608px] desk:mt-6 ${lead}`}>
          {t('כל מה שצריך כדי לגלות, לחקור ולהתחבר לעיר — במקום אחד.', 'Everything you need to discover, explore, and connect with your city — all in one place.')}
        </p>
        <div className="relative mt-10 grid gap-6 text-start desk:mt-12 desk:grid-cols-3">
          {/* The design's soft glows hang off the content, not the window:
              this one centred 40 px outside the cards' left edge, behind them. */}
          <img src={`${A}/glow_left.svg`} alt="" aria-hidden className="pointer-events-none absolute left-[-496px] top-[-14px] -z-10 hidden w-[888px] max-w-none desk:block" />
          {cards.map((c) => (
            <div key={c.icon} className="relative h-[480px] overflow-hidden rounded-3xl bg-[#F6F6F6] p-8 desk:h-[604px] desk:p-10">
              <span className="flex size-14 items-center justify-center rounded-full bg-midblue">
                <img src={`${A}/${c.icon}.svg`} alt="" width={24} height={24} />
              </span>
              <h3 className="mt-4 text-[22px] font-bold leading-[30px] text-[#202124] desk:whitespace-nowrap desk:text-2xl">{c.heading}</h3>
              <p className="mt-4 max-w-[324px] text-base leading-[1.6] text-[#4F4F4F]">{c.text}</p>
              {c.phone}
            </div>
          ))}
        </div>
      </section>

      {/* City services */}
      <section className={`${column} pt-20 text-center desk:pt-[120px]`}>
        <h2 className={title}>{t('שירותי העיר, הכול במקום אחד', 'Your City Services, All in One Place')}</h2>
        <p className={`mx-auto mt-4 max-w-[700px] desk:mt-[26px] ${lead} desk:text-[#606261]`}>
          {t('מידע, שירותים ועדכונים עירוניים חיוניים, בכל פעם שצריך — ישר מהטלפון.',
            'Access essential municipal information, services, and updates whenever you need them — right from your phone.')}
        </p>
        <div className="relative mt-[120px] rounded-3xl bg-midblue px-6 pb-10 desk:mt-[138px] desk:h-[673px] desk:p-0">
          {/* …and this one 42 px outside the block's right edge, behind it. */}
          <img src={`${A}/glow_right.svg`} alt="" aria-hidden className="pointer-events-none absolute right-[-498px] top-[2px] -z-10 hidden w-[888px] max-w-none -scale-x-100 desk:block" />
          <img src={`${A}/deco_sparkle.svg`} alt="" aria-hidden width={34} height={45} className="absolute start-8 top-[-16px] desk:start-[128px]" />
          <img src={`${A}/deco_hearts.svg`} alt="" aria-hidden width={77} height={84} className="absolute bottom-4 end-6 hidden desk:block desk:bottom-auto desk:end-auto desk:start-[1065px] desk:top-[573px]" />
          <div className="flex flex-col items-center gap-10 desk:absolute desk:left-1/2 desk:top-[-83px] desk:-translate-x-1/2 desk:flex-row desk:items-start desk:gap-[31px]">
            <Phone screen="screen_municipal" frame="frame_card_find" w={332} className="-mt-[83px] scale-90 desk:order-2 desk:mt-0 desk:scale-100" />
            {services.map((side, s) => (
              <div key={s} className={`flex w-full flex-col gap-10 text-start desk:w-[394.5px] desk:gap-14 desk:px-[12.8px] desk:pt-[133px] ${s === 0 ? 'desk:order-1 desk:items-end desk:text-end' : 'desk:order-3'}`}>
                {side.map(([icon, heading, text]) => (
                  <div key={icon} className={`flex flex-col ${s === 0 ? 'desk:items-end' : ''}`}>
                    <span className="flex size-14 items-center justify-center rounded-[5px] bg-white">
                      <img src={`${A}/${icon}.svg`} alt="" width={32} height={32} />
                    </span>
                    <h3 className="pt-4 text-2xl font-bold leading-[30px] text-white">{heading}</h3>
                    <p className="max-w-[369px] pt-4 text-base leading-6 text-[#C4C5C7] desk:min-h-[88px]">{text}</p>
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* The app's screens */}
      <section id="screenshots" className="scroll-mt-6 pt-20 text-center desk:pt-[120px]">
        <h2 className={`${column} ${title}`}>{t('גלו את חוויית M4U', 'Discover the M4U Experience')}</h2>
        <div dir="ltr" className="mt-10 snap-x snap-mandatory overflow-x-auto [scrollbar-width:none] desk:mt-[63px] desk:snap-none desk:overflow-hidden">
          <div className="flex w-max items-center gap-[26px] px-4 desk:relative desk:left-1/2 desk:-translate-x-1/2 desk:px-0">
            {/* On a phone the strip starts with the main phone, swipes a screen
                at a time, and leaves out the repeats that only fill the
                desktop's edges. */}
            {strip.map((s, i) => s ? (
              <img key={i} src={`${A}/${s}.webp`} alt="" loading="lazy" width={232} height={504}
                className={`h-[504px] w-[232px] snap-center rounded-2xl border border-line object-cover shadow-[0_0_16px_rgba(0,0,0,0.05)] ${i === 0 || i === strip.length - 1 ? 'hidden desk:block' : ''}`} />
            ) : (
              <Phone key={i} screen="screen_home_full" frame="frame_strip_center" w={295} className="order-first snap-center desk:order-none" />
            ))}
          </div>
        </div>
      </section>

      {/* Download */}
      <section id="download" className={`${column} scroll-mt-6 pb-16 pt-20 desk:pb-[88px] desk:pt-[133px]`}>
        <div className="flex flex-col items-center gap-6 overflow-hidden rounded-2xl bg-[#F6F6F6] px-6 pt-8 desk:h-[352px] desk:flex-row desk:justify-between desk:px-10 desk:pt-0">
          <div className="flex w-full flex-col gap-8 desk:w-[468px] desk:gap-[51px] desk:py-10">
            <h2 className={title}>{t('בכל מקום, בכל זמן, בכל פלטפורמה', 'Anywhere, Any Time, Any Platform')}</h2>
            <Badges ios={ios} android={android} />
          </div>
          <div className="relative h-[280px] w-[249px] shrink-0 overflow-hidden desk:h-[352px]">
            <Phone screen="screen_home" frame="frame_hero_left" w={249} className="absolute left-0 top-[33px]" />
          </div>
        </div>
      </section>
    </div>
  );
}
