import type { Metadata } from 'next';
import { Calendar1 } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { href, pageMetadata, SUFFIX } from '@/lib/seo';
import { eventCategories, eventCategoryLinks, upcomingEvents, type EventCard } from '@/lib/data/events';
import { ListMap, type Facet, type ListMapItem } from '@/components/map/ListMap';
import { Photo } from '@/components/events/Photo';
import { address, categoryLabel, dayOfMonth, eventPrice, shortMonth, timeRange } from '@/components/events/labels';

export async function generateMetadata(): Promise<Metadata> {
  // The events list on a map: the list's own page is the one to index.
  return pageMetadata({ path: '/events-map/', title: 'מפת אירועים במודיעין' + SUFFIX, noindex: true });
}

/** One event as the map page lists it (web_events_map_screen.dart): the
 *  date, the title, its time and place, Free. */
function EventRow({ e, lang }: { e: EventCard; lang: Lang }) {
  const t = tr(lang);
  const time = timeRange(e, lang);
  const place = address(e, lang);
  const price = eventPrice(e, lang);
  return (
    <div className="flex gap-4">
      {e.start_date ? (
        <span className="flex h-[72px] w-16 shrink-0 flex-col items-center justify-center rounded-xl bg-[#F3EEFF] text-[#7B2FF7]">
          <span className="text-2xl font-semibold leading-none">{dayOfMonth(e.start_date, false)}</span>
          <span className="mt-1 text-xs">{shortMonth(e.start_date, lang)}</span>
        </span>
      ) : <Photo url={e.image} alt="" className="h-[72px] w-16 shrink-0 rounded-xl" icon={Calendar1} iconSize={22} />}
      <span className="min-w-0 flex-1">
        <span className="block truncate font-nunito text-base font-semibold text-navy">{e.title}</span>
        {time && <span className="mt-1 block truncate text-xs text-[#3D3D3D]"><span dir="ltr">{time}</span></span>}
        {place && <span className="mt-1 block truncate text-xs text-[#3D3D3D]">{place}</span>}
        <span className="mt-2 flex gap-2">
          {price && <span className={`rounded-md px-2 py-0.5 text-xs font-medium ${e.is_free ? 'bg-[#E8F8EF] text-[#1E9E5A]' : 'bg-surface text-navy'}`}>{price}</span>}
          {e.is_online && <span className="rounded-md bg-surface px-2 py-0.5 text-xs text-navy">{t('אונליין', 'Online')}</span>}
        </span>
      </span>
    </div>
  );
}

/** /events-map/ — the upcoming events on the city map (the current site's
 *  "View on Map" from the events list), with the list beside it. */
export default async function EventsMapPage({ searchParams }: { searchParams: Promise<Record<string, string | string[] | undefined>> }) {
  const sp = await searchParams;
  const lang = await getLang();
  const t = tr(lang);
  const [events, categories, links] = await Promise.all([upcomingEvents(), eventCategories(), eventCategoryLinks()]);
  const used = categories.filter((c) => events.some((e) => (links[e.id] ?? []).some((x) => x.id === c.id)));
  const facets: Facet[] = [
    { id: 'cat', title: t('קטגוריה', 'Category'), options: used.map((c) => ({ value: c.slug, label: categoryLabel(c, lang) })) },
    { id: 'price', title: t('מחיר', 'Price'), single: true, options: [{ value: 'free', label: t('חינם', 'Free') }, { value: 'paid', label: t('בתשלום', 'Paid') }] },
  ];
  const items: ListMapItem[] = events.map((e) => {
    const onMap = !e.is_online && e.latitude != null && e.longitude != null;
    return {
      id: e.id, href: href(`/event/${e.id}/`), title: e.title,
      lat: onMap ? e.latitude : null, lng: onMap ? e.longitude : null,
      icon: '/web/events/map_pin.svg', size: [40, 43],
      text: [e.title, e.venue_name, e.address].filter(Boolean).join(' ').toLowerCase(),
      tags: [...(links[e.id] ?? []).map((c) => `cat:${c.slug}`), `price:${e.is_free ? 'free' : 'paid'}`],
      sort: { soonest: e.starts ?? Number.MAX_SAFE_INTEGER, newest: -(e.published_at ? Date.parse(e.published_at) : 0) },
      row: <EventRow e={e} lang={lang} />,
      card: <EventRow e={e} lang={lang} />,
    };
  });
  const cat = typeof sp.category === 'string' && used.some((c) => c.slug === sp.category) ? sp.category : null;
  return (
    <ListMap lang={lang} items={items} facets={facets}
      sorts={[{ id: 'soonest', label: t('הקרובים ביותר', 'Soonest') }, { id: 'newest', label: t('החדשים ביותר', 'Newest') }]}
      heading={['{n} אירועים', '{n} Events']} sub={t('במודיעין מכבים רעות', 'in Modiin Maccabim Reut')}
      listHref="/events/" placeholder={t('חיפוש אירועים, הופעות ופעילויות', 'Search events, shows and activities')}
      initial={{ q: typeof sp.q === 'string' ? sp.q : '', picked: cat ? { cat: [cat] } : {} }}
      emptyTitle={t('אין אירועים קרובים', 'No upcoming events')} emptyBody={t('אירועים חדשים יופיעו כאן עם פרסומם.', 'New events will appear here as they are published.')} />
  );
}
