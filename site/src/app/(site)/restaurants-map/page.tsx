import type { Metadata } from 'next';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { href, pageMetadata, SUFFIX } from '@/lib/seo';
import {
  BARS_KEY, bizName, bizPhoto, businessCategories, catName, foodPlaces, kosherLabel, sizedPhoto, type FoodPlace,
} from '@/lib/data/businesses';
import { ListMap, type Facet, type ListMapItem } from '@/components/map/ListMap';
import { Photo } from '@/components/businesses/Photo';
import { Rating } from '@/components/businesses/BusinessCard';

export async function generateMetadata(): Promise<Metadata> {
  // The restaurants on a map: /search-rest-modiin/ and the category pages are the
  // ones to index.
  return pageMetadata({ path: '/restaurants-map/', title: 'מפת מסעדות במודיעין' + SUFFIX, noindex: true });
}

/** A place as the map page lists it (web_restaurants_map_screen.dart): its
 *  photograph, name, line, rating, address and cuisine. */
function PlaceRow({ p, lang, kind }: { p: FoodPlace; lang: Lang; kind: string }) {
  const t = tr(lang);
  const b = p.business;
  const cuisine = p.cuisine ? catName(p.cuisine, lang) : null;
  return (
    <div className="flex gap-4">
      <Photo src={sizedPhoto(bizPhoto(b), 400)} alt="" className="h-[92px] w-[120px] shrink-0 rounded-xl" icon={28} />
      <span className="min-w-0 flex-1">
        <span dir="auto" className="block truncate font-nunito text-base font-semibold text-navy">{bizName(b, lang)}</span>
        <span className="mt-1 block truncate text-xs text-gray-text">{kind}{cuisine ? ` · ${cuisine}` : ''}</span>
        <span className="mt-1.5 block"><Rating rating={Number(b.rating ?? 0)} reviews={b.review_count ?? 0} rated={Number(b.rating ?? 0) > 0 || (b.review_count ?? 0) > 0} lang={lang} /></span>
        {b.address && <span dir="auto" className="mt-1.5 block truncate text-xs text-[#3D3D3D]">{b.address}</span>}
        <span className="mt-2 flex gap-2">
          {kosherLabel(b.kosher_level) && <span className="rounded-md bg-surface px-2 py-0.5 text-xs text-navy">{t('כשר', 'Kosher')}</span>}
          {b.has_delivery && <span className="rounded-md bg-surface px-2 py-0.5 text-xs text-navy">{t('משלוחים', 'Delivery')}</span>}
        </span>
      </span>
    </div>
  );
}

/** /restaurants-map/ — every place to eat and drink on the city map, with
 *  the current site's filters: cuisine, kosher, rating, delivery. Opened
 *  from the Restaurants page's "View on Map"; `?q=`, `?cuisine=a,b` and
 *  `?sort=rating` carry over as on the current site. */
export default async function RestaurantsMapPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const lang = await getLang();
  const t = tr(lang);
  const [places, cats] = await Promise.all([foodPlaces(true), businessCategories()]);
  const restaurants = cats.find((c) => c.slug === 'restaurants');
  const cuisines = cats.filter((c) => (c.slug === 'cafe-bakery' || c.slug === 'restaurants' || (!!restaurants && c.parent_id === restaurants.id))
    && places.some((p) => p.slugs.has(c.slug)));
  const kindLabel = (k: FoodPlace['kind']) => k === 'cafe' ? t('בית קפה', 'Cafe') : k === 'bar' ? t('בר', 'Bar') : t('מסעדה', 'Restaurant');

  const facets: Facet[] = [
    {
      id: 'cuisine', title: t('מטבח', 'Cuisine'), options: [
        ...cuisines.map((c) => ({ value: c.slug, label: catName(c, lang) })),
        ...(places.some((p) => p.slugs.has(BARS_KEY)) ? [{ value: BARS_KEY, label: t('ברים', 'Bars') }] : []),
      ],
    },
    { id: 'kosher', title: t('כשרות', 'Kosher'), single: true, options: [{ value: 'yes', label: t('כשר', 'Kosher') }, { value: 'no', label: t('לא כשר', 'Not kosher') }] },
    { id: 'rating', title: t('דירוג', 'Rating'), single: true, options: [4, 3, 2, 1].map((n) => ({ value: String(n), label: t(`${n}★ ומעלה`, `${n}★ & up`) })) },
    ...(places.some((p) => p.business.has_delivery) ? [{ id: 'dining', title: t('אופן הגשה', 'Dining'), options: [{ value: 'delivery', label: t('משלוחים', 'Delivery') }] }] : []),
  ];

  const items: ListMapItem[] = places.map((p, i) => {
    const b = p.business;
    const rating = Number(b.rating ?? 0);
    const row = <PlaceRow p={p} lang={lang} kind={kindLabel(p.kind)} />;
    return {
      id: b.id, href: href(`/business/${b.slug || b.id}/`), title: bizName(b, lang),
      lat: b.latitude, lng: b.longitude,
      icon: '/web/restaurants/map_pin.svg', size: [40, 43],
      text: [b.name, b.name_en, b.short_description, b.address, ...[...p.slugs].map((s) => cats.find((c) => c.slug === s)).filter(Boolean).map((c) => catName(c!, lang))]
        .filter(Boolean).join(' ').toLowerCase(),
      tags: [
        ...[...p.slugs].map((s) => `cuisine:${s}`),
        `kosher:${kosherLabel(b.kosher_level) ? 'yes' : 'no'}`,
        ...[1, 2, 3, 4].filter((n) => rating >= n).map((n) => `rating:${n}`),
        ...(b.has_delivery ? ['dining:delivery'] : []),
      ],
      sort: { newest: i, rating: -rating * 10000 - (b.review_count ?? 0), name: 0 },
      row, card: row,
    };
  });
  // By name: the order of the names in the page's language.
  [...items].sort((a, b) => a.title.localeCompare(b.title, lang)).forEach((it, i) => { it.sort.name = i; });

  const one = (v: string | string[] | undefined) => (typeof v === 'string' ? v : '');
  const wanted = one(sp.cuisine).split(',').filter((s) => facets[0].options.some((o) => o.value === s));
  return (
    <ListMap lang={lang} items={items} facets={facets}
      sorts={[{ id: 'newest', label: t('החדשים ביותר', 'Newest') }, { id: 'rating', label: t('דירוג', 'Rating') }, { id: 'name', label: t('שם', 'Name') }]}
      heading={['{n} מסעדות', '{n} Restaurant Listings']} sub={t('במודיעין מכבים רעות', 'in Modiin Maccabim Reut')}
      listHref="/search-rest-modiin/" placeholder={t('חיפוש מסעדה, מטבח או מקום', 'Search restaurant, cuisine or place')}
      initial={{ q: one(sp.q), picked: { ...(wanted.length ? { cuisine: wanted } : {}), ...(one(sp.dining) === 'delivery' ? { dining: ['delivery'] } : {}) }, sort: one(sp.sort) === 'rating' ? 'rating' : 'newest' }}
      emptyTitle={t('עדיין אין מסעדות', 'No restaurants yet')} emptyBody={t('מקומות חדשים יופיעו כאן כשיתווספו.', 'New places will appear here as they are added.')} />
  );
}
