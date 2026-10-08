import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, wpPage, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { eventCategories, eventCategoryLinks, upcomingEvents } from '@/lib/data/events';
import { JsonLd } from '@/components/JsonLd';
import { EventsHome } from '@/components/events/EventsHome';
import { EventsCategoryBrowser } from '@/components/events/EventsCategoryBrowser';

const PATH = '/events/';
// The page's name, as the website's hero prints it.
const NAME_HE = 'אירועים וחיי לילה במודיעין';
const NAME_EN = 'Events & Nightlife in Modiin';

type Props = { searchParams: Promise<Record<string, string | string[] | undefined>> };

export async function generateMetadata(): Promise<Metadata> {
  // A category view (`?category=`) is this page narrowed, so it shares the
  // page's address, title and description.
  return pageMetadata({
    path: PATH,
    title: NAME_HE + SUFFIX,
    description: 'גלו הופעות, אירועי קהילה, חיי לילה, פעילויות למשפחה ועוד — הכל סביב מודיעין.',
    image: SITE_URL + '/web/events/hero.webp',
  });
}

/** The events page (web_events_screen.dart / events_screen.dart): every
 *  upcoming event, as the app lists them. With `?category=all|free|<slug>`
 *  the website opens the category browser (web_events_category_screen.dart)
 *  and the phone its list narrowed to that circle. */
export default async function EventsPage({ searchParams }: Props) {
  const sp = await searchParams;
  const category = typeof sp.category === 'string' ? sp.category.trim() : '';
  const lang = await getLang();
  const t = tr(lang);
  const [events, categories, links] = await Promise.all([upcomingEvents(), eventCategories(), eventCategoryLinks()]);
  // Only the links of the events on the page travel to the browser.
  const byEvent = Object.fromEntries(events.filter((e) => links[e.id]).map((e) => [e.id, links[e.id]]));
  const heading = h1For(PATH, t(NAME_HE, NAME_EN));

  return (
    <>
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'ItemList', name: NAME_HE, url: SITE_URL + href(PATH),
          itemListElement: events.map((e, i) => ({ '@type': 'ListItem', position: i + 1, url: SITE_URL + href(`/event/${e.id}/`), name: e.title })),
        },
        breadcrumb([[SITE_NAME, '/'], [NAME_HE, PATH]]),
      ]} />
      {category ? (
        <>
          <EventsCategoryBrowser lang={lang} events={events} categories={categories} byEvent={byEvent}
            initialFilter={category} headingOverride={wpPage(PATH)?.h1}
            eventHref={Object.fromEntries(events.map((e) => [e.id, href(`/event/${e.id}/`)]))} />
          <EventsHome lang={lang} heading={heading} headingIsH1={false} events={events} categories={categories}
            byEvent={byEvent} initialFilter={category} phoneOnly />
        </>
      ) : (
        <EventsHome lang={lang} heading={heading} headingIsH1 events={events} categories={categories}
          byEvent={byEvent} initialFilter="all" />
      )}
    </>
  );
}
