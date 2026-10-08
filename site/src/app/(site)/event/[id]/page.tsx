import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowLeft, Calendar1, CalendarAdd, Clock, Location, People, Shop } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { slugParam } from '@/lib/params';
import { pageMetadata, h1For, plain, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import {
  eventById, eventCategoryLinks, eventOrganizer, hasCoordinates, israelIso, upcomingEvents,
  type EventDetail,
} from '@/lib/data/events';
import { JsonLd } from '@/components/JsonLd';
import { MapView } from '@/components/map/MapView';
import { Photo } from '@/components/events/Photo';
import { MEventCard, WebEventCard, CategoryPill } from '@/components/events/EventCards';
import { ShareMenu } from '@/components/events/ShareMenu';
import { Carousel } from '@/components/events/Carousel';
import {
  address, categoryLabel, dayOfMonth, eventPrice, longDate, parseDescription, peopleInterested, shortMonth, timeRange, venue,
} from '@/components/events/labels';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const id = slugParam((await params).id);
  const e = await eventById(id);
  if (!e) return {};
  return pageMetadata({
    path: `/event/${id}/`,
    title: e.seo_title || (e.title + SUFFIX),
    description: e.meta_description || plain(e.short_description || e.full_description, 160),
    image: e.og_image || e.image,
    noindex: !!e.noindex,
    publishedTime: e.published_at,
    modifiedTime: e.updated_at,
    ogTitle: e.og_title,
    ogDescription: e.og_description,
    keywords: e.meta_keywords,
  });
}

/** Directions to the venue: the editor's Waze link where the row has one,
 *  Google Maps to the coordinates otherwise. */
function directionsUrl(e: EventDetail): string | null {
  if (e.waze_url?.trim()) return e.waze_url.trim();
  if (!hasCoordinates(e)) return null;
  return `https://www.google.com/maps/dir/?api=1&destination=${e.latitude},${e.longitude}`;
}

/** Google Calendar's "new event" page filled in (event_calendar.dart): the
 *  times as Israel's clock shows them with the zone named; no time means a
 *  whole day; no end time ends when it starts. */
function calendarUrl(e: EventDetail, details: string): string | null {
  if (!e.start_date) return null;
  const date = (d: string) => d.slice(0, 10).replace(/-/g, '');
  const nextDay = (d: string) => {
    const [y, m, dd] = d.slice(0, 10).split('-').map(Number);
    return new Date(Date.UTC(y, m - 1, dd + 1)).toISOString().slice(0, 10);
  };
  const time = (raw: string | null) => {
    const p = (raw ?? '').split(':');
    return p.length < 2 ? null : [Number(p[0]), Number(p[1])] as const;
  };
  const two = (n: number) => String(n).padStart(2, '0');
  const lastDay = e.end_date ?? e.start_date;
  const from = time(e.start_time);
  let dates: string;
  if (e.is_all_day || !from) {
    dates = `${date(e.start_date)}/${date(nextDay(lastDay))}`;
  } else {
    const to = time(e.end_time) ?? from;
    // 21:00–01:00 on one date runs past midnight.
    const endDay = !e.end_date && to[0] * 60 + to[1] < from[0] * 60 + from[1] ? nextDay(e.start_date) : lastDay;
    dates = `${date(e.start_date)}T${two(from[0])}${two(from[1])}00/${date(endDay)}T${two(to[0])}${two(to[1])}00`;
  }
  const place = [e.venue_name?.trim(), e.address?.trim()].filter(Boolean).join(', ');
  const q = new URLSearchParams({ action: 'TEMPLATE', text: e.title, dates, ctz: 'Asia/Jerusalem' });
  if (place) q.set('location', place);
  if (details) q.set('details', details);
  return `https://calendar.google.com/calendar/render?${q}`;
}

/** An event (web_event_detail_screen.dart above 1100, event_detail_screen.dart
 *  below): the photograph with the date, title and where and when; what it
 *  is about, the details, what is included and the map; the invitation card
 *  with Share and Add to calendar; and other upcoming events. Going needs an
 *  account, which is the app's, so the site has no RSVP. */
export default async function EventPage({ params }: Props) {
  const id = slugParam((await params).id);
  const e = await eventById(id);
  if (!e) notFound();
  const lang = await getLang();
  const t = tr(lang);
  const path = `/event/${id}/`;
  const url = SITE_URL + href(path);
  const [links, upcoming, organizer] = await Promise.all([eventCategoryLinks(), upcomingEvents(), eventOrganizer(e.business_id, lang)]);
  const mine = links[e.id] ?? [];
  const category = mine[0];
  const about = parseDescription(e.full_description?.trim() ? e.full_description : e.short_description);
  const time = timeRange(e, lang);
  const directions = directionsUrl(e);
  const calendar = calendarUrl(e, url);
  const image = e.image || e.og_image;
  const shareMessage = [e.title, e.start_date ? longDate(e.start_date, lang) : null, venue(e, lang)].filter(Boolean).join('\n');

  // Other upcoming events, those sharing this one's category first.
  const shares = (x: { id: string }) => (links[x.id] ?? []).some((c) => mine.some((m) => m.id === c.id));
  const others = upcoming.filter((x) => x.id !== e.id);
  const related = [...others.filter(shares), ...others.filter((x) => !shares(x))];
  const firstCategory = (x: { id: string }) => {
    const c = (links[x.id] ?? [])[0];
    return c ? categoryLabel(c, lang) : null;
  };

  const desc = plain(about.paragraphs.join('\n') || e.short_description, 500);
  const endIso = e.end_date || e.end_time ? israelIso(e.end_date ?? e.start_date!, e.is_all_day ? null : e.end_time) : null;
  const offerPrice = e.is_free ? 0 : e.price ? Number(e.price) : null;

  return (
    <article>
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'Event', name: e.title, url,
          ...(e.start_date ? { startDate: israelIso(e.start_date, e.is_all_day ? null : e.start_time) } : {}),
          ...(endIso ? { endDate: endIso } : {}),
          eventStatus: 'https://schema.org/EventScheduled',
          eventAttendanceMode: e.is_online ? 'https://schema.org/OnlineEventAttendanceMode' : 'https://schema.org/OfflineEventAttendanceMode',
          location: e.is_online
            ? { '@type': 'VirtualLocation', ...(e.online_url ? { url: e.online_url } : {}) }
            : {
              '@type': 'Place', name: e.venue_name || e.address || undefined,
              ...(e.address || e.venue_name ? { address: e.address || e.venue_name } : {}),
              ...(hasCoordinates(e) ? { geo: { '@type': 'GeoCoordinates', latitude: e.latitude, longitude: e.longitude } } : {}),
            },
          ...(image ? { image: [image] } : {}),
          ...(desc ? { description: desc } : {}),
          ...(offerPrice != null && Number.isFinite(offerPrice) ? {
            offers: {
              '@type': 'Offer', price: offerPrice, priceCurrency: 'ILS', url: e.ticket_url || url,
              availability: e.is_sold_out ? 'https://schema.org/SoldOut' : 'https://schema.org/InStock',
            },
          } : {}),
          ...(organizer ? { organizer: { '@type': 'Organization', name: organizer.name, url: SITE_URL + href(`/business/${organizer.slug}/`) } } : {}),
        },
        breadcrumb([[SITE_NAME, '/'], ['אירועים', '/events/'], [e.title, path]]),
      ]} />

      {/* ── The photograph, with the date, title and where and when: over it
             on the website, under it on the phone ── */}
      <section className="relative desk:h-[550px] desk:overflow-hidden">
        <div className="relative h-[260px] desk:absolute desk:inset-0 desk:h-full">
          <Photo url={image} alt={e.title} className="size-full" icon={Calendar1} iconSize={60} eager />
          <div className="absolute inset-0 desk:hidden" style={{ background: 'linear-gradient(to top, rgba(0,0,0,0.4), rgba(0,0,0,0))' }} />
          <div className="absolute inset-y-0 start-0 hidden w-1/2 desk:block ltr:bg-[linear-gradient(to_right,rgba(0,0,0,0.64)_1.2%,rgba(0,0,0,0.64)_52.3%,rgba(0,0,0,0)_100%)] rtl:bg-[linear-gradient(to_left,rgba(0,0,0,0.64)_1.2%,rgba(0,0,0,0.64)_52.3%,rgba(0,0,0,0)_100%)]" />
        </div>
        {/* The phone's round buttons on the photograph. The heart beside
            them saves to an account, which is the app's. */}
        <Link href="/events/" aria-label={t('חזרה', 'Back')} className="absolute start-3 top-[7px] flex size-10 items-center justify-center rounded-full bg-white text-[#3D3D3D] desk:hidden">
          <span className="rtl:-scale-x-100"><ArrowLeft size={20} color="currentColor" /></span>
        </Link>
        {calendar && (
          <a href={calendar} target="_blank" rel="noopener" aria-label={t('הוספה ליומן', 'Add to calendar')}
            className="absolute end-[124px] top-[7px] flex size-10 items-center justify-center rounded-full bg-white desk:hidden">
            <CalendarAdd size={20} color="#3D3D3D" />
          </a>
        )}
        <div className="absolute end-[68px] top-[7px] desk:hidden">
          <ShareMenu url={url} title={e.title} message={shareMessage} lang={lang} align="end" className="flex size-10 items-center justify-center rounded-full bg-white">
            <img src="/web/events/share20.svg" alt={t('שיתוף', 'Share')} className="size-5 brightness-0 opacity-75" />
          </ShareMenu>
        </div>

        <div className="relative desk:absolute desk:inset-x-0 desk:top-[106px]">
          <div className="desk:mx-auto desk:max-w-[calc(1600px_+_2*clamp(16px,4.5vw,80px))] desk:px-[clamp(16px,4.5vw,80px)]">
            <div className="relative mx-4 flow-root border-b border-line pb-5 desk:mx-0 desk:w-[528px] desk:border-0 desk:pb-0">
              {e.start_date && (
                <span className="relative -mt-[45px] flex w-[81px] flex-col items-center gap-1.5 rounded-[11.4px] border-2 border-midblue bg-white p-[9.4px] desk:mt-0 desk:border-0 desk:p-[11.4px]">
                  <span className="text-lg font-medium leading-[22px] text-midblue">{shortMonth(e.start_date, lang)}</span>
                  <span className="text-[32px] font-semibold leading-[39px] text-black">
                    <span className="desk:hidden">{dayOfMonth(e.start_date, false)}</span>
                    <span className="hidden desk:inline">{dayOfMonth(e.start_date)}</span>
                  </span>
                </span>
              )}
              {category && <CategoryPill label={categoryLabel(category, lang)} className="absolute end-[-3px] top-3 inline-block px-4 py-1.5 text-sm desk:hidden" />}
              <h1 className="mt-5 font-nunito text-[28px] font-semibold leading-[34px] text-black desk:mt-[26px] desk:line-clamp-2 desk:text-5xl desk:leading-[59px] desk:text-white">
                {h1For(path, e.title)}
              </h1>
              {category && <CategoryPill label={categoryLabel(category, lang)} className="mt-3 hidden px-4 py-1.5 text-sm desk:inline-block" />}

              {/* The website's lines, white over the photograph. */}
              <div className="hidden flex-col gap-6 pt-6 desk:flex">
                {time && <HeroMeta icon="/web/events/clock16.svg" text={time} ltr />}
                {address(e, lang) && <HeroMeta icon="/web/events/pin16.svg" text={address(e, lang)!} />}
                {/* The real count, only once there is one. */}
                {e.rsvp_count > 0 && <HeroMeta icon="/web/events/people16.svg" text={peopleInterested(e.rsvp_count, lang)} />}
              </div>

              {/* The phone's: time, the venue with its address, interest, price. */}
              <div className="desk:hidden">
                {time && <PhoneMeta icon={<Clock size={16} color="#888888" />}>{time}</PhoneMeta>}
                {[e.venue_name?.trim(), e.address?.trim()].filter(Boolean).length > 0 && (
                  <PhoneMeta icon={<Location size={16} color="#888888" />}>{[e.venue_name?.trim(), e.address?.trim()].filter(Boolean).join(', ')}</PhoneMeta>
                )}
                {e.rsvp_count > 0 && (
                  <PhoneMeta icon={<People size={16} color="#888888" />}>
                    <span className="text-black">{e.rsvp_count}</span>{e.rsvp_count === 1 ? t(' מתעניין', ' person interested') : t(' מתעניינים', ' people interested')}
                  </PhoneMeta>
                )}
                {eventPrice(e, lang, false) && (
                  <p className="mt-4 flex items-baseline gap-1">
                    <span className="font-nunito text-[28px] font-semibold leading-[34px] text-black">{eventPrice(e, lang, false)}</span>
                    <span className="text-sm text-[#6D6D6D]">{t('מחיר', 'Price')}</span>
                  </p>
                )}
              </div>
            </div>
          </div>
        </div>

        <div className="absolute inset-x-0 bottom-7 hidden desk:block">
          <div className="mx-auto flex max-w-[calc(1600px_+_2*clamp(16px,4.5vw,80px))] justify-end px-[clamp(16px,4.5vw,80px)]">
            <ShareMenu url={url} title={e.title} message={shareMessage} lang={lang} align="end"
              className="flex h-9 items-center gap-2 rounded-[60px] bg-white/90 px-4 text-sm font-medium leading-6 text-navy">
              <img src="/web/events/share16.svg" alt="" className="size-4" />{t('שיתוף', 'Share')}
            </ShareMenu>
          </div>
        </div>
      </section>

      {/* ── What it is, where it is; on the website the invitation beside ── */}
      <div className="desk:mx-auto desk:flex desk:max-w-[calc(1600px_+_2*clamp(16px,4.5vw,80px))] desk:items-start desk:justify-between desk:gap-10 desk:px-[clamp(16px,4.5vw,80px)] desk:pt-14">
        <div className="min-w-0 desk:max-w-[1011px] desk:flex-1">
          {organizer && (
            <section className="mx-4 mt-5 desk:hidden">
              <h2 className="text-base font-semibold text-[#1F1F1F]">{t('מארגנים', 'Organized by')}</h2>
              <Link href={href(`/business/${organizer.slug}/`)} className="mt-3 flex items-center gap-3 rounded-xl bg-[#F6F6F6] p-3">
                <Photo url={organizer.logo} alt="" className="size-10 shrink-0 rounded-full" icon={Shop} iconSize={18} />
                <span className="min-w-0">
                  <span className="block truncate text-sm font-medium text-black">{organizer.name}</span>
                  {organizer.subtitle && <span className="mt-1 block truncate text-xs text-[#6D6D6D]">{organizer.subtitle}</span>}
                </span>
              </Link>
            </section>
          )}

          {about.paragraphs.length > 0 && (
            <section className="mx-4 mt-8 desk:mx-0 desk:mb-14 desk:mt-0">
              <SectionTitle>{t('על האירוע', 'About This Event')}</SectionTitle>
              {about.paragraphs.map((p, i) => (
                <p key={i} className="mt-3 max-w-[896px] whitespace-pre-line text-sm leading-[1.6] text-[#3D3D3D] desk:mt-6 desk:text-base">{p}</p>
              ))}
            </section>
          )}

          <DetailsBox e={e} lang={lang} directions={directions} />

          {about.included.length > 0 && (
            <section className="mx-4 mt-8 desk:mx-0 desk:mt-14">
              <SectionTitle>{t('מה כלול', "What's Included")}</SectionTitle>
              <ul className="mt-5 flex flex-col gap-3.5 desk:mt-6">
                {about.included.map((item, i) => (
                  <li key={i} className="flex items-start gap-2 text-base leading-[19px] text-[#3D3D3D]">
                    <img src="/web/events/included_check.svg" alt="" className="mt-[1.5px] size-4 shrink-0" />{item}
                  </li>
                ))}
              </ul>
            </section>
          )}

          {hasCoordinates(e) && (
            <section className="mx-4 mt-8 desk:mx-0 desk:mt-14">
              <SectionTitle>{t('איפה זה?', 'Where Is It?')}</SectionTitle>
              <div className="relative isolate mt-4 h-[230px] overflow-hidden rounded-xl desk:mt-6 desk:h-[320px] desk:max-w-[720px] desk:rounded-2xl">
                <MapView pins={[]} center={[e.latitude!, e.longitude!]} zoom={15} interactive={false} fit={false} lang={lang} />
                {/* The venue's pin over the centre, which is the venue, tip down on the spot. */}
                <img src="/icons/m_events_pin.svg" alt="" className="pointer-events-none absolute left-1/2 top-1/2 z-[1000] h-[52px] w-12 -translate-x-1/2 -translate-y-full desk:hidden" />
                <img src="/web/events/map_pin.svg" alt="" className="pointer-events-none absolute left-1/2 top-1/2 z-[1000] hidden h-[52px] w-12 -translate-x-1/2 -translate-y-full desk:block" />
                {directions && (
                  <a href={directions} target="_blank" rel="noopener" aria-label={t('הצג במפה', 'View on Map')} className="absolute inset-0 z-[1001] flex items-end justify-center pb-[17px]">
                    <span className="flex h-10 items-center gap-1.5 rounded-[50px] bg-white px-4 text-sm font-medium text-navy shadow-[0_4px_4px_rgba(0,0,0,0.15)] desk:hidden">
                      <img src="/icons/m_events_map.svg" alt="" className="size-4" />{t('הצג במפה', 'View on Map')}
                    </span>
                  </a>
                )}
              </div>
            </section>
          )}
        </div>

        {/* "You're Invited!" — I'm Going and Save need an account, which is
            the app's; the card says what, when and where, and Share. */}
        <aside className="hidden w-[clamp(380px,28.9375%,463px)] shrink-0 rounded-2xl border border-line bg-white p-6 shadow-[0_0_8px_rgba(0,0,0,0.1)] desk:block">
          <p className="font-nunito text-2xl font-semibold leading-[30px] text-midblue">{t('אתם מוזמנים!', "You're Invited!")}</p>
          <Photo url={image} alt="" className="mt-[15px] h-[180px] w-full rounded-xl" icon={Calendar1} iconSize={34} />
          <p className="mt-4 text-[22px] font-semibold leading-[27px] text-black">{e.title}</p>
          {time && <CardMeta icon="/web/events/clock16.svg" text={time} ltr />}
          {address(e, lang) && <CardMeta icon="/web/events/pin16.svg" text={address(e, lang)!} />}
          {e.rsvp_count > 0 && <CardMeta icon="/web/events/people16.svg" text={peopleInterested(e.rsvp_count, lang)} />}
          <div className="mt-6">
            <ShareMenu url={url} title={e.title} message={shareMessage} lang={lang}
              className="flex h-11 w-full items-center justify-center gap-2 rounded-[60px] border border-midblue bg-white px-6 text-base font-medium leading-6 text-midblue">
              <img src="/web/events/share20.svg" alt="" className="size-5" />{t('שיתוף', 'Share')}
            </ShareMenu>
          </div>
          {calendar && (
            <a href={calendar} target="_blank" rel="noopener"
              className="mt-3 flex h-11 w-full items-center justify-center gap-2 rounded-[60px] border border-midblue bg-white px-6 text-base font-medium leading-6 text-midblue">
              <img src="/web/events/det_date.svg" alt="" className="size-5" />{t('הוספה ליומן', 'Add to calendar')}
            </a>
          )}
          {organizer && (
            <div className="mt-[23px] border-t border-line pt-6">
              <p className="font-nunito text-base font-semibold leading-5 text-midblue">{t('מארגנים', 'Organized by')}</p>
              <Link href={href(`/business/${organizer.slug}/`)} className="mt-4 flex items-center gap-3">
                <span className="size-16 shrink-0 overflow-hidden rounded-full border border-line">
                  <Photo url={organizer.logo} alt="" className="size-full" icon={Shop} iconSize={24} />
                </span>
                <span className="min-w-0">
                  <span className="line-clamp-2 text-base font-semibold leading-[19px] text-[#3D3D3D]">{organizer.name}</span>
                  {organizer.subtitle && <span className="mt-1.5 block truncate text-xs leading-[15px] text-[#6D6D6D]">{organizer.subtitle}</span>}
                </span>
              </Link>
            </div>
          )}
        </aside>
      </div>

      {/* ── You May Also Like ── */}
      {related.length > 0 && (
        <>
          <section className="wrap hidden pb-[159px] pt-14 desk:block">
            <SectionTitle>{t('אולי יעניין אתכם גם', 'You May Also Like')}</SectionTitle>
            <div className="mt-8">
              <Carousel count={Math.min(related.length, 8)}>
                {related.slice(0, 8).map((x) => (
                  <div key={x.id} className="w-[calc((100%-48px)/3)] shrink-0 min-[1398px]:w-[calc((100%-72px)/4)]">
                    <WebEventCard event={x} lang={lang} category={firstCategory(x)} />
                  </div>
                ))}
              </Carousel>
            </div>
          </section>
          <section className="px-4 pb-6 pt-8 desk:hidden">
            <SectionTitle>{t('אולי יעניין אתכם גם', 'You May Also Like')}</SectionTitle>
            <div className="mt-4 flex flex-col gap-3">
              {related.slice(0, 4).map((x) => <MEventCard key={x.id} event={x} lang={lang} category={firstCategory(x)} />)}
            </div>
          </section>
        </>
      )}
      {related.length === 0 && <div className="hidden h-[159px] desk:block" />}
    </article>
  );
}

/** 24 Nunito in mid blue on the website, 16 Inter on the phone. */
function SectionTitle({ children }: { children: React.ReactNode }) {
  return <h2 className="text-base font-semibold text-[#1F1F1F] desk:font-nunito desk:text-2xl desk:leading-[30px] desk:text-midblue">{children}</h2>;
}

function HeroMeta({ icon, text, ltr = false }: { icon: string; text: string; ltr?: boolean }) {
  return (
    <span className="flex items-center gap-2">
      <img src={icon} alt="" className="size-4 shrink-0" />
      <span dir={ltr ? 'ltr' : undefined} className="truncate text-sm font-medium leading-[17px] text-white">{text}</span>
    </span>
  );
}

function CardMeta({ icon, text, ltr = false }: { icon: string; text: string; ltr?: boolean }) {
  return (
    <p className="mt-4 flex items-start gap-2">
      <img src={icon} alt="" className="mt-px size-4 shrink-0" />
      <span dir={ltr ? 'ltr' : undefined} className="text-sm leading-[17px] text-[#3D3D3D]">{text}</span>
    </p>
  );
}

function PhoneMeta({ icon, children }: { icon: React.ReactNode; children: React.ReactNode }) {
  return (
    <p className="mt-3 flex items-center gap-2">
      <span className="shrink-0">{icon}</span>
      <span className="truncate text-sm text-[#6D6D6D]">{children}</span>
    </p>
  );
}

/** "Event Details" on the website: four divided cells, each drawn only when
 *  the row carries what goes in it. The location opens directions. */
function DetailsBox({ e, lang, directions }: { e: EventDetail; lang: Lang; directions: string | null }) {
  const t = tr(lang);
  const time = timeRange(e, lang);
  const place = venue(e, lang);
  const price = eventPrice(e, lang, false);
  const cells = [
    e.start_date ? { icon: '/web/events/det_date.svg', label: t('תאריך', 'Date'), value: longDate(e.start_date, lang), ltr: false, link: null } : null,
    time ? { icon: '/web/events/det_time.svg', label: t('שעה', 'Time'), value: time, ltr: true, link: null } : null,
    place ? { icon: '/web/events/det_location.svg', label: t('מיקום', 'Location'), value: place, ltr: false, link: directions } : null,
    price ? { icon: '/web/events/det_price.svg', label: t('מחיר', 'Price'), value: price, ltr: false, link: null } : null,
  ].filter((c): c is NonNullable<typeof c> => !!c);
  if (!cells.length) return null;
  return (
    <section className="hidden desk:block">
      <SectionTitle>{t('פרטי האירוע', 'Event Details')}</SectionTitle>
      <div className="mt-6 flex rounded-xl border border-line p-4">
        {cells.map((c, i) => {
          const body = (
            <>
              <img src={c.icon} alt="" className="size-6 shrink-0" />
              <span className="min-w-0">
                <span className="block text-base font-medium leading-[19px] text-black">{c.label}</span>
                <span dir={c.ltr ? 'ltr' : undefined} className="mt-1 block text-sm leading-[17px] text-[#6D6D6D]">{c.value}</span>
              </span>
            </>
          );
          const cls = `flex flex-1 items-start gap-4 py-4 ${i === 0 ? '' : 'ps-4'} ${i === cells.length - 1 ? '' : 'border-e border-line pe-4'}`;
          return c.link
            ? <a key={c.label} href={c.link} target="_blank" rel="noopener" className={cls}>{body}</a>
            : <div key={c.label} className={cls}>{body}</div>;
        })}
      </div>
    </section>
  );
}
