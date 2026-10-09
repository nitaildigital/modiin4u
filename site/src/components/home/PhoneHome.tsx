import Link from 'next/link';
import { Calendar1, Clock, House2, Location, Maximize4, Star1, Verify } from 'iconsax-react';
import { tr, type Lang } from '@/lib/i18n';
import { href } from '@/lib/seo';
import {
  activeListings, bizDescription, bizImage, bizName, bizNeighborhood, catName, eventCategoryNames, eventPrice, eventTime,
  foodPlaces, homeArticles, kosherLabel, liveOffers, primaryCategories, roomsText, shekels, upcomingEvents,
} from '@/lib/data/home';
import { dayBadge, phoneDateLine, tintOf } from './format';

// How many cards a phone row carries. The app's rows scroll through every
// restaurant and every article; a page has to send what it shows, so the
// two long rows stop at a screenful's worth of swiping, with "See all" for
// the rest.
const ROW_RESTAURANTS = 20;
const ROW_NEWS = 12;

/** A row's heading and its "See all". */
function Header({ title, to, all }: { title: string; to: string; all: string }) {
  return (
    <div className="flex items-center justify-between px-4">
      <h2 className="text-base font-semibold leading-[1.21] text-[#1F1F1F]">{title}</h2>
      <Link href={to} className="text-xs font-medium text-midblue">{all}</Link>
    </div>
  );
}

/** One horizontal row of cards, swiped sideways. */
function Row({ children, gap = 'gap-3' }: { children: React.ReactNode; gap?: string }) {
  return (
    <div className={`mt-3 flex snap-x items-start overflow-x-auto px-4 pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden ${gap}`}>
      {children}
    </div>
  );
}

/** The home page's phone layout below the header (home_screen.dart): the
 *  four shortcuts, restaurants, deals, events to come, apartments, and the
 *  latest news — a row only when it has something in it. */
export async function PhoneHome({ lang }: { lang: Lang }) {
  const t = tr(lang);
  const all = t('ראה הכל', 'See all');
  const [food, kinds, offers, events, eventCats, listings, articles] = await Promise.all([
    foodPlaces(), primaryCategories(), liveOffers(), upcomingEvents(), eventCategoryNames(lang), activeListings(), homeArticles(ROW_NEWS),
  ]);

  // Jobs takes Deals' place in the frame the app follows; the site has no
  // jobs page, so the fourth shortcut stays Deals, which it has.
  const shortcuts: [string, string, string][] = [
    [t('מסעדות', 'Restaurants'), 'restaurants', '/search-rest-modiin/'],
    [t('אירועים', 'Events'), 'events', '/events/'],
    [t('נדל"ן', 'Real estate'), 'realestate', '/search-apartments/'],
    [t('מבצעים', 'Deals'), 'deals', '/deals/'],
  ];

  return (
    <div className="pb-8 desk:hidden">
      <h2 className="mt-[22px] px-4 text-base font-semibold leading-[1.21] text-[#1F1F1F]">{t('גלו את מודיעין', 'Discover Modiin')}</h2>
      <ul className="mt-4 grid grid-cols-4 px-3">
        {shortcuts.map(([label, icon, to]) => (
          <li key={icon}>
            <Link href={to} className="flex flex-col items-center gap-2.5">
              <img src={`/icons/m_home_cat_${icon}.svg`} alt="" width={48} height={48} className="size-12" />
              <span className="max-w-full truncate text-sm font-medium leading-[1.21] text-[#3D3D3D]">{label}</span>
            </Link>
          </li>
        ))}
      </ul>

      {food.length > 0 && (
        <section className="mt-8">
          <Header title={t('מסעדות במודיעין', 'Restaurants in Modiin')} to="/search-rest-modiin/" all={all} />
          <Row>
            {food.slice(0, ROW_RESTAURANTS).map((b) => {
              const kind = kinds.get(b.id);
              const type = kind ? catName(kind.category, lang) : bizDescription(b);
              const address = [b.address?.trim(), bizNeighborhood(b, lang)].filter(Boolean).join(', ');
              const img = bizImage(b);
              return (
                <Link key={b.id} href={href(`/business/${b.slug || b.id}/`)} className="w-[270px] shrink-0 snap-start rounded-xl border border-line bg-white p-2">
                  <span className="relative block h-[140px] overflow-hidden rounded-lg" style={img ? undefined : { background: tintOf(b.id) }}>
                    {img && <img src={img} alt={bizName(b, lang)} loading="lazy" className="size-full object-cover" />}
                    {kosherLabel(b.kosher_level) && (
                      <span className="absolute bottom-2 left-2 flex items-center gap-1 rounded-[50px] bg-[#0033AC] px-2 py-1.5 text-[10px] font-medium leading-none text-white">
                        <Verify size={12} color="#fff" variant="Bold" />{t('כשר', 'Kosher')}
                      </span>
                    )}
                  </span>
                  <span dir="auto" className="mt-2.5 block truncate text-start font-nunito text-base font-semibold text-navy">{bizName(b, lang)}</span>
                  <span className="mt-2 flex items-center gap-1.5 text-xs text-[#6D6D6D]">
                    <Location size={14} color="#6D6D6D" className="shrink-0" />
                    <span className="truncate">{address}</span>
                  </span>
                  <span className="mt-2 flex items-center justify-between gap-2 text-xs">
                    {(b.review_count ?? 0) === 0
                      ? <span className="text-[#6D6D6D]">{t('אין דירוג עדיין', 'Not rated yet')}</span>
                      : (
                        <span className="flex shrink-0 items-center gap-1.5">
                          <Star1 size={14} color="#FFC107" variant="Bold" />
                          <span className="font-medium text-black">{(b.rating ?? 0).toFixed(1)}</span>
                          <span className="text-[#6D6D6D]">({b.review_count})</span>
                        </span>
                      )}
                    {type && <span className="min-w-0 truncate rounded bg-[#006BF6] px-1.5 py-[3px] text-[10px] font-medium leading-[1.21] text-white">{type}</span>}
                  </span>
                </Link>
              );
            })}
          </Row>
        </section>
      )}

      {offers.length > 0 && (
        <section className="mt-8">
          <Header title={t('מבצעים בקרבתך', 'Deals near you')} to="/deals/" all={all} />
          <Row>
            {offers.map((o) => {
              const img = o.image_url || o.businesses?.logo_url || o.businesses?.cover_url;
              return (
                <Link key={o.id} href={href(`/deal/${o.id}/`)} className="relative h-[130px] w-[230px] shrink-0 snap-start overflow-hidden rounded-xl bg-[#E0E8F0]">
                  {img && <img src={img} alt="" loading="lazy" className="absolute inset-0 size-full object-cover" />}
                  <span className="absolute inset-0 bg-[linear-gradient(180deg,transparent,rgba(0,0,0,.55))]" />
                  <span dir="auto" className="absolute bottom-3 right-3 left-3 line-clamp-2 text-right font-rubik text-base font-bold leading-tight text-white">{o.name}</span>
                </Link>
              );
            })}
          </Row>
        </section>
      )}

      {events.length > 0 && (
        <section className="mt-8">
          <Header title={t('אירועים קרובים', 'Upcoming events')} to="/events/" all={all} />
          <Row>
            {events.map((e) => {
              const img = e.image_url || e.og_image;
              const { month, day } = dayBadge(e.start_date, lang);
              const price = e.is_free ? t('חינם', 'Free') : eventPrice(e);
              return (
                <Link key={e.id} href={href(`/event/${e.id}/`)} className="w-[270px] shrink-0 snap-start rounded-xl border border-line bg-white p-2">
                  <span className="relative block h-[140px] overflow-hidden rounded-lg" style={img ? undefined : { background: tintOf(e.id) }}>
                    {img && <img src={img} alt={e.title} loading="lazy" className="size-full object-cover" />}
                    {day && (
                      <span className="absolute bottom-2.5 left-2.5 flex w-[57px] flex-col items-center rounded-lg bg-white p-2 leading-[1.21]">
                        <span className="text-sm font-medium text-midblue">{month}</span>
                        <span className="mt-1 text-xl font-semibold text-black">{day}</span>
                      </span>
                    )}
                  </span>
                  <span dir="auto" className="mt-2.5 block truncate text-start font-nunito text-base font-semibold text-navy">{e.title}</span>
                  <span className="mt-1 block min-h-[15px] text-xs text-[#6D6D6D]">{eventCats.get(e.id) ?? ''}</span>
                  <span className="mt-2 flex items-start gap-2">
                    <span className="min-w-0 flex-1 text-xs text-[#6D6D6D]">
                      <span className="flex items-center gap-1.5">
                        <Location size={14} color="#6D6D6D" className="shrink-0" />
                        <span className="truncate">{e.venue_name || e.address}</span>
                      </span>
                      <span className="mt-2 flex items-center gap-1.5">
                        <Clock size={14} color="#6D6D6D" className="shrink-0" />
                        {eventTime(e) ?? ''}
                      </span>
                    </span>
                    {price && <span className={`font-nunito text-lg font-semibold ${e.is_free ? 'text-midblue' : 'text-navy'}`}>{price}</span>}
                  </span>
                </Link>
              );
            })}
          </Row>
        </section>
      )}

      {listings.length > 0 && (
        <section className="mt-8">
          <Header title={t('דירות בקרבתך', 'Apartments near you')} to="/search-apartments/" all={all} />
          <ul className="mt-3 px-4">
            {listings.slice(0, 4).map((l) => {
              const rent = l.kind === 'rent';
              const price = rent ? l.price_per_month : l.price;
              const address = l.address || (lang === 'en' && l.neighborhoods?.name_en) || l.neighborhoods?.name;
              return (
                <li key={l.id} className="border-b border-line">
                  <Link href={href(`/listing/${l.id}/`)} className="flex items-start gap-3 py-3">
                    {l.cover_url
                      ? <img src={l.cover_url} alt={l.title} loading="lazy" className="h-20 w-[95px] shrink-0 rounded-md object-cover" />
                      : <span className="flex h-20 w-[95px] shrink-0 items-center justify-center rounded-md bg-[#E0E8F0]"><House2 size={28} color="#9AA0A6" variant="Bold" /></span>}
                    <span className="min-w-0 flex-1">
                      <span className="flex items-center justify-between gap-2">
                        <span className="font-nunito text-base font-semibold text-navy">
                          {price != null ? (rent ? t(`${shekels(price)} לחודש`, `${shekels(price)} / month`) : shekels(price)) : ''}
                        </span>
                        <span className="text-[10px] font-medium text-turquoise">{rent ? t('להשכרה', 'FOR RENT') : t('למכירה', 'FOR SALE')}</span>
                      </span>
                      {address && (
                        <span className="mt-[9px] flex items-center gap-1.5 text-xs text-[#6D6D6D]">
                          <Location size={14} color="#6D6D6D" className="shrink-0" /><span className="truncate">{address}</span>
                        </span>
                      )}
                      {(l.sqm != null || l.rooms != null) && (
                        <span className="mt-[9px] flex items-center text-xs text-[#6D6D6D]">
                          {l.sqm != null && <span className="me-[31px] flex items-center gap-2"><Maximize4 size={14} color="#6D6D6D" />{l.sqm} {t('מ״ר', 'm²')}</span>}
                          {l.rooms != null && <span className="flex items-center gap-2"><House2 size={14} color="#6D6D6D" />{roomsText(l.rooms)} {t('חדרים', 'Rooms')}</span>}
                        </span>
                      )}
                    </span>
                  </Link>
                </li>
              );
            })}
          </ul>
        </section>
      )}

      {articles.length > 0 && (
        <section className="mt-8">
          <Header title={t('חדשות אחרונות', 'Latest news')} to="/news/" all={all} />
          <Row gap="gap-5">
            {articles.map((a) => (
              <Link key={a.id} href={href(`/news/${a.slug}/`)} className="w-[250px] shrink-0 snap-start">
                {a.image
                  ? <img src={a.image} alt="" loading="lazy" className="h-[150px] w-[250px] rounded-xl object-cover" />
                  : <span className="block h-[150px] w-[250px] rounded-xl" style={{ background: tintOf(a.id) }} />}
                <span dir="rtl" className="mt-3 line-clamp-2 text-right text-base font-medium leading-[1.19] text-black">{a.title}</span>
                <span className="mt-3 flex items-center gap-2 text-sm text-[#6D6D6D]">
                  <Calendar1 size={16} color="#888888" className="shrink-0" />
                  <time dateTime={a.published_at ?? undefined}>{phoneDateLine(a.published_at, lang)}</time>
                </span>
              </Link>
            ))}
          </Row>
        </section>
      )}
    </div>
  );
}
