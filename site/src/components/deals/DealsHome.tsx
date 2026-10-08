'use client';
import { useMemo, useRef, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { ArrowLeft, DiscountShape } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import type { Deal, DealCategory } from '@/lib/data/deals';
import type { Banner } from '@/lib/data/banners';
import { Photo } from '@/components/events/Photo';
import { MDealCard, WebDealCard } from './DealCards';
import { DealsBanners } from './DealsBanners';
import { brandStrip, businessName, isHebrew, residentsOnly } from './labels';

type Pill = 'expiring' | 'popular' | 'newest' | 'residents';

/** How many deals the phone's list shows before "View All". */
const FOLDED = 3;

/** The deals page (web_deals_screen.dart above 1100, deals_screen.dart
 *  below), from the deals running now: the heading, the DEALS_TOP banners,
 *  the categories that hold a deal, the deals themselves — a row of cards on
 *  the website with the four pills under it, a list on the phone — and the
 *  businesses behind the most-claimed deals. A category or a business
 *  narrows the deals in place. */
export function DealsHome({ lang, heading, deals, categories, kinds, banners, dealHref }: {
  lang: Lang; heading: string; deals: Deal[]; categories: DealCategory[];
  kinds: Record<string, string[]>; banners: Banner[]; dealHref: Record<string, string>;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [category, setCategory] = useState<string | null>(null);
  const [business, setBusiness] = useState<string | null>(null);
  const [pill, setPill] = useState<Pill | null>(null);
  const [expanded, setExpanded] = useState(false);
  const row = useRef<HTMLDivElement>(null);
  const deskDeals = useRef<HTMLDivElement>(null);
  const phoneDeals = useRef<HTMLDivElement>(null);

  const inCategory = (d: Deal, id: string) => !!d.business && (kinds[d.business.id] ?? []).includes(id);

  // Only the categories that hold a running deal, in the admin's order. The
  // website's circle is the category's picture, else a deal's photograph.
  const tiles = useMemo(() => categories.flatMap((c) => {
    const inIt = deals.filter((d) => inCategory(d, c.id));
    if (!inIt.length) return [];
    const photo = c.image_url || inIt.map((d) => d.image_url ?? d.business?.cover).find(Boolean) || null;
    return [{ c, count: inIt.length, photo }];
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }), [categories, deals, kinds]);

  const narrowed = useMemo(() => {
    let list = deals;
    if (category) list = list.filter((d) => inCategory(d, category));
    if (business) list = list.filter((d) => d.business?.id === business);
    return list;
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [deals, category, business, kinds]);

  // The website's pills: three put the row in an order, the fourth keeps the
  // residents-only deals.
  const shown = useMemo(() => {
    const list = [...narrowed];
    const time = (s: string | null) => (s ? Date.parse(s) : null);
    const nullsLast = (x: number | null, y: number | null, cmp: number) => (x == null || y == null ? (x == null ? (y == null ? 0 : 1) : -1) : cmp);
    switch (pill) {
      case 'residents': return list.filter(residentsOnly);
      case 'expiring': return list.sort((a, b) => { const x = time(a.end_at), y = time(b.end_at); return nullsLast(x, y, (x ?? 0) - (y ?? 0)); });
      case 'popular': return list.sort((a, b) => b.claim_count - a.claim_count);
      case 'newest': return list.sort((a, b) => {
        const x = time(a.start_at ?? a.created_at), y = time(b.start_at ?? b.created_at);
        return nullsLast(x, y, (y ?? 0) - (x ?? 0));
      });
      default: return list;
    }
  }, [narrowed, pill]);

  // The businesses behind the deals, the most-claimed first.
  const brands = useMemo(() => {
    const by = new Map<string, Deal[]>();
    for (const d of deals) {
      if (!d.business?.id || !d.business.name) continue;
      by.set(d.business.id, [...(by.get(d.business.id) ?? []), d]);
    }
    const claims = (l: Deal[]) => l.reduce((s, d) => s + d.claim_count, 0);
    return [...by.entries()].sort(([, a], [, b]) =>
      claims(b) - claims(a) || b.filter((d) => d.is_featured).length - a.filter((d) => d.is_featured).length || b.length - a.length);
  }, [deals]);
  // The phone orders them without the featured step (deals_screen.dart).
  const phoneBrands = useMemo(() => {
    const claims = (l: Deal[]) => l.reduce((s, d) => s + d.claim_count, 0);
    return [...brands].sort(([, a], [, b]) => claims(b) - claims(a) || b.length - a.length);
  }, [brands]);

  const scrollRow = (dir: number) => {
    const el = row.current;
    if (!el) return;
    const rtl = getComputedStyle(el).direction === 'rtl';
    el.scrollBy({ left: dir * 500 * (rtl ? -1 : 1), behavior: 'smooth' });
  };

  /** A brand with one deal opens it; with several it narrows the deals to
   *  them, or widens them back when chosen again. */
  const pickBrand = (id: string, phone: boolean) => {
    const narrowing = business !== id;
    setBusiness(narrowing ? id : null);
    setCategory(null);
    if (phone) setExpanded(narrowing);
    if (row.current) row.current.scrollLeft = 0;
    if (narrowing) (phone ? phoneDeals : deskDeals).current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  const isNarrowed = category != null || business != null || pill === 'residents';
  const clearAll = () => { setCategory(null); setBusiness(null); setPill(null); };
  const phoneList = narrowed;
  const folded = !expanded && phoneList.length > FOLDED;

  return (
    <div>
      {/* ── The heading: on the phone in the turquoise wash under the bar ── */}
      <div className="relative">
        <div className="pointer-events-none absolute inset-x-0 top-0 h-[271px] desk:hidden" style={{ background: 'linear-gradient(to bottom, rgba(23,169,208,0.2), rgba(23,169,208,0))' }} />
        <div className="relative pb-[25px] desk:mx-auto desk:max-w-[calc(1600px_+_2*clamp(16px,4.5vw,80px))] desk:px-[clamp(16px,4.5vw,80px)] desk:pb-0 desk:pt-14">
          <div className="relative flex h-11 items-center justify-center desk:hidden">
            <Link href="/" aria-label={t('חזרה', 'Back')} className="absolute start-[15px] flex size-6 items-center justify-center text-[#3D3D3D]">
              <span className="rtl:-scale-x-100"><ArrowLeft size={24} color="currentColor" /></span>
            </Link>
            <span className="text-base font-medium text-black">{t('מבצעים', 'Deals')}</span>
          </div>
          <h1 className="mt-[13px] px-10 text-center font-nunito text-[32px] font-semibold leading-[39px] text-[#001650] desk:mt-0 desk:px-0 desk:text-[44px] desk:leading-[1.23] desk:text-black">
            {heading}
          </h1>
          <p className="mt-[13px] px-[25px] text-center text-base leading-[19px] text-[#6D6D6D] desk:hidden">
            {t('גלו מבצעים, הנחות והטבות לזמן מוגבל ברחבי מודיעין.', 'Explore local deals, discounts, and limited-time offers across Modiin.')}
          </p>
          <p className="mt-3.5 hidden text-center text-base leading-[1.19] text-[#6D6D6D] desk:block">
            {t('גלו מבצעים מקומיים, הנחות והטבות לזמן מוגבל בכל מודיעין.', 'Explore local deals, discounts, and limited-time offers across Modiin.')}
          </p>
        </div>
        {banners.length > 0 && <div className="relative"><DealsBanners banners={banners} /></div>}
      </div>

      {/* ── Explore Deals by Category ── */}
      {tiles.length > 0 && (
        <>
          <section className="wrap hidden pt-14 desk:block">
            <h2 className="font-nunito text-[28px] font-semibold leading-[1.21] text-midblue">{t('גלו מבצעים לפי קטגוריה', 'Explore Deals by Category')}</h2>
            {/* The design's single row of six columns; a seventh or eighth
                narrows them, past eight they wrap eight to a row. */}
            <div className="mt-10 grid gap-y-10" style={{ gridTemplateColumns: `repeat(${tiles.length <= 6 ? 6 : Math.min(tiles.length, 8)}, minmax(0, 1fr))` }}>
              {tiles.map(({ c, count, photo }) => {
                const on = category === c.id;
                const name = lang === 'en' && c.name_en ? c.name_en : c.name;
                return (
                  <button key={c.id} type="button" onClick={() => { setCategory(on ? null : c.id); setBusiness(null); }} aria-pressed={on}
                    className="group flex flex-col items-center">
                    <span className="relative block size-[116px] rounded-full">
                      <Photo url={photo} alt="" className="size-full rounded-full" icon={DiscountShape} iconSize={30} />
                      <span className={`absolute inset-0 rounded-full ${on ? 'ring-[3px] ring-inset ring-midblue' : 'group-hover:ring-[3px] group-hover:ring-inset group-hover:ring-turquoise'}`} />
                    </span>
                    <span dir={isHebrew(name) ? 'rtl' : 'ltr'} className="mt-5 line-clamp-2 px-2.5 text-center text-lg font-semibold leading-[1.21] text-[#1C1C1E]">{name}</span>
                    <span className="mt-1.5 text-sm leading-[1.21] text-gray-text">{count === 1 ? t('מבצע אחד', '1 Deal') : t(`${count} מבצעים`, `${count} Deals`)}</span>
                  </button>
                );
              })}
            </div>
          </section>
          <section className="pb-8 desk:hidden">
            <h2 className="px-4 text-base font-semibold text-[#1F1F1F]">{t('מבצעים לפי קטגוריה', 'Explore Deals by Category')}</h2>
            <div className="mt-4 flex overflow-x-auto px-4 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {tiles.map(({ c, count }) => {
                const on = category === c.id;
                const name = lang === 'en' && c.name_en ? c.name_en : c.name;
                return (
                  <button key={c.id} type="button" aria-pressed={on} className="flex w-[100px] shrink-0 flex-col items-center"
                    onClick={() => { setCategory(on ? null : c.id); setBusiness(null); setExpanded(false); }}>
                    <span className={`block size-16 rounded-full ${on ? 'ring-[2.5px] ring-midblue' : ''}`}>
                      {/* The category's own picture; the phone has no fallback photograph. */}
                      <Photo url={c.image_url} alt="" className="size-full rounded-full" icon={DiscountShape} iconSize={24} />
                    </span>
                    <span className={`mt-3 w-full truncate px-2.5 text-center text-sm ${on ? 'font-bold' : 'font-medium'} text-black`}>{name}</span>
                    <span className="mt-1 text-sm text-gray-text">{count === 1 ? t('מבצע אחד', '1 deal') : t(`${count} מבצעים`, `${count} deals`)}</span>
                  </button>
                );
              })}
            </div>
          </section>
        </>
      )}

      {/* ── The website: Popular Deals in Modiin, running off the far edge ── */}
      <section ref={deskDeals} className="hidden scroll-mt-24 pt-20 desk:block">
        <div className="wrap flex items-start">
          <div className="min-w-0 flex-1">
            <h2 className="font-nunito text-[28px] font-semibold leading-[1.21] text-midblue">{t('מבצעים פופולריים במודיעין', 'Popular Deals in Modiin')}</h2>
            <p className="mt-2 text-sm leading-[1.21] text-gray-text">{t('המבצעים הנבחרים בשבילכם', 'Top deals handpicked for you')}</p>
          </div>
          {shown.length > 1 && (
            <div className="flex gap-3 pt-2.5">
              <HeaderArrow back onClick={() => scrollRow(-1)} />
              <HeaderArrow onClick={() => scrollRow(1)} />
            </div>
          )}
        </div>
        <div className="mt-[23px]">
          {shown.length === 0 ? (
            <div className="wrap">
              <Notice lang={lang} narrowed={isNarrowed} onClear={clearAll} />
            </div>
          ) : (
            <div ref={row} className="flex gap-5 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
              style={{ paddingInline: 'max(clamp(16px, 4.5vw, 80px), calc((100vw - 1600px) / 2))' }}>
              {shown.map((d) => <WebDealCard key={d.id} deal={d} lang={lang} />)}
            </div>
          )}
        </div>
        {deals.length > 0 && (
          <div className="wrap mt-12 flex flex-wrap justify-center gap-x-[21px] gap-y-4">
            {([['expiring', t('נגמר בקרוב', 'Expiring Soon')], ['popular', t('הכי פופולרי', 'Most Popular')], ['newest', t('חדש', 'New')], ['residents', t('לתושבים בלבד', 'Residents Only')]] as [Pill, string][]).map(([p, label]) => (
              <button key={p} type="button" aria-pressed={pill === p} onClick={() => setPill(pill === p ? null : p)}
                className={`flex h-20 items-center rounded-[50px] border px-10 font-nunito text-2xl font-semibold leading-[1.25] transition-colors ${pill === p ? 'border-midblue bg-midblue text-white' : 'border-[#D1D1D1] bg-white text-[#3D3D3D] hover:border-turquoise'}`}>
                {label}
              </button>
            ))}
          </div>
        )}
      </section>

      {/* ── The phone: Popular Deals, three, then "View All" ── */}
      <section ref={phoneDeals} className="scroll-mt-16 px-4 desk:hidden">
        <h2 className="text-base font-semibold text-[#1F1F1F]">{t('מבצעים פופולריים במודיעין', 'Popular Deals in Modiin')}</h2>
        <div className="mt-4">
          {phoneList.length === 0 ? (
            <div className="flex flex-col items-center px-4 py-12 text-center">
              <span className="flex size-[72px] items-center justify-center rounded-full bg-[#F2F2F2]"><DiscountShape size={30} color="#6D6D6D" /></span>
              <p className="mt-4 text-base font-semibold text-[#1F1F1F]">{t('אין מבצעים כרגע', 'No deals right now')}</p>
              <p className="mt-2 text-[13px] text-[#6D6D6D]">{t('כשעסקים במודיעין יוסיפו מבצעים, הם יופיעו כאן.', 'When businesses in Modiin add offers, they will appear here.')}</p>
            </div>
          ) : (
            <>
              {(folded ? phoneList.slice(0, FOLDED) : phoneList).map((d) => <MDealCard key={d.id} deal={d} lang={lang} />)}
              {folded && (
                <div className="relative h-[222px] overflow-hidden">
                  <div className="pointer-events-none" aria-hidden><MDealCard deal={phoneList[FOLDED]} lang={lang} /></div>
                  <div className="absolute inset-0" style={{ background: 'linear-gradient(to bottom, rgba(255,255,255,0), #fff 98%)' }} />
                  <div className="absolute inset-x-0 bottom-[18px] flex justify-center">
                    <button type="button" onClick={() => setExpanded(true)} className="rounded-[60px] border border-midblue bg-white px-6 py-2 text-sm font-medium leading-6 text-midblue">
                      {t('ראה הכל', 'View All')}
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </section>

      {/* ── Most Popular Brands ── */}
      {brands.length > 0 && (
        <>
          <section className="wrap hidden pt-[70px] desk:block">
            <h2 className="font-nunito text-[28px] font-semibold leading-[1.21] text-midblue">{t('המותגים הפופולריים', 'Most Popular Brands')}</h2>
            <div className="mt-6 grid grid-cols-5 gap-[25px]">
              {brands.slice(0, 10).map(([id, list]) => (
                <BrandTile key={id} deals={list} lang={lang} selected={business === id} big
                  link={list.length === 1 ? dealHref[list[0].id] : null} onPick={() => pickBrand(id, false)} />
              ))}
            </div>
          </section>
          <section className="px-4 pt-8 desk:hidden">
            <h2 className="text-base font-semibold text-[#1F1F1F]">{t('המותגים הפופולריים', 'Most Popular Brands')}</h2>
            <div className="mt-[18px] grid grid-cols-2 gap-3">
              {phoneBrands.slice(0, 8).map(([id, list]) => (
                <BrandTile key={id} deals={list} lang={lang} selected={business === id}
                  link={list.length === 1 ? dealHref[list[0].id] : null} onPick={() => pickBrand(id, true)} />
              ))}
            </div>
          </section>
        </>
      )}
      <div className="h-10 desk:h-[146px]" />
    </div>
  );
}

function HeaderArrow({ back = false, onClick }: { back?: boolean; onClick: () => void }) {
  return (
    <button type="button" onClick={onClick} aria-label={back ? '‹' : '›'} className="flex size-10 items-center justify-center rounded-full border border-line bg-white">
      <img src="/web/deals/arrow20.svg" alt="" className={`size-5 ${back ? 'ltr:-scale-x-100' : 'rtl:-scale-x-100'}`} />
    </button>
  );
}

function Notice({ lang, narrowed, onClear }: { lang: Lang; narrowed: boolean; onClear: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <div className="flex h-[353px] flex-col items-center justify-center rounded-xl border border-line px-8 text-center">
      <DiscountShape size={44} color="rgba(95,94,90,0.5)" />
      <p className="mt-4 text-lg font-semibold text-[#1C1C1E]">{narrowed ? t('אין מבצעים מתאימים', 'No deals match') : t('אין עדיין מבצעים', 'No deals yet')}</p>
      <p className="mt-2 max-w-[520px] text-sm leading-normal text-gray-text">
        {narrowed ? t('נקו את הסינון כדי לראות את כל המבצעים.', 'Clear the filter to see every deal running now.')
          : t('עסקים מקומיים עדיין לא פרסמו הטבות. ההטבות יופיעו כאן כשיפורסמו.', 'Local businesses have not published an offer yet. They will show up here when they do.')}
      </p>
      {narrowed && (
        <button type="button" onClick={onClear} className="mt-6 h-11 rounded-[60px] bg-midblue px-8 text-base font-medium text-white">
          {t('הצג את כל המבצעים', 'Show all deals')}
        </button>
      )}
    </div>
  );
}

/** A business behind the deals: the pink strip with its best discount, its
 *  logo (its name where it has none), and the button. One deal opens it;
 *  several narrow the deals to them. */
function BrandTile({ deals, lang, selected, big = false, link, onPick }: {
  deals: Deal[]; lang: Lang; selected: boolean; big?: boolean; link: string | null; onPick: () => void;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const first = deals[0];
  const name = businessName(first, lang) ?? '';
  const logo = first.business?.logo;
  const strip = brandStrip(deals, lang);
  const n = deals.length;
  const body: ReactNode = (
    <>
      <span dir={isHebrew(strip) ? 'rtl' : 'ltr'} className="block w-full truncate bg-[#FFE6E6] px-2 py-2 text-center text-sm font-medium leading-[1.21] text-[#E90052]">{strip}</span>
      <span className="flex min-h-0 flex-1 flex-col p-3">
        <span className="flex min-h-0 flex-1 items-center justify-center">
          {logo
            ? <img src={logo} alt={name} loading="lazy" className={`object-contain ${big ? 'max-h-24 max-w-[204px]' : 'max-h-14 max-w-[120px]'}`} />
            : <span dir={isHebrew(name) ? 'rtl' : 'ltr'} className={`line-clamp-2 text-center font-nunito font-semibold leading-[1.2] text-navy ${big ? 'text-2xl' : 'text-lg'}`}>{name}</span>}
        </span>
        <span className={`flex w-full items-center justify-center rounded-[60px] bg-midblue font-medium text-white ${big ? 'h-11 text-base leading-6' : 'px-3 py-2 text-xs leading-6'}`}>
          {n === 1 ? t('צפו במבצע', 'View Deal') : t(`צפו ב־${n} מבצעים`, `View ${n} Deals`)}
        </span>
      </span>
    </>
  );
  const cls = `flex flex-col overflow-hidden rounded-xl border bg-white transition-colors ${big ? 'h-[210px]' : 'h-[174px]'} ${selected ? 'border-midblue' : 'border-line hover:border-midblue'}`;
  return link
    ? <Link href={link} className={cls}>{body}</Link>
    : <button type="button" onClick={onPick} aria-pressed={selected} className={`${cls} w-full`}>{body}</button>;
}
