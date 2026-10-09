import Link from 'next/link';
import { CloseCircle, Home2, Map1, SearchNormal1, SearchStatus } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { breadcrumb, href, SITE_NAME } from '@/lib/seo';
import { SITE_URL, CONTACT } from '@/lib/config';
import { activeListings, activeNeighborhoods, localName, type Listing, type ListingKind, type Neighborhood } from '@/lib/data/realestate';
import { JsonLd } from '@/components/JsonLd';
import { MapView } from '@/components/map/MapView';
import { ListingCard, ListingPhoto } from './ListingCard';
import { HoodCarousel } from './HoodCarousel';
import { FilterForm, PriceRange } from './FilterForm';
import { ContactMenu } from './Menus';
import { BROWSE_TYPES, contactOptions, hoodName, priceOf, roomsText, shekels, typeLabel } from './format';
import { applySearch, filterCount, priceBounds, readSearch, searchHref, sortListings, type Search, type SearchParams } from './search';

const A = '/web/realestate';

/**
 * The real estate section: /realestate/ and the old WordPress addresses that
 * stand in for it (/apartments/, /real-estate-agents/, /my-avenue/ …).
 *
 * Desktop (web_realestate_screen.dart): the hero with its search, the six
 * property types, a row for sale and one to let, "What We Are Providing" and
 * the neighbourhoods. With `?kind=` in the address it is the search page
 * instead (web_realestate_search_screen.dart): filters, results, map.
 * Phone (realestate_screen.dart): the search, the types, the sale / rent
 * tabs and the list.
 *
 * [h1] is the page's one heading: the phone bar's title. On an old address
 * it is WordPress's H1 and the desktop shows it above the content too
 * ([oldAddress]); on /realestate/ the desktop design draws no such title,
 * so there it is for screen readers only.
 */
export async function RealEstateView({ path, h1, sp, oldAddress = false }: {
  path: string; h1: string; sp: SearchParams; oldAddress?: boolean;
}) {
  const lang = await getLang();
  const [all, hoods] = await Promise.all([activeListings(), activeNeighborhoods()]);
  const s = readSearch(sp);
  const searching = s.kind != null;

  // The phone tab opens on sale; its list keeps the repository's order
  // (featured, then newest) unless a sort was asked for.
  const phoneKind: ListingKind = s.kind ?? 'sale';
  let phoneRows = applySearch(all.filter((l) => l.kind === phoneKind), s, lang);
  if (sp.sort) phoneRows = sortListings(phoneRows, s.sort);

  const shown = searching ? sortListings(applySearch(all.filter((l) => l.kind === s.kind), s, lang), s.sort) : phoneRows;

  return (
    <div>
      <JsonLd data={[
        breadcrumb(path === '/realestate/' ? [[SITE_NAME, '/'], ['נדל״ן', '/realestate/']] : [[SITE_NAME, '/'], ['נדל״ן', '/realestate/'], [h1, path]]),
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: h1,
          itemListElement: shown.slice(0, 30).map((l, i) => ({
            '@type': 'ListItem', position: i + 1, url: SITE_URL + href(`/listing/${l.id}/`), name: l.title,
          })),
        },
      ]} />

      {/* The phone bar: its title (the page's H1), the search, the types and
          the sale / rent tabs, staying in view over the list. */}
      <div className="sticky top-14 z-30 bg-white/90 pb-2 desk:static desk:bg-transparent desk:pb-0">
        <div className="wrap">
          <h1 className={oldAddress
            ? 'pt-2.5 text-center text-base font-medium leading-6 text-black desk:pt-10 desk:text-start desk:font-nunito desk:text-[28px] desk:font-semibold desk:leading-[34px] desk:text-midblue'
            : 'pt-2.5 text-center text-base font-medium leading-6 text-black desk:sr-only'}>
            {h1}
          </h1>
        </div>
        <PhoneControls s={s} lang={lang} kind={phoneKind} hoods={hoods} />
      </div>

      <div className="hidden desk:block">
        {searching
          ? <DeskSearch s={s} all={all} hoods={hoods} lang={lang} />
          : <DeskLanding s={s} all={all} hoods={hoods} lang={lang} />}
      </div>

      <div className="desk:hidden">
        <PhoneList rows={phoneRows} s={s} lang={lang} />
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// PHONE
// ─────────────────────────────────────────────

function PhoneControls({ s, lang, kind, hoods }: { s: Search; lang: Lang; kind: ListingKind; hoods: Neighborhood[] }) {
  const t = tr(lang);
  const chosen = s.types.length === 1 ? s.types[0] : null;
  // A neighbourhood page's "See all" narrows the list to it: said here, with
  // a way out, rather than filtering out of sight.
  const hood = s.neighborhood ? hoods.find((h) => h.id === s.neighborhood) : undefined;
  return (
    <div className="desk:hidden">
      <FilterForm action="/realestate/" className="mt-[18px] px-4">
        {s.kind && <input type="hidden" name="kind" value={s.kind} />}
        {s.types.map((ty) => <input key={ty} type="hidden" name="type" value={ty} />)}
        {s.neighborhood && <input type="hidden" name="neighborhood" value={s.neighborhood} />}
        {s.sort !== 'newest' && <input type="hidden" name="sort" value={s.sort} />}
        <label className="flex h-12 items-center gap-2 rounded-full border border-line bg-white px-4">
          <SearchNormal1 size={18} color="#6D6D6D" />
          <input type="search" name="q" defaultValue={s.q} placeholder={t('חיפוש לפי מיקום, שכונה...', 'Search by location, neighborhood...')}
            className="min-w-0 flex-1 bg-transparent text-sm outline-none placeholder:text-[#6D6D6D]" />
        </label>
      </FilterForm>
      <div className="mt-4 flex h-[100px] gap-3 overflow-x-auto px-4 [scrollbar-width:none]">
        {BROWSE_TYPES.map(([type, icon]) => {
          const on = chosen === type;
          return (
            <Link key={type} href={searchHref({ ...s, types: on ? [] : [type] })} scroll={false}
              className={`flex w-[100px] shrink-0 flex-col items-center justify-center gap-1.5 rounded-xl bg-white ${on ? 'border-2 border-midblue' : 'border border-line'}`}>
              <img src={icon} alt="" width={32} height={32} className="size-8" />
              <span className={`max-w-full truncate px-2 text-sm text-black ${on ? 'font-semibold' : 'font-medium'}`}>{typeLabel(type, lang)}</span>
            </Link>
          );
        })}
      </div>
      {hood && (
        <div className="mt-3 flex px-4">
          <Link href={searchHref({ ...s, neighborhood: null })} scroll={false} aria-label={t('הסרת הסינון לפי שכונה', 'Remove the neighborhood filter')}
            className="flex h-8 items-center gap-1.5 rounded-full bg-[#E8EEF7] ps-3 pe-2 text-sm text-midblue">
            {t('שכונה: ', 'Neighborhood: ')}{localName(hood.name, hood.name_en, lang)}
            <CloseCircle size={18} color="currentColor" />
          </Link>
        </div>
      )}
      <div className="mt-4 flex gap-5 px-4">
        {(['sale', 'rent'] as const).map((k) => {
          const on = kind === k;
          return (
            <Link key={k} href={searchHref({ ...s, kind: k, min: null, max: null })} scroll={false}
              className={`border-b-[3px] py-3 ${on ? 'border-midblue text-xl font-semibold text-midblue' : 'border-transparent text-base font-medium text-[#6D6D6D]'}`}>
              {k === 'sale' ? t('למכירה', 'For Sale') : t('להשכרה', 'For Rent')}
            </Link>
          );
        })}
      </div>
    </div>
  );
}

function PhoneList({ rows, s, lang }: { rows: Listing[]; s: Search; lang: Lang }) {
  const t = tr(lang);
  const onMap = rows.some((l) => l.latitude != null && l.longitude != null);
  if (!rows.length) {
    const filtering = !!s.q || filterCount(s) > 0;
    return (
      <div className="flex flex-col items-center px-8 py-20 text-center">
        <span className="flex size-[72px] items-center justify-center rounded-full bg-[#F2F2F2]"><Home2 size={30} color="#6D6D6D" /></span>
        <p className="mt-4 text-base font-semibold text-[#1F1F1F]">{filtering ? t('לא נמצאו מודעות מתאימות', 'No listings match your search') : t('אין מודעות כרגע', 'No listings right now')}</p>
        {!filtering && <p className="mt-2 text-[13px] text-[#6D6D6D]">{t('כשתפורסמנה דירות במודיעין, הן יופיעו כאן.', 'When apartments are posted in Modiin, they will appear here.')}</p>}
      </div>
    );
  }
  return (
    <div className="px-4 pt-2 pb-6">
      <div className="flex flex-col gap-4">
        {rows.map((l) => <ListingCard key={l.id} l={l} lang={lang} variant="phone" />)}
      </div>
      {onMap && (
        <div className="pointer-events-none sticky bottom-[92px] z-30 mt-4 flex justify-center">
          <Link href={searchHref({ ...s, kind: s.kind ?? 'sale' }, '/realestate-map/')}
            className="pointer-events-auto flex h-10 items-center gap-1.5 rounded-full bg-white px-4 text-sm font-medium text-navy shadow-[0_4px_12px_rgba(0,0,0,0.25)]">
            <Map1 size={16} color="currentColor" />{t('הצג במפה', 'View on Map')}
          </Link>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────
// DESKTOP — the landing page
// ─────────────────────────────────────────────

function SectionTitle({ children, center = false }: { children: React.ReactNode; center?: boolean }) {
  return <h2 className={`font-nunito text-[28px] font-semibold leading-[34px] text-midblue ${center ? 'text-center' : ''}`}>{children}</h2>;
}

function Notice({ title, body, icon = 'home' }: { title: string; body: string; icon?: 'home' | 'search' }) {
  const Icon = icon === 'home' ? Home2 : SearchStatus;
  return (
    <div className="flex flex-col items-center rounded-xl border border-line px-6 py-[72px] text-center">
      <Icon size={44} color="rgba(109,109,109,0.5)" />
      <p className="mt-4 font-nunito text-xl font-semibold leading-[25px] text-navy">{title}</p>
      <p className="mt-2 text-sm leading-[17px] text-gray-text">{body}</p>
    </div>
  );
}

function DeskLanding({ s, all, hoods, lang }: { s: Search; all: Listing[]; hoods: Neighborhood[]; lang: Lang }) {
  const t = tr(lang);
  const selected = s.types.length === 1 ? s.types[0] : null;
  const counts = new Map<string, number>();
  for (const l of all) counts.set(l.property_type, (counts.get(l.property_type) ?? 0) + 1);

  const row = (kind: ListingKind) => {
    const rent = kind === 'rent';
    const rows = all.filter((l) => l.kind === kind && (!selected || l.property_type === selected)).slice(0, 4);
    return (
      <section className="wrap">
        <div className="flex items-center gap-4">
          <div className="min-w-0 flex-1">
            <SectionTitle>{rent ? t('דירות להשכרה במודיעין', 'Apartments for Rent in Modiin') : t('דירות למכירה במודיעין', 'Apartments for Sale in Modiin')}</SectionTitle>
            <p className="mt-2.5 text-sm leading-[17px] text-gray-text">
              {rent
                ? t('גלו דירות ובתים להשכרה בשכונות הטובות ביותר ברחבי מודיעין.', 'Discover apartments and homes available for rent in the best neighborhoods across Modiin.')
                : t('גלו את הדירות והבתים העדכניים ביותר למכירה ברחבי מודיעין.', 'Explore the latest apartments and homes available for sale across Modiin.')}
            </p>
          </div>
          <Link href={searchHref({ kind, types: selected ? [selected] : [] })}
            className="flex h-9 shrink-0 items-center gap-1 rounded-full bg-midblue px-4 text-sm font-medium leading-6 text-white hover:bg-midblue/90">
            {t('לכל הנכסים', 'View all properties')}
            <img src={`${A}/chevron_right_white.svg`} alt="" width={16} height={16} className="rtl:-scale-x-100" />
          </Link>
        </div>
        <div className="mt-8">
          {rows.length ? (
            // Four across the column, three on a laptop where four would
            // squeeze the price line.
            <div className="grid grid-cols-3 gap-6 min-[1319px]:grid-cols-4 [&>*:nth-child(4)]:hidden min-[1319px]:[&>*:nth-child(4)]:block">
              {rows.map((l) => <ListingCard key={l.id} l={l} lang={lang} variant="desk" />)}
            </div>
          ) : (
            <Notice
              title={selected
                ? t(`אין כרגע ${typeLabel(selected, lang)} בקטגוריה הזו`, `No ${typeLabel(selected, lang)} listed here yet`)
                : rent ? t('אין כרגע דירות להשכרה', 'Nothing to let yet') : t('אין כרגע דירות למכירה', 'Nothing for sale yet')}
              body={selected
                ? t('הסירו את סוג הנכס שנבחר למעלה כדי לראות את הכל.', 'Clear the property type above to see everything on file.')
                : t('נכסים יופיעו כאן עם פרסומם.', 'Properties will appear here as they are published.')} />
          )}
        </div>
      </section>
    );
  };

  // The three cards: the first one lit until the pointer is over another.
  const services = [
    { icon: 'svc_rent', title: t('מצאו את השכירות הבאה', 'Find Your Next Rental'), body: t('חפשו דירות ובתים להשכרה ברחבי מודיעין.', 'Browse apartments and homes available for rent across Modiin.'), href: searchHref({ kind: 'rent' }) },
    { icon: 'svc_sell', title: t('מכרו נכס', 'Sell A Property'), body: t('פרסמו את הנכס שלכם והתחברו לאנשים שמחפשים לקנות במודיעין.', 'List your property and connect with people looking to buy in Modiin.'), href: `mailto:${CONTACT.email}` },
    { icon: 'svc_buy', title: t('קנו נכס', 'Buy A Property'), body: t('גלו דירות ובתים למכירה במודיעין. השוו נכסים, שכונות, מחירים.', 'Explore apartments and homes for sale in Modiin. Compare properties, neighborhoods, prices.'), href: searchHref({ kind: 'sale' }) },
  ];

  // The design's cards are photographs: those with one first, in the
  // admin's order.
  const hoodCards = [...hoods.filter((h) => h.image_url), ...hoods.filter((h) => !h.image_url)]
    .map((h) => ({ id: h.id, name: localName(h.name, h.name_en, lang), image: h.image_url }));

  return (
    <>
      {/* HERO — the dotted band, the photograph, the search across it. */}
      <section className="relative h-[662px]">
        <span className="absolute inset-0 bg-[linear-gradient(to_top,rgba(191,231,246,0.08),rgba(196,196,196,0))]" />
        <span className="absolute inset-0 bg-[url(/web/common/dots_tile.png)] bg-size-[154px_154px] bg-top bg-repeat opacity-20" />
        <div className="absolute inset-x-6 top-12 mx-auto h-[551px] max-w-[1200px] overflow-hidden rounded-3xl bg-[#6F7476]">
          <img src="/web/realestate/hero.webp" alt="" className="absolute inset-0 size-full object-cover" />
          <span className="absolute inset-0 bg-black/20" />
          <span className="absolute inset-x-0 top-0 h-[428px] bg-[linear-gradient(to_bottom,rgba(128,178,223,0.55),rgba(128,178,223,0))]" />
          <div className="absolute inset-x-0 top-28 flex flex-col items-center px-6 text-center text-white">
            <p className="font-nunito text-[44px] font-semibold leading-[54px]">{t('מצאו את הבית המושלם במודיעין', 'Find Your Perfect Home in Modiin')}</p>
            <p className="mt-3.5 text-base leading-[19px]">{t('גלו דירות ובתים למכירה ולהשכרה.', 'Discover apartments and homes available for sale and rent.')}</p>
            <form action="/realestate/" method="get" role="search"
              className="mt-12 flex w-full max-w-[848px] items-center rounded-[50px] bg-white p-4 text-start text-black shadow-[0_0_8px_rgba(0,0,0,0.25)]">
              <label className="flex flex-col gap-2 ps-0">
                <span className="text-sm leading-[17px] text-gray-text">{t('אני מחפש', "I'm looking to")}</span>
                <select name="kind" defaultValue="sale"
                  className="w-[134px] cursor-pointer appearance-none bg-[url(/web/realestate/chevron16.svg)] bg-size-[16px] bg-no-repeat text-base font-medium leading-[19px] outline-none ltr:bg-position-[right_center] rtl:bg-position-[left_center]">
                  <option value="sale">{t('לקנות', 'Buy')}</option>
                  <option value="rent">{t('לשכור', 'Rent')}</option>
                </select>
              </label>
              <label className="ms-[47px] flex min-w-0 flex-1 flex-col gap-2">
                <span className="text-sm leading-[17px] text-gray-text">{t('מיקום / שכונה', 'Location / Neighborhood')}</span>
                <input type="search" name="q" placeholder={t('הזינו כתובת, שכונה או אזור.', 'Enter an address, neighborhood or area.')}
                  className="bg-transparent text-base leading-[19px] outline-none placeholder:text-[#4F4F4F]" />
              </label>
              <button type="submit" className="ms-4 flex items-center gap-2 rounded-[60px] bg-midblue px-6 py-[11px] text-base font-medium leading-6 text-white hover:bg-midblue/90">
                <img src="/web/common/search_white.svg" alt="" width={18} height={18} />{t('חיפוש', 'Search')}
              </button>
            </form>
          </div>
        </div>
      </section>

      {/* BROWSE BY TYPE — each a filter on the two rows below. */}
      <section className="wrap mt-12">
        <div className="mx-auto max-w-[1200px]">
          <SectionTitle center>{t('חפשו נדל״ן', 'Browse Real Estate')}</SectionTitle>
          <div className="mt-8 grid grid-cols-6 gap-4">
            {BROWSE_TYPES.map(([type, icon]) => {
              const on = selected === type;
              const n = counts.get(type) ?? 0;
              return (
                <Link key={type} href={on ? '/realestate/' : searchHref({ types: [type] })} scroll={false} aria-pressed={on}
                  className={`flex flex-col items-center rounded-xl bg-white px-4 py-5 text-center ${on ? 'border-2 border-midblue' : 'border border-line hover:border-[#CFCFCF]'}`}>
                  <img src={icon} alt="" width={32} height={32} className="size-8" />
                  <span className="mt-[19px] text-base font-medium leading-[19px] text-black">{typeLabel(type, lang)}</span>
                  <span className="mt-2 text-sm leading-[17px] text-[#6D6D6D]">{n === 0 ? t('אין נכסים כרגע', 'None listed yet') : t(`${n} נכסים`, `${n} Properties`)}</span>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      <div className="mt-[72px]">{row('sale')}</div>
      <div className="mt-20">{row('rent')}</div>

      {/* WHAT WE ARE PROVIDING */}
      <section className="wrap mt-20">
        <SectionTitle center>{t('מה אנחנו מציעים', 'What We Are Providing')}</SectionTitle>
        <div className="group/svc mt-8 grid grid-cols-3 gap-[21px]">
          {services.map((c, i) => {
            const lit = i === 0
              ? 'shadow-[0_1px_5px_rgba(0,0,0,0.1)] group-has-[a:hover]/svc:shadow-none hover:!shadow-[0_1px_5px_rgba(0,0,0,0.1)]'
              : 'hover:shadow-[0_1px_5px_rgba(0,0,0,0.1)]';
            const titleLit = i === 0
              ? 'text-midblue group-has-[a:hover]/svc:text-black group-hover/card:!text-midblue'
              : 'text-black group-hover/card:text-midblue';
            const artLit = i === 0
              ? 'opacity-100 group-has-[a:hover]/svc:opacity-0 group-hover/card:!opacity-100'
              : 'opacity-0 group-hover/card:opacity-100';
            return (
              <a key={c.icon} href={c.href} className={`group/card flex flex-col items-center rounded-[10px] border border-[#E0E0E0] bg-white p-[30px] text-center transition-shadow ${lit}`}>
                {/* The lit card's drawing turns the brand blue; the rental
                    one has a grey twin rather than a tint. */}
                <span className="relative size-14">
                  <img src={`${A}/${c.icon === 'svc_rent' ? 'svc_rent_grey' : c.icon}.svg`} alt="" className="absolute inset-0 size-14 object-contain" />
                  {c.icon === 'svc_rent'
                    ? <img src={`${A}/svc_rent.svg`} alt="" className={`absolute inset-0 size-14 object-contain transition-opacity ${artLit}`} />
                    : <span className={`absolute inset-0 bg-midblue transition-opacity ${artLit}`}
                        style={{ mask: `url(${A}/${c.icon}.svg) center / contain no-repeat`, WebkitMask: `url(${A}/${c.icon}.svg) center / contain no-repeat` }} />}
                </span>
                <span className={`mt-5 text-[22px] font-semibold leading-[27px] ${titleLit}`}>{c.title}</span>
                <span className="mt-4 text-base leading-[1.6] text-gray-text">{c.body}</span>
              </a>
            );
          })}
        </div>
      </section>

      {/* APARTMENTS BY NEIGHBOURHOOD */}
      {hoodCards.length > 0 && (
        <section className="wrap mt-20">
          <SectionTitle center>{t('דירות לפי שכונות', 'Apartments by Neighborhoods')}</SectionTitle>
          <HoodCarousel hoods={hoodCards} lang={lang} />
        </section>
      )}
      <div className="h-[146px]" />
    </>
  );
}

// ─────────────────────────────────────────────
// DESKTOP — the search page: filters | results | map
// ─────────────────────────────────────────────

function Check({ name, value, checked, label }: { name: string; value: string; checked: boolean; label: string }) {
  return (
    <label className="flex cursor-pointer items-center gap-2">
      <input type="checkbox" name={name} value={value} defaultChecked={checked} className="peer sr-only" />
      <span className="size-4 shrink-0 bg-[url(/web/realestate/checkbox_off.svg)] bg-contain peer-checked:bg-[url(/web/realestate/checkbox_on.svg)] peer-focus-visible:outline-2 peer-focus-visible:outline-midblue" />
      <span className="text-[13px] leading-4 text-[#3D3D3D]">{label}</span>
    </label>
  );
}

function Group({ title, gap, children }: { title: string; gap: number; children: React.ReactNode }) {
  return (
    <fieldset>
      <legend className="text-sm font-semibold leading-[17px] text-navy">{title}</legend>
      <div style={{ marginTop: gap }}>{children}</div>
    </fieldset>
  );
}

const SELECT = 'h-[42px] cursor-pointer appearance-none rounded-lg border border-line bg-white bg-[url(/web/realestate/chevron_down20.svg)] bg-size-[20px] bg-no-repeat px-3 text-sm leading-[17px] text-black outline-none ltr:bg-position-[right_12px_center] ltr:pr-10 rtl:bg-position-[left_12px_center] rtl:pl-10';

function DeskSearch({ s, all, hoods, lang }: { s: Search; all: Listing[]; hoods: Neighborhood[]; lang: Lang }) {
  const t = tr(lang);
  const kind = s.kind!;
  const rent = kind === 'rent';
  const ofKind = all.filter((l) => l.kind === kind);
  const results = sortListings(applySearch(ofKind, s, lang), s.sort);
  const bounds = priceBounds(ofKind);
  const n = results.length;
  const heading = rent
    ? (n === 1 ? t('נמצאה דירה אחת להשכרה', '1 Apartment found for rent') : t(`${n} דירות נמצאו להשכרה`, `${n} Apartments found for rent`))
    : (n === 1 ? t('נמצאה דירה אחת למכירה', '1 Apartment found for sale') : t(`${n} דירות נמצאו למכירה`, `${n} Apartments found for sale`));
  const pins = results.filter((l) => l.latitude != null && l.longitude != null).map((l) => ({
    id: l.id, lat: l.latitude!, lng: l.longitude!, href: href(`/listing/${l.id}/`), label: l.title,
    icon: `${A}/listing_pin.svg`, size: [40, 44] as [number, number],
  }));
  const range: [number, number] | null = bounds && (s.min != null || s.max != null)
    ? [Math.max(bounds[0], s.min ?? bounds[0]), Math.min(bounds[1], s.max ?? bounds[1])] : null;

  return (
    // Keyed to the filters (not the typed text), so "Clear all filters"
    // draws the boxes afresh while typing keeps its place in the field.
    <FilterForm key={searchHref({ ...s, q: '' })} action="/realestate/" className="flex h-[calc(100vh-80px)] min-h-[640px] border-t border-line">
      <input type="hidden" name="kind" value={kind} />

      {/* FILTERS — 294 wide */}
      <aside className="w-[294px] shrink-0 overflow-y-auto border-e border-line bg-surface p-5">
        <label className="flex h-[42px] items-center gap-2 rounded-lg border border-line bg-white px-3">
          <img src={`${A}/search_pin.svg`} alt="" width={16} height={16} />
          <input type="search" name="q" defaultValue={s.q} placeholder={t('חיפוש לפי מיקום...', 'Search by location...')}
            className="min-w-0 flex-1 bg-transparent text-sm leading-[17px] text-black outline-none placeholder:text-[#6D6D6D]" />
        </label>
        <div className="mt-4 flex flex-col gap-6">
          <Group title={t('סוג נכס', 'Property Type')} gap={17}>
            <div className="flex flex-col gap-3.5">
              {BROWSE_TYPES.map(([type]) => <Check key={type} name="type" value={type} checked={s.types.includes(type)} label={typeLabel(type, lang)} />)}
            </div>
          </Group>
          {/* Only when there are two different prices to slide between. */}
          {bounds && (
            <Group title={t('טווח מחירים', 'Price Range')} gap={14}>
              <PriceRange bounds={bounds} value={range} />
            </Group>
          )}
          <Group title={t('חדרים', 'Rooms')} gap={17}>
            <div className="flex flex-col gap-3.5">
              {[1, 2, 3, 4, 5].map((r) => (
                <Check key={r} name="rooms" value={String(r)} checked={s.rooms.includes(r)}
                  label={r === 5 ? t('5+ חדרים', '5+ Rooms') : r === 1 ? t('חדר 1', '1 Room') : t(`${r} חדרים`, `${r} Rooms`)} />
              ))}
            </div>
          </Group>
          <Group title={t('קומה', 'Floor')} gap={12}>
            <select name="floor" defaultValue={s.floor ?? ''} className={`${SELECT} w-full`} aria-label={t('קומה', 'Floor')}>
              <option value="">{t('הכל', 'Any')}</option>
              <option value="low">1-3</option>
              <option value="mid">4-7</option>
              <option value="high">8+</option>
            </select>
          </Group>
          <Group title={t('שכונה', 'Neighborhood')} gap={12}>
            <select name="neighborhood" defaultValue={s.neighborhood ?? ''} className={`${SELECT} w-full`} aria-label={t('שכונה', 'Neighborhood')}>
              <option value="">{t('הכל', 'Any')}</option>
              {hoods.map((h) => <option key={h.id} value={h.id}>{localName(h.name, h.name_en, lang)}</option>)}
            </select>
          </Group>
          {filterCount(s) > 0 && (
            <Link href={searchHref({ kind, q: s.q, sort: s.sort })} scroll={false}
              className="self-start text-[13px] font-medium leading-4 text-midblue underline">
              {t('נקה את כל הסינונים', 'Clear all filters')}
            </Link>
          )}
        </div>
      </aside>

      {/* RESULTS */}
      <section className="flex min-w-0 flex-[900] flex-col border-e border-line">
        <div className="flex items-center gap-4 px-6 pt-6 pb-[26px]">
          <div className="min-w-0 flex-1">
            <h2 className="font-nunito text-[28px] font-semibold leading-[34px] text-midblue">{heading}</h2>
            <p className="mt-2 text-sm leading-[17px] text-gray-text">{t('במודיעין מכבים רעות', 'in Modiin Maccabim Reut')}</p>
          </div>
          <select name="sort" defaultValue={s.sort} aria-label={t('מיון', 'Sort')} className={`${SELECT} w-auto min-w-[166px] shrink-0`}>
            <option value="newest">{t('מיון: החדשים ביותר', 'Sort by: Newest')}</option>
            <option value="price-low">{t('מיון: המחיר הנמוך', 'Sort by: Lowest price')}</option>
            <option value="price-high">{t('מיון: המחיר הגבוה', 'Sort by: Highest price')}</option>
          </select>
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto px-6">
          {!ofKind.length ? (
            // Nothing published at all is not nothing matching the filters.
            <div className="py-16"><Notice
              title={rent ? t('אין כרגע דירות להשכרה', 'No apartments to let yet') : t('אין כרגע דירות למכירה', 'No apartments for sale yet')}
              body={t('נכסים יופיעו כאן עם פרסומם.', 'Properties will appear here as they are published.')} /></div>
          ) : !results.length ? (
            <div className="flex flex-col items-center py-16 text-center">
              <SearchStatus size={48} color="rgba(123,137,154,0.6)" />
              <p className="mt-4 font-nunito text-xl font-semibold text-navy">{t('אין דירות שתואמות את הסינון', 'No apartments match your filters')}</p>
              <p className="mt-2 text-sm text-gray-text">{t('נסו להרחיב את טווח המחירים או להסיר סינון.', 'Try widening the price range or clearing a filter.')}</p>
              {filterCount(s) > 0 && (
                <Link href={searchHref({ kind, q: s.q, sort: s.sort })} scroll={false}
                  className="mt-6 flex h-11 items-center rounded-[60px] bg-midblue px-8 text-base font-medium text-white">
                  {t('נקה את כל הסינונים', 'Clear all filters')}
                </Link>
              )}
            </div>
          ) : results.map((l) => <ResultRow key={l.id} l={l} lang={lang} />)}
        </div>
      </section>

      {/* MAP — the results that carry coordinates */}
      <div className="min-w-0 flex-[726]">
        <MapView pins={pins} lang={lang} zoom={13} center={pins.length === 1 ? undefined : [31.8928, 35.0104]} />
      </div>
    </FilterForm>
  );
}

/** One result: the photograph, then the title, where it is, its figures,
 *  and the price with a way to call. A plain flat is a "Standard
 *  Apartment" here, to set it apart from a garden one. */
function ResultRow({ l, lang }: { l: Listing; lang: Lang }) {
  const t = tr(lang);
  const price = priceOf(l);
  const place = hoodName(l, lang) ?? l.address;
  const phone = l.real_estate_agents?.phone ?? l.contact_phone;
  const figures: [string, string][] = [];
  if (l.sqm != null) figures.push(['spec_sqm', t(`${l.sqm} מ״ר`, `${l.sqm} m²`)]);
  if (l.rooms != null) figures.push(['spec_rooms', l.rooms === 1 ? t('חדר 1', '1 Room') : t(`${roomsText(l.rooms)} חדרים`, `${roomsText(l.rooms)} Rooms`)]);
  if (l.floor != null) figures.push(['spec_floor', l.floor === 0 ? t('קומת קרקע', 'Ground Floor') : t(`קומה ${l.floor}`, `Floor ${l.floor}`)]);
  figures.push(['spec_type', l.property_type === 'apartment' ? t('דירה רגילה', 'Standard Apartment') : typeLabel(l.property_type, lang)]);
  return (
    <article className="relative flex h-[202px] gap-6 border-b border-line py-5">
      <ListingPhoto url={l.cover_url} width={261} alt={l.title} className="h-[162px] w-[261px] shrink-0 rounded-xl" iconSize={40} />
      <div className="flex min-w-0 flex-1 flex-col justify-between">
        <div>
          <h3 className="truncate font-nunito text-lg font-semibold leading-[22px] text-navy">
            <Link href={href(`/listing/${l.id}/`)} dir="auto" className="after:absolute after:inset-0">{l.title}</Link>
          </h3>
          {place && <p dir="auto" className={`mt-2 truncate text-sm leading-[17px] text-gray-text ${lang === 'he' ? 'text-right' : 'text-left'}`}>{place}</p>}
          <div className="mt-[22px] flex flex-wrap gap-x-4 gap-y-2 min-[1700px]:gap-x-[31px]">
            {figures.map(([icon, text]) => (
              <span key={icon} className="flex items-center gap-2 whitespace-nowrap text-xs leading-[15px] text-[#3D3D3D]">
                <img src={`${A}/${icon}.svg`} alt="" width={14} height={14} />{text}
              </span>
            ))}
          </div>
        </div>
        <div className="flex items-center">
          <div className="flex min-w-0 flex-1 items-baseline gap-2">
            {price == null
              ? <span className="font-nunito text-base font-semibold text-midblue">{t('מחיר לפי בקשה', 'Price on request')}</span>
              : <>
                  <span dir="ltr" className="font-nunito text-[22px] font-semibold leading-[27px] text-midblue">{shekels(price)}</span>
                  {l.kind === 'rent' && <span className="text-sm text-gray-text">{t('/ לחודש', '/ month')}</span>}
                </>}
          </div>
          {/* Only when there is a number to dial. */}
          {phone && (
            <div className="relative z-10">
              <ContactMenu options={contactOptions({ phone, whatsapp: phone }, lang)} label={t('צור קשר', 'Contact')}
                icon={<img src={`${A}/call16.svg`} alt="" width={16} height={16} />}
                className="flex h-10 items-center gap-2 rounded-[60px] border border-midblue px-4 text-sm font-medium leading-6 text-midblue hover:bg-midblue/5" />
            </div>
          )}
        </div>
      </div>
    </article>
  );
}
