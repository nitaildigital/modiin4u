import Link from 'next/link';
import { tr, type Lang } from '@/lib/i18n';
import { href } from '@/lib/seo';
import { CONTACT } from '@/lib/config';
import { banners, type Banner } from '@/lib/data/banners';
import {
  activeBusinesses, activeListings, bizName, catName, homeArticles, primaryCategories, professionals,
  publishedEvents, recommendedBusinesses, shekels,
} from '@/lib/data/home';
import { BusinessCard } from './Cards';
import { MapTeaser, type Layer } from './MapTeaser';
import { ProfessionalsRow, type Pro } from './ProfessionalsRow';
import { cardOf, newsDateLine } from './format';

/** A section's title in Mid blue, its line of copy under it, and anything
 *  that belongs at the far end of the heading. */
function Heading({ title, subtitle, action }: { title: string; subtitle: string; action?: React.ReactNode }) {
  return (
    <div className="flex items-center gap-6">
      <div className="min-w-0 flex-1">
        <h2 className="font-nunito text-[28px] font-semibold leading-[1.22] text-midblue">{title}</h2>
        <p className="mt-2.5 text-sm leading-[1.21] text-gray-text">{subtitle}</p>
      </div>
      {action}
    </div>
  );
}

/** "View all ›" filled Mid blue, 36 high. */
function ViewAll({ to, label, lang }: { to: string; label: string; lang: Lang }) {
  return (
    <Link href={to} className="flex shrink-0 items-center gap-1 rounded-[60px] bg-midblue px-4 py-1.5 text-sm font-medium leading-6 text-white hover:bg-midblue/90">
      {label}
      <img src="/web/home/chevron_right_white.svg" alt="" width={16} height={16} className={`size-4 ${lang === 'he' ? '-scale-x-100' : ''}`} />
    </Link>
  );
}

/** A booked banner at the size its slot is drawn; a tap follows its link. */
function Slot({ b, w, h, bordered = false }: { b: Banner; w: number; h: number; bordered?: boolean }) {
  const img = (
    <span className="relative block" style={{ width: w, height: h, maxWidth: '100%' }}>
      <img src={b.image_url} alt={b.name} loading="lazy" className="size-full object-cover" />
      {bordered && <span className="absolute inset-0 border border-line" />}
    </span>
  );
  return b.destination_url ? <a href={b.destination_url} target="_blank" rel="noopener sponsored" className="block">{img}</a> : img;
}

/** The home page's desktop layout below the hero (web_home_screen.dart):
 *  the eight category cards, the top banner, the news, the map with its
 *  banners, the recommended businesses, the community banner, TikTok, and
 *  the professionals. Every row from the database or not at all. */
export async function DesktopHome({ lang }: { lang: Lang }) {
  const t = tr(lang);
  const [top, side, articles, kinds, picks, all, events, listings, pros] = await Promise.all([
    banners('HOME_TOP'), banners('HOME_MAP_SIDE'), homeArticles(7), primaryCategories(), recommendedBusinesses(12),
    activeBusinesses(), publishedEvents(), activeListings(), professionals(),
  ]);

  const cards: [string, string, string, string][] = [
    [t('חדשות', 'News'), 'news', t('מה קורה במודיעין', 'What’s happening in Modiin'), '/news/'],
    [t('אירועים', 'Events'), 'events', t('מה יש במודיעין', 'What’s on in Modiin'), '/events/'],
    [t('קהילה', 'Community'), 'community', t('קבוצות ויוזמות', 'Groups & Initiatives'), '/community/'],
    [t('בעלי מקצוע', 'Professionals'), 'professionals', t('מומחים ושירותים', 'Experts & Services'), '/professionals/'],
    [t('מפות', 'Maps'), 'maps', t('גלו את מודיעין', 'Explore Modiin'), '/map/'],
    [t('עסקים', 'Businesses'), 'businesses', t('כל העסקים במודיעין', 'All Businesses in Modiin'), '/businesses/'],
    [t('נדל״ן', 'Real Estate'), 'realestate', t('דירות ופרויקטים', 'Apartments & Projects'), '/realestate/'],
    [t('עירייה', 'Municipal'), 'municipal', t('שירותי עירייה ושבת', 'City services & Shabbat'), '/municipal/'],
  ];

  const lead = articles.slice(0, 3);
  const rest = articles.slice(3);

  // The map's pins: the businesses, events and listings that carry
  // coordinates (mapPoisProvider), each opening its own page.
  const pin = (layer: string) => ({ icon: `/web/home/map_pin_${layer}.svg`, size: [40, 43.24] as [number, number] });
  const layers: Layer[] = [
    {
      id: 'businesses', label: t('עסקים', 'Businesses'),
      pins: all.filter((b) => b.latitude && b.longitude).map((b) => ({
        id: 'b' + b.id, lat: b.latitude!, lng: b.longitude!, href: href(`/business/${b.slug || b.id}/`), label: bizName(b, lang), ...pin('businesses'),
      })),
    },
    {
      id: 'events', label: t('אירועים', 'Events'),
      pins: events.filter((e) => e.latitude && e.longitude).map((e) => ({
        id: 'e' + e.id, lat: e.latitude!, lng: e.longitude!, href: href(`/event/${e.id}/`), label: e.title, ...pin('events'),
      })),
    },
    {
      id: 'realestate', label: t('נדל״ן', 'Real Estate'),
      pins: listings.filter((l) => l.latitude && l.longitude).map((l) => {
        const price = l.kind === 'rent' ? l.price_per_month : l.price;
        return { id: 'l' + l.id, lat: l.latitude!, lng: l.longitude!, href: href(`/listing/${l.id}/`), label: price != null ? shekels(price) : l.title, ...pin('realestate') };
      }),
    },
  ];

  const pickCards = picks.map((b) => cardOf(b, kinds.get(b.id), lang));
  const shown = pickCards.slice(0, 8);
  const faded = pickCards.slice(8, 12);

  // The first six of everybody and of each trade (the row shows six).
  const firstSix = new Set<string>(pros.people.slice(0, 6).map((b) => b.id));
  for (const trade of pros.trades) pros.people.filter((b) => trade.ids.has(b.id)).slice(0, 6).forEach((b) => firstSix.add(b.id));
  const people: Pro[] = pros.people.filter((b) => firstSix.has(b.id)).map((b) => {
    const trades = pros.trades.filter((x) => x.ids.has(b.id));
    return {
      card: cardOf(b, kinds.get(b.id), lang),
      trade: trades[0] ? catName(trades[0].category, lang) : (b.short_description ?? b.full_description ?? '').trim(),
      tradeIds: trades.map((x) => x.category.id),
    };
  });

  return (
    <div className="hidden desk:block">
      {/* The category cards: eight across the column, four on a narrower one. */}
      <div className="wrap">
        <ul className="grid grid-cols-4 gap-4 min-[1320px]:grid-cols-8">
          {cards.map(([title, icon, sub, to]) => (
            <li key={icon}>
              <Link href={to} className="flex h-full flex-col items-center rounded-xl border border-line bg-white px-4 py-5 text-center transition-transform hover:scale-[1.008]">
                <img src={`/web/home/card_${icon}.svg`} alt="" width={32} height={32} className="size-8" />
                <span className="mt-[19px] text-base font-medium leading-[1.21] text-black">{title}</span>
                {/* One line, as drawn: a line too long for the card gives
                    way by shrinking (FittedBox), measured against the card. */}
                <span className="mt-2 block w-full [container-type:inline-size]">
                  <span className="block whitespace-nowrap leading-[1.21] text-[#6D6D6D]" style={{ fontSize: `min(14px, calc(100cqw / ${(sub.length * 0.53).toFixed(2)}))` }}>{sub}</span>
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </div>

      {/* The 728 × 90 banner between the cards and the news, when one is booked. */}
      {top[0] ? <div className="flex justify-center pb-16 pt-14"><Slot b={top[0]} w={728} h={90} bordered /></div> : <div className="h-16" />}

      {articles.length > 0 && (
        <section className="wrap">
          <Heading title={t('חדשות מודיעין', 'Modiin News')}
            subtitle={t('קבלו את החדשות, הסיפורים והעדכונים החשובים ברחבי העיר.', 'Get the latest news, stories and important updates happening across the city.')}
            action={<ViewAll to="/news/" label={t('הצג הכל', 'View all')} lang={lang} />} />
          <div className="mt-6 flex items-start gap-[26px]">
            <ul className="flex min-w-0 flex-[812] flex-col gap-5">
              {lead.map((a) => (
                <li key={a.id}>
                  <Link href={href(`/news/${a.slug}/`)} className="flex items-start gap-[21px] rounded-xl border border-line bg-white p-5 transition-transform hover:scale-[1.008]">
                    <span className="min-w-0 flex-1" dir="rtl">
                      <span className="line-clamp-2 text-right font-nunito text-[22px] font-semibold leading-[1.24] text-black">{a.title}</span>
                      {a.excerpt && <span className="mt-3 line-clamp-2 text-right text-sm leading-[1.4] text-gray-text">{a.excerpt}</span>}
                      <DateRow iso={a.published_at} lang={lang} />
                    </span>
                    <Thumb src={a.image} className="h-[181px] w-[286px]" />
                  </Link>
                </li>
              ))}
            </ul>
            {rest.length > 0 && (
              <ul className="min-w-0 flex-[762] rounded-xl border border-line bg-white px-5 pb-[15px] pt-1">
                {rest.map((a) => (
                  <li key={a.id} className="border-b border-line">
                    <Link href={href(`/news/${a.slug}/`)} className="flex items-center gap-[21px] py-5 transition-transform hover:scale-[1.008]">
                      <span className="min-w-0 flex-1" dir="rtl">
                        <span className="line-clamp-2 text-right font-nunito text-[22px] font-semibold leading-[1.24] text-black">{a.title}</span>
                        {a.excerpt && <span className="mt-3 line-clamp-1 text-right text-sm leading-[1.4] text-gray-text">{a.excerpt}</span>}
                        <DateRow iso={a.published_at} lang={lang} />
                      </span>
                      <Thumb src={a.image} className="h-[131px] w-[207px]" />
                    </Link>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </section>
      )}

      {/* The map, and the banners booked beside it: one wide over two squares. */}
      <section className="wrap mt-20 flex items-start gap-6">
        <div className="min-w-0 flex-1">
          <MapTeaser title={t('גלו את מודיעין', 'Explore Modiin')}
            subtitle={t('גלו עסקים, אירועים ומקומות ברחבי העיר.', 'Discover businesses, events and places around the city.')}
            layers={layers} openLabel={t('פתח מפה', 'Open Map')} lang={lang} />
        </div>
        {side.length > 0 && (
          <div className="w-[460px] shrink-0">
            <Slot b={side[0]} w={460} h={281} />
            {side.length > 1 && (
              <div className="mt-[17px] flex gap-5">
                <Slot b={side[1]} w={220} h={220} />
                {side[2] && <Slot b={side[2]} w={220} h={220} />}
              </div>
            )}
          </div>
        )}
      </section>

      {/* "AI Picks · Recommended for You": two rows, a third fading out under View all. */}
      {pickCards.length > 0 && (
        <section className="wrap mt-20">
          <span className="mb-4 inline-flex h-9 items-center gap-2 rounded-lg bg-turquoise/10 px-3 text-sm font-medium leading-[1.21] text-midblue">
            <span className="flex size-5 items-center justify-center"><img src="/web/home/ai_small.svg" alt="" width={14.55} height={17.5} /></span>
            {t('בחירות AI', 'AI Picks')}
          </span>
          <Heading title={t('מומלצים בשבילך', 'Recommended for You')}
            subtitle={t('גלו מקומות, שירותים ופעילויות לפי מה שחשוב לכם.', 'Discover places, services and activities based on what matters to you.')} />
          <div className="mt-8 grid grid-cols-2 gap-x-6 gap-y-8 min-[1320px]:grid-cols-4">
            {shown.map((b) => <BusinessCard key={b.id} b={b} lang={lang} />)}
          </div>
          <div className="relative mt-8 h-[133px] overflow-hidden">
            {faded.length > 0 && (
              <div aria-hidden className="pointer-events-none grid grid-cols-2 gap-x-6 min-[1320px]:grid-cols-4 [&>*:nth-child(n+3)]:hidden min-[1320px]:[&>*:nth-child(n+3)]:flex" inert>
                {faded.map((b) => <BusinessCard key={b.id} b={b} lang={lang} />)}
              </div>
            )}
            {/* The fade is drawn 200 tall and cut at 133: white from a little past halfway. */}
            <div className="pointer-events-none absolute inset-x-0 top-0 h-[200px] bg-[linear-gradient(180deg,rgba(255,255,255,.8)_1.8%,#fff_53%,#fff)]" />
            <div className="absolute inset-x-0 top-[29px] flex justify-center">
              <Link href="/businesses/" className="flex h-[46px] items-center gap-1 rounded-[60px] border border-midblue bg-white px-8 text-base font-medium leading-6 text-midblue hover:bg-midblue/5">
                {t('הצג הכל', 'View all')}
                <img src="/web/home/chevron_right_blue20.svg" alt="" width={20} height={20} className={`size-5 ${lang === 'he' ? '-scale-x-100' : ''}`} />
              </Link>
            </div>
          </div>
        </section>
      )}

      {/* The design's banner into the city's community. */}
      <div className="mx-auto mt-[67px] max-w-[1072px] px-6">
        <Link href="/community/" className="block aspect-[1024/222] overflow-hidden bg-[#4A91B5]">
          <img src="/web/home/join_community.webp" alt={t('הצטרפו לקהילת העיר מודיעין', 'Join the Modiin city community')} loading="lazy" className="size-full object-cover" />
        </Link>
      </div>

      {/* "Modiin on TikTok LIVE": the design's strip, opening the city's TikTok. */}
      <section className="wrap mt-20">
        <Heading title={t('מודיעין בטיקטוק LIVE', 'Modiin on TikTok LIVE')}
          subtitle={t('ראו מה קורה ברחבי העיר, ישירות מהקהילה המקומית.', 'See what’s happening around the city, straight from the local community.')} />
        <a href={CONTACT.tiktok} target="_blank" rel="noopener" className="mt-[38.5px] block aspect-[1600/514] overflow-hidden" aria-label={t('מודיעין בטיקטוק', 'Modiin on TikTok')}>
          <img src="/web/home/tiktok_live.webp" alt="" loading="lazy" className="size-full object-cover" />
        </a>
      </section>

      {/* The professionals: whoever is filed under Services, the trades as pills. */}
      {people.length > 0 && (
        <section className="wrap mt-20">
          <ProfessionalsRow lang={lang} allLabel={t('הכל', 'All')} people={people}
            trades={pros.trades.map((x) => ({ id: x.category.id, name: catName(x.category, lang) }))}
            heading={<Heading title={t('מצאו בעל מקצוע במודיעין', 'Find a Professional in Modiin')}
              subtitle={t('התחברו עם בעלי מקצוע מקומיים לבית, לעסק ולצרכים היומיומיים.', 'Connect with trusted local professionals for your home, business and everyday needs.')} />} />
        </section>
      )}
      <div className="h-32" />
    </div>
  );
}

function DateRow({ iso, lang }: { iso: string | null; lang: Lang }) {
  if (!iso) return null;
  return (
    <span className="mt-3.5 flex items-center gap-[9px] text-sm leading-[1.21] text-gray-text" dir={lang === 'he' ? 'rtl' : 'ltr'}>
      <img src="/web/home/date.svg" alt="" width={16} height={16} className="size-4" />
      <time dateTime={iso}>{newsDateLine(iso, lang)}</time>
    </span>
  );
}

function Thumb({ src, className }: { src: string | null; className: string }) {
  return src
    ? <img src={src} alt="" loading="lazy" className={`shrink-0 rounded-xl object-cover ${className}`} />
    : <span className={`shrink-0 rounded-xl bg-[linear-gradient(135deg,#E0E8F0,#C8D4E0)] ${className}`} />;
}
