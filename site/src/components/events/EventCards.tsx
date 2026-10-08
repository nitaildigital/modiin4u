import Link from 'next/link';
import { Calendar1, Global } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { href } from '@/lib/seo';
import type { EventCard } from '@/lib/data/events';
import { Photo } from './Photo';
import { dayOfMonth, eventPrice, interested, shortMonth, startTime, venue } from './labels';

/** The white date badge on a photo: "OCT" over "08". */
export function DateBadge({ date, lang, className = '' }: { date: string; lang: Lang; className?: string }) {
  return (
    <span className={`flex w-[57px] flex-col items-center gap-1 rounded-lg bg-white p-2 ${className}`}>
      <span className="text-xs font-medium leading-[15px] text-midblue">{shortMonth(date, lang)}</span>
      <span className="text-lg font-semibold leading-[22px] text-black">{dayOfMonth(date)}</span>
    </span>
  );
}

/** The turquoise category pill. */
export function CategoryPill({ label, className = '' }: { label: string; className?: string }) {
  // No display class of its own: the caller says whether it shows.
  return <span className={`whitespace-nowrap rounded-full bg-turquoise font-medium leading-[1.21] text-white ${className}`}>{label}</span>;
}

/** A small meta line: an icon in a 16 box, then the text. Clock times stay
 *  left to right inside the Hebrew page. */
function Meta({ icon, text, ltr = false, online = false }: { icon: string; text: string; ltr?: boolean; online?: boolean }) {
  return (
    <span className="flex min-w-0 items-center gap-2">
      <span className="flex size-4 shrink-0 items-center justify-center">
        {online ? <Global size={16} color="#17A9D0" variant="Bold" /> : <img src={icon} alt="" />}
      </span>
      <span dir={ltr ? 'ltr' : undefined} className="truncate text-sm leading-[17px] text-gray-text">{text}</span>
    </span>
  );
}

/** The website's event card, 364 tall (web_events_screen.dart, WebEventCard):
 *  the photo with the category pill and the date badge, the title, the start
 *  time and the place, the price and — once somebody has said they are
 *  coming — the interest count. */
export function WebEventCard({ event: e, lang, category }: { event: EventCard; lang: Lang; category?: string | null }) {
  const time = startTime(e, lang);
  const place = venue(e, lang);
  const price = eventPrice(e, lang);
  return (
    <Link href={href(`/event/${e.id}/`)}
      className="flex h-[364px] flex-col overflow-hidden rounded-xl border border-line bg-white transition hover:border-midblue hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)]">
      <div className="relative h-[200px] shrink-0">
        <Photo url={e.image} alt={e.title} className="size-full" icon={Calendar1} iconSize={34} />
        {category && <CategoryPill label={category} className="absolute end-[14px] top-[15px] px-2 py-1.5 text-xs" />}
        {e.start_date && <DateBadge date={e.start_date} lang={lang} className="absolute bottom-3 start-3" />}
      </div>
      <div className="flex min-h-0 flex-1 flex-col p-4">
        <p className="truncate font-nunito text-xl font-semibold leading-[25px] text-navy">{e.title}</p>
        {time && <span className="mt-4"><Meta icon="/web/events/card_clock.svg" text={time} ltr /></span>}
        {place && <span className="mt-4"><Meta icon="/web/events/card_pin.svg" text={place} online={e.is_online} /></span>}
        <div className="mt-auto flex items-center">
          <span className={`min-w-0 flex-1 truncate font-nunito text-xl font-semibold leading-[25px] ${e.is_free ? 'text-midblue' : 'text-navy'}`}>{price}</span>
          {e.rsvp_count > 0 && (
            <span className="flex items-center gap-1">
              <img src="/web/events/card_star.svg" alt="" className="size-[18px]" />
              <span className="text-sm font-medium leading-[17px] text-[#3D3D3D]">{interested(e.rsvp_count, lang)}</span>
            </span>
          )}
        </div>
      </div>
    </Link>
  );
}

/** The phone's event card (m_event_card.dart): the 200 photo with its date
 *  badge, then title, category, time and place, price and interest. */
export function MEventCard({ event: e, lang, category }: { event: EventCard; lang: Lang; category?: string | null }) {
  const time = startTime(e, lang);
  const place = venue(e, lang);
  const price = eventPrice(e, lang);
  return (
    <Link href={href(`/event/${e.id}/`)} className="block">
      <div className="relative h-[200px]">
        <Photo url={e.image} alt={e.title} className="size-full rounded-xl" icon={Calendar1} iconSize={40} />
        {e.start_date && (
          <span className="absolute bottom-3 start-3 flex w-[57px] flex-col items-center gap-1 rounded-lg bg-white p-2">
            <span className="text-sm font-medium text-midblue">{shortMonth(e.start_date, lang)}</span>
            <span className="text-2xl font-semibold leading-none text-black">{dayOfMonth(e.start_date, false)}</span>
          </span>
        )}
      </div>
      <div className="py-4">
        <p className="line-clamp-2 font-nunito text-xl font-semibold text-navy">{e.title}</p>
        {category && <p className="mt-2 text-sm text-gray-text">{category}</p>}
        {(time || place) && (
          <div className="mt-3 flex items-center text-sm text-gray-text">
            {time && (
              <span className="me-3 flex shrink-0 items-center gap-2">
                <span className="flex size-4 items-center justify-center"><img src="/web/events/card_clock.svg" alt="" /></span>
                <span dir="ltr">{time}</span>
              </span>
            )}
            {place && (
              <span className="flex min-w-0 items-center gap-2">
                <span className="flex size-4 shrink-0 items-center justify-center"><img src="/web/events/card_pin.svg" alt="" /></span>
                <span className="truncate">{place}</span>
              </span>
            )}
          </div>
        )}
        {(price || e.rsvp_count > 0) && (
          <div className="mt-3 flex items-center">
            {price && <span className={`font-nunito text-xl font-semibold ${e.is_free ? 'text-midblue' : 'text-navy'}`}>{price}</span>}
            {e.rsvp_count > 0 && (
              <span className="ms-auto flex items-center gap-1">
                <img src="/web/events/card_star.svg" alt="" className="size-4" />
                <span className="text-sm font-medium text-[#3D3D3D]">{interested(e.rsvp_count, lang)}</span>
              </span>
            )}
          </div>
        )}
      </div>
    </Link>
  );
}
