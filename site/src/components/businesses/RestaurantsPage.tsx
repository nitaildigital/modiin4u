import Link from 'next/link';
import { ArrowLeft, ArrowRight, Location, Map as MapIcon, SearchNormal1, Setting4, ShieldTick, Verify } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { breadcrumb, h1For, href, SITE_NAME } from '@/lib/seo';
import { categoryPath } from '@/lib/routes';
import { SITE_URL } from '@/lib/config';
import {
  activeBusinesses, bizName, bizNeighborhood, bizPhoto, businessCategories, businessesInCategory, catName,
  categoryCounts, foodPlaces, kosherLabel, primaryCategories, ratedFirst, sizedPhoto, bizDescription,
  type BizCategory, type BizRow, type FoodPlace,
} from '@/lib/data/businesses';
import { banners } from '@/lib/data/banners';
import { JsonLd } from '@/components/JsonLd';
import { BannerImage } from '@/components/ui/Banner';
import { RestaurantCard, type FoodCard } from './RestaurantCard';
import { RotatingRow } from './RotatingRow';
import { Rating } from './BusinessCard';
import { Photo } from './Photo';

const catHref = (slug: string) => href(categoryPath(slug));

/** The Restaurants page (WordPress's /search-rest-modiin/):
 *  web_restaurants_screen.dart at desktop width — the photograph with the
 *  title, search and quick picks, the paid banners, the food categories, and
 *  rows of restaurants, cafés, bars, the best loved and those that deliver —
 *  and restaurants_screen.dart on a phone. Every "View all" opens the
 *  category's page (a list Google can read); the search opens the
 *  restaurants list, narrowed; "View on Map" opens /restaurants-map/.
 *
 *  Left out: the Takeaway pick, which no row answers (`has_takeaway` is
 *  false on all of them). */
export async function RestaurantsPage({ path }: { path: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const [places, phonePlaces, cats, counts, primary, all, top] = await Promise.all([
    foodPlaces(true), foodPlaces(false), businessCategories(), categoryCounts(), primaryCategories(), activeBusinesses(),
    banners('RESTAURANTS_TOP'),
  ]);
  const title = h1For(path, t('מסעדות במודיעין', 'Restaurants in Modiin'));
  const bySlug = new Map(cats.map((c) => [c.slug, c]));
  const restaurants = bySlug.get('restaurants');

  // ── desktop ──
  const food = cats.filter((c) => c.slug === 'cafe-bakery' || c.slug === 'restaurants' || (!!restaurants && c.parent_id === restaurants.id));
  const inside = new Map(food.map((c) => [c.slug, places.filter((p) => p.slugs.has(c.slug))]));
  food.sort((a, b) => inside.get(b.slug)!.length - inside.get(a.slug)!.length);
  // The category's own picture, else a photograph from a place inside it —
  // each photograph on one tile only.
  const used = new Set<string>();
  const firstUnused = (ps: FoodPlace[]) => {
    const photos = ps.map((p) => bizPhoto(p.business)).filter((u): u is string => !!u);
    const pick = photos.find((u) => !used.has(u)) ?? photos[0] ?? null;
    if (pick) used.add(pick);
    return pick;
  };
  const tiles = food.map((c) => ({ c, count: inside.get(c.slug)!.length, image: c.image_url || firstUnused(inside.get(c.slug)!) }));

  const kindLabel = (k: FoodPlace['kind']) => k === 'cafe' ? t('בית קפה', 'Cafe') : k === 'bar' ? t('בר', 'Bar') : t('מסעדה', 'Restaurant');
  const card = (p: FoodPlace, compact: boolean): FoodCard => {
    const b = p.business;
    const cuisine = p.cuisine ? catName(p.cuisine, lang) : null;
    return {
      id: b.id, href: href(`/business/${b.slug}/`), name: bizName(b, lang),
      type: compact && cuisine ? `${kindLabel(p.kind)} · ${cuisine}` : kindLabel(p.kind),
      address: b.address ?? '', photo: sizedPhoto(bizPhoto(b), 800),
      rating: Number(b.rating ?? 0), reviews: b.review_count ?? 0, kind: p.kind,
      pill: compact ? null : cuisine, kosher: !!kosherLabel(b.kosher_level), delivery: !!b.has_delivery,
      phone: (b.phone ?? '').trim() || null, whatsapp: b.whatsapp,
    };
  };
  const popular = ratedFirst(places.filter((p) => p.kind === 'restaurant'));
  const coffee = ratedFirst(places.filter((p) => p.kind === 'cafe'));
  // No bar category is read: these are the places whose own line opens with
  // "bar" or "pub".
  const bars = ratedFirst(places.filter((p) => p.kind === 'bar'));
  // "The places locals love most" can only be ones someone has rated.
  const loved = ratedFirst(places.filter((p) => Number(p.business.rating ?? 0) > 0));
  // "Lunch Nearby": no column holds a wait or a distance; what is recorded is
  // who delivers — less the restaurants the first row already shows.
  const shown = new Set(popular.slice(0, 4).map((p) => p.business.id));
  const lunch = ratedFirst(places.filter((p) => p.kind === 'restaurant' && p.business.has_delivery && !shown.has(p.business.id)));
  const barsCat = bySlug.get('ברים');

  const picks = [
    bySlug.has('restaurants') && { icon: 'chip_restaurants.svg', label: t('מסעדות', 'Restaurants'), to: catHref('restaurants') },
    bySlug.has('cafe-bakery') && { icon: 'chip_coffee.svg', label: t('בתי קפה', 'Coffee Shops'), to: catHref('cafe-bakery') },
    bars.length > 0 && barsCat && { icon: 'chip_bars.svg', label: t('ברים', 'Bars'), to: catHref(barsCat.slug) },
    bySlug.has('pizza') && { icon: 'chip_pizza.svg', label: t('פיצה', 'Pizza'), to: catHref('pizza') },
  ].filter(Boolean) as { icon: string; label: string; to: string }[];

  // ── phone ──
  const kinds = primary;
  const phoneKind = (b: BizRow) => (kinds.get(b.id) ? catName(kinds.get(b.id)!.category, lang) : bizDescription(b));
  const cuisines = restaurants ? cats.filter((c) => c.parent_id === restaurants.id) : [];
  const phoneUsed = new Set<string>();
  const cuisinePhoto = (c: BizCategory) => {
    if (c.image_url) return c.image_url;
    const photos = phonePlaces.filter((p) => p.slugs.has(c.slug)).map((p) => bizPhoto(p.business)).filter((u): u is string => !!u);
    const pick = photos.find((u) => !phoneUsed.has(u)) ?? photos[0] ?? null;
    if (pick) phoneUsed.add(pick);
    return pick;
  };
  const [phoneRestaurants, phoneCafes] = await Promise.all([
    restaurants ? businessesInCategory(restaurants.id) : Promise.resolve([]),
    bySlug.get('cafe-bakery') ? businessesInCategory(bySlug.get('cafe-bakery')!.id) : Promise.resolve([]),
  ]);
  const topRated = [...all].sort((a, b) => Number(b.rating ?? 0) - Number(a.rating ?? 0) || (b.review_count ?? 0) - (a.review_count ?? 0))
    .filter((b) => Number(b.rating ?? 0) > 0).slice(0, 8);

  const Back = lang === 'he' ? ArrowRight : ArrowLeft;
  return (
    <div className="pb-24 desk:pb-[216px]">
      <JsonLd data={[
        breadcrumb([[SITE_NAME, '/'], [title, path]]),
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: title,
          itemListElement: places.map((p, i) => ({ '@type': 'ListItem', position: i + 1, url: SITE_URL + href(`/business/${p.business.slug}/`), name: p.business.name })),
        },
      ]} />

      {/* The hero: on a phone the page's title bar and search. */}
      <section className="relative desk:h-[662px]">
        <div className="absolute inset-0 hidden bg-[linear-gradient(to_top,#BFE7F614,#C4C4C400)] desk:block" />
        <div className="absolute inset-0 hidden bg-[url(/web/common/dots_tile.png)] bg-[length:154px] bg-top opacity-20 desk:block" />
        <div className="relative mx-auto max-w-[430px] px-4 desk:top-12 desk:mx-6 desk:h-[551px] desk:max-w-none desk:overflow-hidden desk:rounded-3xl desk:px-0 min-[1248px]:mx-auto min-[1248px]:max-w-[1200px]">
          <img src="/web/restaurants/hero.webp" alt="" className="absolute inset-0 hidden size-full bg-[#858882] object-cover desk:block" />
          <div className="absolute inset-x-0 top-0 hidden h-[428px] bg-[linear-gradient(to_bottom,#80B2DF,#80B2DF00)] mix-blend-multiply desk:block" />
          <div className="relative flex h-10 items-center justify-center desk:block desk:h-auto desk:pt-[112px]">
            <Link href="/" aria-label={t('חזרה', 'Back')} className="absolute start-0 text-[#3D3D3D] desk:hidden"><Back size={24} color="currentColor" /></Link>
            <h1 className="text-base font-medium text-black desk:text-center desk:font-nunito desk:text-[44px] desk:font-semibold desk:leading-[54px] desk:text-white">{title}</h1>
          </div>
          <p className="relative mt-3.5 hidden text-center text-base leading-[19px] text-white desk:block">
            {t('גלו את המסעדות, בתי הקפה והברים הטובים במודיעין', 'Discover the best restaurants, cafe and bars in Modiin')}
          </p>
          {/* The search opens the restaurants list, narrowed to the words. */}
          <form action={catHref('restaurants')} method="get" role="search"
            className="relative mx-6 mt-12 hidden items-center gap-6 rounded-full bg-white p-4 shadow-[0_0_8px_rgba(0,0,0,0.25)] desk:flex min-[896px]:mx-auto min-[896px]:max-w-[848px]">
            <label className="min-w-0 flex-1 ps-2">
              <span className="block text-sm leading-[17px] text-[#3D3D3D]">{t('מה אתם מחפשים?', 'What are you looking for?')}</span>
              <input name="q" type="search" placeholder={t('מסעדות, מטבחים, מנה או שם...', 'Restaurants, cuisines, dish or name...')}
                className="mt-2 w-full bg-transparent text-base leading-[19px] text-black outline-none placeholder:text-gray-text" />
            </label>
            <button type="submit" className="flex h-[46px] items-center gap-2 rounded-full bg-midblue px-6 text-base font-medium text-white">
              <img src="/web/common/search_white.svg" alt="" className="size-[18px]" />{t('חיפוש', 'Search')}
            </button>
          </form>
          <div className="relative mt-[33px] hidden flex-wrap justify-center gap-2 desk:flex">
            {picks.map((p) => (
              <Link key={p.to} href={p.to} className="flex items-center gap-2 rounded-lg bg-white px-3 py-2.5 text-xs leading-[15px] text-midblue hover:bg-white/90">
                <img src={`/web/restaurants/${p.icon}`} alt="" className="size-3.5" />{p.label}
              </Link>
            ))}
            {/* Every place on the map, with the filters (/restaurants-map). */}
            <Link href="/restaurants-map/" className="flex items-center gap-2 rounded-lg bg-white px-3 py-2.5 text-xs leading-[15px] text-midblue hover:bg-white/90">
              <MapIcon size={14} color="currentColor" />{t('הצגה במפה', 'View on Map')}
            </Link>
          </div>
          <Link href={catHref('restaurants')} className="mt-1 flex h-12 items-center gap-2 rounded-full border border-line bg-white px-4 desk:hidden">
            <SearchNormal1 size={18} color="#6D6D6D" />
            <span className="flex-1 text-sm text-[#6D6D6D]">{t('חיפוש מסעדה, מטבח או מיקום', 'Search a restaurant, cuisine or place')}</span>
            <Setting4 size={20} color="#123A72" />
          </Link>
        </div>
      </section>

      {/* ── desktop ── */}
      <div className="wrap hidden desk:block">
        {top.length > 0 && (
          <div className="mt-14">
            <RotatingRow cols="[--cols:3]" gap={20} minForArrows={3} lang={lang}>
              {top.map((b) => <div key={b.id} className="aspect-[520/300] [&_img]:size-full [&_img]:rounded-xl"><BannerImage banner={b} className="h-full" /></div>)}
            </RotatingRow>
          </div>
        )}

        {tiles.length > 0 && (
          <section className="mt-16">
            <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{t('גלו קטגוריות', 'Explore Categories')}</h2>
            <p className="mt-2.5 text-sm text-gray-text">{t('גלו מסעדות לפי האוכל שאתם אוהבים.', 'Discover restaurants by the food you love.')}</p>
            <div className="mt-6">
              <RotatingRow cols="[--cols:5] min-[1540px]:[--cols:7]" gap={18} arrowTop="110px" lang={lang}>
                {tiles.map(({ c, count, image }) => (
                  <Link key={c.id} href={catHref(c.slug)} className="block overflow-hidden rounded-xl border border-line bg-white transition-shadow hover:border-midblue hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)]">
                    <Photo src={sizedPhoto(image, 600)} alt="" glyph={null} bg="bg-[#E8D5D0]" className="h-[150px] w-full" />
                    <span className="block p-3">
                      <span className="block truncate font-nunito text-lg font-semibold leading-[22px] text-navy">{catName(c, lang)}</span>
                      <span className="mt-1 block truncate text-sm leading-[17px] text-gray-text">{count} {count === 1 ? t('מקום', 'place') : t('מקומות', 'places')}</span>
                    </span>
                  </Link>
                ))}
              </RotatingRow>
            </div>
          </section>
        )}

        <Row icon="section_restaurants.svg" title={t('מסעדות פופולריות במודיעין', 'Popular Restaurants in Modiin')}
          sub={t('המסעדות המדורגות ביותר, האהובות על המקומיים.', 'Top rated restaurants loved by locals.')}
          more={t('כל המסעדות', 'View all restaurants')} to={catHref('restaurants')} cards={popular.slice(0, 5).map((p) => card(p, false))} lang={lang} />
        <Row icon="section_coffee.svg" title={t('בתי קפה במודיעין', 'Coffee Shops in Modiin')}
          sub={t('מקומות נעימים לקפה טוב ואווירה טובה.', 'Cozy places for great coffee and good vibes.')}
          more={t('כל בתי הקפה', 'View all coffee shops')} to={catHref('cafe-bakery')} cards={coffee.slice(0, 5).map((p) => card(p, false))} lang={lang} />
        <Row icon="section_bars.svg" title={t('ברים במודיעין', 'Bars in Modiin')}
          sub={t('ברים ופאבים לדרינק ולבילוי בערב.', 'Bars and pubs for a drink and a night out.')}
          more={t('כל הברים', 'View all bars')} to={catHref(barsCat?.slug ?? 'restaurants')} cards={bars.slice(0, 5).map((p) => card(p, false))} lang={lang} />
        <Row icon="section_loved.svg" title={t('האהובים ביותר במודיעין', 'Most Loved in Modiin')}
          sub={t('המקומות שהמקומיים הכי אוהבים.', 'The places locals love most.')}
          more={t('הצג הכל', 'View all')} to={catHref('restaurants') + '?sort=rating'} cards={loved.slice(0, 5).map((p) => card(p, true))} compact lang={lang} />
        <Row icon="section_nearby.svg" title={t('ארוחת צהריים בסביבה', 'Lunch Nearby')}
          sub={t('מצאו מקומות מעולים לארוחת צהריים במודיעין.', 'Find great places for lunch around Modiin.')}
          more={t('הצג הכל', 'View all')} to={catHref('restaurants') + '?delivery=1'} cards={lunch.slice(0, 5).map((p) => card(p, true))} compact delivery lang={lang} />
      </div>

      {/* ── phone ── */}
      <div className="mx-auto max-w-[430px] desk:hidden">
        {/* The campaigns booked for the page's top, one at a time across
            (the app's screen drew an empty panel with three still dots
            here); nothing booked, nothing drawn. */}
        {top.length > 0 && (
          <ul className="mt-4 flex snap-x snap-mandatory gap-3 overflow-x-auto px-4 [scrollbar-width:none]">
            {top.map((b) => (
              <li key={b.id} className="w-full shrink-0 snap-center [&_img]:h-[200px] [&_img]:w-full [&_img]:rounded-xl [&_img]:object-cover">
                <BannerImage banner={b} />
              </li>
            ))}
          </ul>
        )}
        {cuisines.length > 0 && (
          <section className="mt-4">
            <h2 className="px-4 text-base font-semibold text-[#1F1F1F]">{t('גלו את מודיעין', 'Discover Modiin')}</h2>
            <ul className="mt-3 flex gap-3 overflow-x-auto px-4 pb-1 [scrollbar-width:none]">
              {cuisines.map((c) => {
                const n = counts.get(c.id);
                return (
                  <li key={c.id} className="w-[120px] shrink-0">
                    <Link href={catHref(c.slug)} className="block overflow-hidden rounded-xl border border-line bg-white">
                      <Photo src={sizedPhoto(cuisinePhoto(c), 400)} alt="" icon={24} className="h-[90px] w-full" />
                      <span className="block p-2">
                        <span className="block truncate text-sm font-medium text-navy">{catName(c, lang)}</span>
                        {n != null && <span className="mt-0.5 block text-xs text-gray-text">{t(`${n} מקומות`, `${n} places`)}</span>}
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </section>
        )}
        <PhoneSection title={t('מסעדות במודיעין', 'Restaurants in Modiin')} more={t('לכל המסעדות', 'All restaurants')} to={catHref('restaurants')}
          rows={phoneRestaurants.slice(0, 3)} kindOf={phoneKind} lang={lang} />
        <PhoneSection title={t('בתי קפה ומאפיות', 'Cafés & Bakeries')} more={t('לכל בתי הקפה', 'All cafés')} to={catHref('cafe-bakery')}
          rows={phoneCafes.slice(0, 3)} kindOf={phoneKind} lang={lang} />
        {topRated.length > 0 && (
          <section className="mt-10">
            <h2 className="px-4 text-base font-semibold text-[#1F1F1F]">{t('המומלצים ביותר', 'Most Recommended')}</h2>
            <ul className="mt-3 flex gap-5 overflow-x-auto px-[18px] pb-1 [scrollbar-width:none]">
              {topRated.map((b) => (
                <li key={b.id} className="relative w-[250px] shrink-0">
                  <Photo src={sizedPhoto(bizPhoto(b), 600)} alt={bizName(b, lang)} icon={32} className="h-[150px] w-full rounded-xl" />
                  <h3 dir="auto" className="mt-3 truncate font-nunito text-xl font-semibold text-navy">
                    <Link href={href(`/business/${b.slug}/`)} className="after:absolute after:inset-0">{bizName(b, lang)}</Link>
                  </h3>
                  <p className="mt-1 truncate text-sm text-gray-text">{phoneKind(b)}</p>
                  <PhoneAddress b={b} lang={lang} />
                  <div className="mt-3"><Rating rating={Number(b.rating ?? 0)} reviews={b.review_count ?? 0} lang={lang} /></div>
                </li>
              ))}
            </ul>
          </section>
        )}
        {/* "View on Map", floating over the list above the bottom menu, as on
            the events page. */}
        <div className="pointer-events-none fixed inset-x-0 bottom-[92px] z-30 flex justify-center">
          <Link href="/restaurants-map/" className="pointer-events-auto flex h-10 items-center gap-1.5 rounded-[50px] bg-white px-4 text-sm font-medium text-navy shadow-[0_4px_4px_rgba(0,0,0,0.15)]">
            <MapIcon size={16} color="currentColor" />{t('הצג במפה', 'View on Map')}
          </Link>
        </div>
      </div>
    </div>
  );
}

/** A desktop row: the round icon, the heading and its line, "View all", and
 *  one row of cards — four large or five small at the design's width, one
 *  fewer on a narrower window. Left out while it has nothing to show. */
function Row({ icon, title, sub, more, to, cards, compact = false, delivery = false, lang }: {
  icon: string; title: string; sub: string; more: string; to: string; cards: FoodCard[]; compact?: boolean; delivery?: boolean; lang: Lang;
}) {
  if (!cards.length) return null;
  return (
    <section className="mt-[72px]">
      <div className="flex items-center gap-4">
        <img src={`/web/restaurants/${icon}`} alt="" className="-m-[2.4px] size-[52.8px] shrink-0" />
        <div className="min-w-0 flex-1">
          <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{title}</h2>
          <p className="mt-2.5 text-sm leading-[17px] text-gray-text">{sub}</p>
        </div>
        <Link href={to} className="flex shrink-0 items-center gap-1 rounded-full bg-midblue px-4 py-1.5 text-sm font-medium leading-6 text-white hover:bg-midblue/90">
          {more}<img src="/web/restaurants/chevron_right_white.svg" alt="" className="size-4 rtl:-scale-x-100" />
        </Link>
      </div>
      <div className={`mt-8 grid gap-6 ${compact
        ? 'grid-cols-4 min-[1540px]:grid-cols-5 [&>*:nth-child(n+5)]:hidden min-[1540px]:[&>*:nth-child(5)]:block'
        : 'grid-cols-3 min-[1540px]:grid-cols-4 [&>*:nth-child(n+4)]:hidden min-[1540px]:[&>*:nth-child(4)]:block'}`}>
        {cards.map((c) => <div key={c.id}><RestaurantCard p={c} lang={lang} compact={compact} showDelivery={delivery} /></div>)}
      </div>
    </section>
  );
}

function PhoneAddress({ b, lang }: { b: BizRow; lang: Lang }) {
  const address = [b.address, bizNeighborhood(b, lang)].filter(Boolean).join(', ');
  return (
    <p className="mt-3 flex items-center gap-2 text-sm text-gray-text">
      <Location size={16} color="#17A9D0" variant="Bold" className="shrink-0" />
      <span dir="auto" className="truncate">{address}</span>
    </p>
  );
}

/** A phone section (restaurants_screen _buildVerticalSection): three cards,
 *  the last fading out under "View all". */
function PhoneSection({ title, more, to, rows, kindOf, lang }: {
  title: string; more: string; to: string; rows: BizRow[]; kindOf: (b: BizRow) => string; lang: Lang;
}) {
  if (!rows.length) return null;
  return (
    <section className="mt-6 px-4 [&+section]:mt-10">
      <h2 className="text-base font-semibold text-[#1F1F1F]">{title}</h2>
      <div className="relative mt-3 flex flex-col gap-4">
        {rows.map((b) => (
          <article key={b.id} className="relative">
            <div className="relative">
              <Photo src={sizedPhoto(bizPhoto(b), 800)} alt={bizName(b, lang)} className="h-[200px] w-full rounded-xl" />
              {kosherLabel(b.kosher_level) && (
                <span className="absolute bottom-3 start-3 flex h-[27px] items-center gap-1.5 rounded-full bg-[#0033AC] px-2 text-xs font-medium text-white">
                  <ShieldTick size={14} color="#fff" />{lang === 'he' ? 'כשר' : 'Kosher'}
                </span>
              )}
              <span className="absolute -bottom-5 end-3 grid size-10 place-items-center rounded-full border-2 border-white bg-[#31AC4E]">
                <Verify size={20} color="#fff" variant="Bold" />
              </span>
            </div>
            <h3 dir="auto" className="mt-4 font-nunito text-xl font-semibold text-navy">
              <Link href={href(`/business/${b.slug}/`)} className="after:absolute after:inset-0">{bizName(b, lang)}</Link>
            </h3>
            <p className="mt-2 text-sm text-gray-text">{kindOf(b)}</p>
            <PhoneAddress b={b} lang={lang} />
            <div className="mt-3"><Rating rating={Number(b.rating ?? 0)} reviews={b.review_count ?? 0} lang={lang} /></div>
          </article>
        ))}
        <div className="pointer-events-none absolute inset-x-0 bottom-0 h-[222px] bg-[linear-gradient(to_bottom,#FFFFFF00,#fff)]" />
        <Link href={to} className="absolute inset-x-0 bottom-0 flex h-10 items-center justify-center rounded-full border border-midblue bg-white px-6 text-sm font-medium text-midblue">{more}</Link>
      </div>
    </section>
  );
}
