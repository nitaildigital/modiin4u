import type { Metadata } from 'next';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { href, pageMetadata, SUFFIX } from '@/lib/seo';
import { activeListings, activeNeighborhoods, localName, type Listing } from '@/lib/data/realestate';
import { ListMap, type Facet, type ListMapItem } from '@/components/map/ListMap';
import { ListingPhoto } from '@/components/realestate/ListingCard';
import { BROWSE_TYPES, hoodName, kindLabel, priceOf, roomsText, shekels, typeLabel } from '@/components/realestate/format';
import { readSearch, searchHref } from '@/components/realestate/search';

export async function generateMetadata(): Promise<Metadata> {
  // The listings on a map: /search-apartments/ and its searches are the pages to index.
  return pageMetadata({ path: '/realestate-map/', title: 'מפת נדל״ן במודיעין' + SUFFIX, noindex: true });
}

/** A listing as the map page lists it (web_realestate_map_screen.dart): its
 *  photograph, price, title, rooms and size, and where. */
function ListingRow({ l, lang }: { l: Listing; lang: Lang }) {
  const t = tr(lang);
  const price = priceOf(l);
  const facts = [
    typeLabel(l.property_type, lang),
    l.rooms != null ? t(`${roomsText(l.rooms)} חדרים`, `${roomsText(l.rooms)} rooms`) : null,
    l.sqm != null ? t(`${l.sqm} מ״ר`, `${l.sqm} m²`) : null,
  ].filter(Boolean).join(' · ');
  return (
    <div className="flex gap-4">
      <ListingPhoto url={l.cover_url} width={400} alt="" className="h-[92px] w-[120px] shrink-0 rounded-xl" iconSize={28} />
      <span className="min-w-0 flex-1">
        <span className="flex items-center gap-2">
          <span className="font-nunito text-lg font-semibold text-midblue">
            {price != null ? shekels(price) + (l.kind === 'rent' ? t(' לחודש', ' / month') : '') : t('מחיר לפי בקשה', 'Price on request')}
          </span>
          <span className="rounded-full bg-surface px-2 py-0.5 text-[11px] text-navy">{kindLabel(l.kind, lang, false)}</span>
        </span>
        <span dir="auto" className="mt-1 block truncate text-sm font-medium text-navy">{l.title}</span>
        {facts && <span className="mt-1 block truncate text-xs text-gray-text">{facts}</span>}
        {(l.address || hoodName(l, lang)) && <span dir="auto" className="mt-1 block truncate text-xs text-[#3D3D3D]">{l.address || hoodName(l, lang)}</span>}
      </span>
    </div>
  );
}

/** /realestate-map/ — the active listings on the city map (the phone list's
 *  "View on Map"), with search and the phone filter sheet's choices: sale
 *  or rent, type, neighbourhood, rooms. A real estate search's fields carry
 *  over (`?kind=&type=&neighborhood=&rooms=&q=`). */
export default async function RealEstateMapPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const s = readSearch(sp);
  const lang = await getLang();
  const t = tr(lang);
  const [all, hoods] = await Promise.all([activeListings(), activeNeighborhoods()]);
  const usedHoods = hoods.filter((h) => all.some((l) => l.neighborhood_id === h.id));
  const usedTypes = BROWSE_TYPES.map(([ty]) => ty).filter((ty) => all.some((l) => l.property_type === ty));

  const facets: Facet[] = [
    { id: 'kind', title: t('סוג עסקה', 'Deal'), single: true, options: [{ value: 'sale', label: t('למכירה', 'For Sale') }, { value: 'rent', label: t('להשכרה', 'For Rent') }] },
    { id: 'type', title: t('סוג נכס', 'Property type'), options: usedTypes.map((ty) => ({ value: ty, label: typeLabel(ty, lang) })) },
    { id: 'rooms', title: t('חדרים', 'Rooms'), single: true, options: [1, 2, 3, 4, 5].map((n) => ({ value: String(n), label: t(`${n}+ חדרים`, `${n}+ rooms`) })) },
    ...(usedHoods.length ? [{ id: 'hood', title: t('שכונה', 'Neighborhood'), options: usedHoods.map((h) => ({ value: h.id, label: localName(h.name, h.name_en, lang) })) }] : []),
  ];

  const items: ListMapItem[] = all.map((l, i) => {
    const price = priceOf(l);
    const row = <ListingRow l={l} lang={lang} />;
    return {
      id: l.id, href: href(`/listing/${l.id}/`), title: l.title,
      lat: l.latitude, lng: l.longitude, icon: '/web/realestate/listing_pin.svg', size: [40, 44],
      text: [l.title, l.address, l.neighborhoods?.name, l.neighborhoods?.name_en].filter(Boolean).join(' ').toLowerCase(),
      tags: [
        `kind:${l.kind}`, `type:${l.property_type}`,
        ...[1, 2, 3, 4, 5].filter((n) => (l.rooms ?? 0) >= n).map((n) => `rooms:${n}`),
        ...(l.neighborhood_id ? [`hood:${l.neighborhood_id}`] : []),
      ],
      // A listing with no price sorts last either way.
      sort: { newest: i, 'price-low': price ?? Number.MAX_SAFE_INTEGER, 'price-high': price != null ? -price : Number.MAX_SAFE_INTEGER },
      row, card: row,
    };
  });

  return (
    <ListMap lang={lang} items={items} facets={facets}
      sorts={[{ id: 'newest', label: t('החדשים ביותר', 'Newest') }, { id: 'price-low', label: t('מחיר: מהנמוך', 'Price: low to high') }, { id: 'price-high', label: t('מחיר: מהגבוה', 'Price: high to low') }]}
      heading={['{n} נכסים', '{n} Properties']} sub={t('במודיעין מכבים רעות', 'in Modiin Maccabim Reut')}
      listHref={searchHref(s)} placeholder={t('חיפוש לפי מיקום, שכונה...', 'Search by location, neighborhood...')}
      initial={{
        q: s.q, sort: s.sort,
        picked: {
          ...(s.kind ? { kind: [s.kind] } : {}), ...(s.types.length ? { type: s.types } : {}),
          ...(s.rooms.length ? { rooms: [String(Math.min(...s.rooms))] } : {}), ...(s.neighborhood ? { hood: [s.neighborhood] } : {}),
        },
      }}
      emptyTitle={t('אין מודעות כרגע', 'No listings right now')} emptyBody={t('כשתפורסמנה דירות במודיעין, הן יופיעו כאן.', 'When apartments are posted in Modiin, they will appear here.')} />
  );
}
