import Link from 'next/link';
import { Buildings2, Call, Clock, Export, Gallery, Global, Instagram, Location, MessageText1, Messages2, Reserve, Shop, Star1, Verify, ArrowLeft2 } from 'iconsax-react';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { h1For, breadcrumb, href, SITE_NAME } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import {
  businessGallery, businessMenu, businessReviews, localName, moreBusinesses, primaryKinds, reviewReplies,
  type Business, type BusinessCard, type Kind, type MenuItem,
} from '@/lib/data/business';
import { JsonLd } from '@/components/JsonLd';
import { BusinessUI, BackButton, CallMenu, ExpandableText, GalleryStrip, PhoneTabs, PhotoThumb, ShareMenu, ShowAllPhotos, TrackedLink } from './ui';
import { DesktopReviews, type ReviewView } from './Reviews';
import { GoogleHours } from './GoogleHours';
import { BusinessMap } from './BusinessMap';
import { ShareMark, WhatsAppMark, DirectionMark } from './icons';
import {
  clock, dirOf, highlights, hoursOf, initials, kosherLabel, openNow, price, reviewDate, shownUrl, sized, waNumber, webLink,
  type Hours,
} from './format';

/** The city as the old site's structured data named it (build_seo_pages.py). */
const CITY = 'מודיעין-מכבים-רעות';

type T = (he: string, en: string) => string;

/** Everything the two layouts read, worked out once. */
type View = {
  b: Business; lang: Lang; he: boolean; t: T; path: string;
  name: string; heading: string; kind: string | null; about: string;
  cover: string | null; photos: string[]; hours: Hours[]; hoursText: string | null;
  reviews: ReviewView[]; menu: MenuItem[]; isPark: boolean; hasPlace: boolean;
  phone: string; website: string; whatsapp: string; instagram: string;
};

/** A business or park page — web_business_detail_screen.dart above 1100 px,
 *  business_detail_screen.dart below. [path] is the address it is read at
 *  (/business/<slug>/, or an old /professionals/<slug>/), for its H1, its
 *  structured data and its breadcrumb. */
export async function BusinessPage({ b, path }: { b: Business; path: string }) {
  const lang = await getLang();
  const t = tr(lang);
  const he = lang === 'he';
  const [photos, raw, menuRows, kinds, more] = await Promise.all([
    businessGallery(b.id), businessReviews(b.id), businessMenu(b.id), primaryKinds(), moreBusinesses(b),
  ]);
  const replies = await reviewReplies(raw.map((r) => r.id));
  const resident = t('תושב', 'Resident');

  const name = localName(b.name, b.name_en, lang);
  const k = kinds[b.id];
  const isPark = b.kind === 'park';
  const full = b.full_description?.trim() || null;
  const v: View = {
    b, lang, he, t, path, name,
    // Google reads the Hebrew page: WordPress's H1 where the address had one.
    heading: he ? h1For(path, b.name) : name,
    kind: k ? localName(k.category.name, k.category.name_en, lang) : null,
    about: (full ?? b.short_description ?? '').trim(),
    cover: b.cover_url || b.og_image_url || null,
    photos,
    hours: hoursOf(b),
    hoursText: b.hours_text?.replace(/\r\n/g, '\n').trim() || null,
    reviews: raw.map((r) => {
      const author = r.author_name || r.profiles?.full_name || '';
      return {
        id: r.id, author: author || resident, initials: initials(author), date: reviewDate(r.created_at, lang),
        rating: r.rating, body: r.body ?? '',
        replies: (replies[r.id] ?? []).map((x) => ({
          id: x.id, author: x.author_name?.trim() || resident, date: reviewDate(x.created_at, lang), body: (x.body ?? '').trim(),
        })),
      };
    }),
    menu: menuRows.filter((m) => m.is_available !== false),
    isPark,
    hasPlace: !!b.latitude && !!b.longitude,
    phone: isPark ? '' : (b.phone ?? '').trim(),
    website: isPark ? '' : (b.website ?? '').trim(),
    whatsapp: isPark ? '' : (b.whatsapp ?? '').trim(),
    instagram: isPark ? '' : (b.instagram ?? '').trim(),
  };

  const image = b.og_image_url || b.cover_url;
  const ld: Record<string, unknown> = {
    '@context': 'https://schema.org', '@type': isPark ? 'Park' : 'LocalBusiness',
    name: b.name, url: SITE_URL + href(path),
  };
  if (b.address) ld.address = { '@type': 'PostalAddress', streetAddress: b.address, addressLocality: CITY, addressCountry: 'IL' };
  if (b.phone && !isPark) ld.telephone = b.phone;
  if (b.latitude && b.longitude) ld.geo = { '@type': 'GeoCoordinates', latitude: b.latitude, longitude: b.longitude };
  if (image) ld.image = image;
  if ((b.review_count ?? 0) > 0 && b.rating) ld.aggregateRating = { '@type': 'AggregateRating', ratingValue: b.rating, reviewCount: b.review_count };
  const section: [string, string] = path.startsWith('/professionals/')
    ? ['אנשי מקצוע', '/professionals/']
    : isPark ? ['פארקים', '/parks/'] : ['עסקים', '/businesses/'];

  return (
    <BusinessUI businessId={b.id} photos={photos}>
      <JsonLd data={[ld, breadcrumb([[SITE_NAME, '/'], section, [b.name, path]])]} />
      <div className="hidden desk:block"><Desktop v={v} kinds={more.kinds} more={more.cards} inNeighborhood={more.inNeighborhood} /></div>
      <div className="desk:hidden"><Phone v={v} /></div>
    </BusinessUI>
  );
}

// ═══════════════════════════ Desktop ═══════════════════════════

const title = 'font-nunito text-2xl font-semibold text-midblue';

function Desktop({ v, more, kinds, inNeighborhood }: { v: View; more: BusinessCard[]; kinds: Record<string, Kind>; inNeighborhood: boolean }) {
  const { b, t, he } = v;
  const hl = highlights(b, t);
  const neighborhood = b.neighborhoods ? localName(b.neighborhoods.name, b.neighborhoods.name_en, v.lang) : '';
  return (
    <>
      <Hero v={v} />
      <div className="wrap mt-14">
        <div className="flex items-start gap-12 min-[1660px]:gap-[136px]">
          <div className="flex min-w-0 flex-1 flex-col gap-14">
            {v.about && <About v={v} />}
            {hl.length > 0 && (
              <section>
                <h2 className={title}>{t('נקודות בולטות', 'Highlights')}</h2>
                <ul className="mt-6 flex flex-col gap-4">
                  {hl.map((h) => (
                    <li key={h} className="flex items-center gap-3 text-base text-[#3D3D3D]">
                      <img src="/web/business/highlight_check.svg" alt="" width={20} height={20} />{h}
                    </li>
                  ))}
                </ul>
              </section>
            )}
            {/* The menu the panel keeps — not a park's. */}
            {!v.isPark && v.menu.length > 0 && <DesktopMenu v={v} />}
            {v.photos.length > 0 && (
              <section>
                <h2 className={title}>{t('גלריית העסק', 'Business Gallery')}</h2>
                <div className="mt-[23px]"><GalleryStrip /></div>
              </section>
            )}
            <section className="max-w-[918px]">
              <h2 className={title}>{t(`ביקורות על ${v.name}`, `Reviews for ${v.name}`)}</h2>
              <div className="mt-[39px]">
                {v.reviews.length === 0 ? (
                  // Nothing to average, and no place on the website to write
                  // the first one: reviews are written in the app.
                  <p className="text-base text-[#3D3D3D]">{t('עדיין אין ביקורות. תושבים כותבים ביקורות באפליקציית מודיעין בשבילך.', 'No reviews yet. Reviews are written by residents in the Modiin4u app.')}</p>
                ) : <DesktopReviews reviews={v.reviews} he={he} />}
              </div>
            </section>
          </div>
          <aside className="flex w-[376px] shrink-0 flex-col gap-5">
            <LocationCard v={v} />
            {!v.isPark && <MoreInfo v={v} />}
          </aside>
        </div>
      </div>
      {more.length > 0 && (
        <section className="wrap mt-16">
          <h2 className={title}>
            {inNeighborhood && neighborhood ? t(`עסקים נוספים ב${neighborhood}`, `More Businesses in ${neighborhood}`) : t('עסקים נוספים במודיעין', 'More Businesses in Modiin')}
          </h2>
          {/* Two across, three on a laptop, five on a wide screen — and only
              as many as fit one row. */}
          <ul className="mt-[30px] grid grid-cols-3 gap-6 min-[1560px]:grid-cols-5 [&>li:nth-child(n+4)]:hidden min-[1560px]:[&>li:nth-child(n+4)]:block">
            {more.map((x) => <li key={x.id}><SmallCard x={x} kind={kinds[x.id]} lang={v.lang} /></li>)}
          </ul>
        </section>
      )}
      <div className="h-[120px]" />
    </>
  );
}

/** The cover across the page, the logo and the name over it. */
function Hero({ v }: { v: View }) {
  const { b, t, he } = v;
  const kosher = kosherLabel(b.kosher_level);
  const facts = [v.kind, kosher ? t('כשר', 'Kosher') : null].filter(Boolean).join(' · ');
  const cover = v.cover ?? v.photos[0] ?? null;
  const count = b.review_count ?? 0;
  const now = v.hours.length ? openNow(v.hours) : null;
  return (
    <section className="relative h-[550px] overflow-hidden bg-gradient-to-r from-[#0058B5] to-[#010A36]">
      {cover && <img src={sized(cover, 1440)} alt={v.name} className="absolute inset-0 size-full object-cover" />}
      {/* The design darkens the half the name sits on, fading to clear. The
          Flutter page meant to and drew nothing (an empty box sized itself
          to no height); mirrored for Hebrew, the name lands on another part
          of the photo, so the darkening is what keeps it readable. */}
      <div className="absolute inset-y-0 start-0 w-1/2"
        style={{ backgroundImage: `linear-gradient(to ${he ? 'left' : 'right'}, rgba(0,0,0,.8) 1.2%, rgba(0,0,0,.8) 52.3%, rgba(0,0,0,0))` }} />
      <div className="wrap relative h-full"><div className="relative h-full">
        <div className="absolute inset-x-0 top-[158px] flex items-start gap-[33px]">
          <HeroLogo url={b.logo_url} isPark={v.isPark} />
          <div className="min-w-0 flex-1">
            <p role="heading" aria-level={1} dir={dirOf(v.heading)} className="line-clamp-2 font-nunito text-[48px] font-semibold leading-[1.23] text-white">{v.heading}</p>
            {facts && <p className="mt-3.5 text-base text-white">{facts}</p>}
            {(count > 0 || kosher) && (
              <div className="mt-6 flex gap-4">
                {count > 0 && <GlassPill icon="/web/business/star14.svg" label={t(`${(b.rating ?? 0).toFixed(1)} · ${count} ביקורות`, `${(b.rating ?? 0).toFixed(1)} · ${count} reviews`)} />}
                {kosher && <GlassPill icon="/web/business/check14.svg" label={he ? kosher : 'Kosher'} />}
              </div>
            )}
            <div className="mt-8" />
            {now && (
              <p className="mb-4 flex items-center gap-2 text-sm font-medium">
                {now.open
                  ? <><img src="/web/business/clock_open.svg" alt="" width={16} height={16} /><span className="text-[#00BA00]">{t('פתוח עכשיו', 'Open now')}</span></>
                  : <><Clock size={16} color="#F21C1C" /><span className="text-[#F21C1C]">{t('סגור עכשיו', 'Closed now')}</span></>}
                <span className="ms-1 text-white">
                  {now.closes && `${t('נסגר ב-', 'Closes')} ${clock(now.closes, v.lang)} · `}
                  <a href="#hours" className="underline">{t('כל שעות הפעילות', 'See all hours')}</a>
                </span>
              </p>
            )}
            {b.address && (
              <p className="flex items-center gap-2 text-sm font-medium text-white">
                <img src="/web/business/pin.svg" alt="" width={12} height={16} className="mx-0.5" />
                <span dir={dirOf(b.address)} className="truncate">{b.address}</span>
              </p>
            )}
          </div>
        </div>
        {v.photos.length > 0 && (
          <div className="absolute end-0 top-[486px]"><ShowAllPhotos label={t('כל התמונות', 'Show all photos')} /></div>
        )}
      </div></div>
    </section>
  );
}

/** The logo in a white circle, 140 across; a park's badge, or the shop mark,
 *  where there is none. */
function HeroLogo({ url, isPark }: { url: string | null; isPark: boolean }) {
  return (
    <span className="flex size-[140px] shrink-0 items-center justify-center overflow-hidden rounded-full bg-white">
      {url ? <img src={sized(url, 140)} alt="" className="size-full object-contain" />
        : isPark ? <img src="/icons/m_municipal_parks.svg" alt="" width={56} height={56} />
          : <Shop size={48} color="#123A72" />}
    </span>
  );
}

function GlassPill({ icon, label }: { icon: string; label: string }) {
  return (
    <span className="flex items-center gap-[7px] rounded-full border border-white/50 bg-white/10 px-3 py-2 text-sm text-white">
      <img src={icon} alt="" width={14} height={14} />{label}
    </span>
  );
}

/** About, paragraph by paragraph, each in its own direction. */
function About({ v }: { v: View }) {
  const paragraphs = v.about.split(/\n\s*\n/).map((p) => p.trim()).filter(Boolean);
  return (
    <section className="max-w-[896px]">
      <h2 className={title}>{v.t(`אודות ${v.name}`, `About ${v.name}`)}</h2>
      <div className="mt-6 flex flex-col gap-[18px]">
        {paragraphs.map((p, i) => <p key={i} dir={dirOf(p)} className="whitespace-pre-line text-base leading-[1.6] text-[#3D3D3D]">{p}</p>)}
      </div>
    </section>
  );
}

/** Items grouped by the heading the panel gave them, in its order. */
function sections(items: MenuItem[], trim: boolean): [string, MenuItem[]][] {
  const by = new Map<string, MenuItem[]>();
  for (const i of items) {
    const key = trim ? (i.section ?? '').trim() : (i.section ?? '');
    by.set(key, [...(by.get(key) ?? []), i]);
  }
  return [...by.entries()];
}

function DesktopMenu({ v }: { v: View }) {
  return (
    <section>
      <h2 className={title}>{v.t('תפריט', 'Menu')}</h2>
      {sections(v.menu, true).map(([sec, items]) => (
        <div key={sec}>
          {sec && <h3 className="mt-5 text-lg font-semibold text-black">{sec}</h3>}
          <ul className="mt-2">
            {items.map((i) => (
              <li key={i.id} className="flex items-start gap-4 border-b border-line py-3">
                <div className="min-w-0 flex-1">
                  <p className="text-base font-medium text-black">{i.name}</p>
                  {i.description?.trim() && <p className="mt-1 text-sm text-[#6D6D6D]">{i.description.trim()}</p>}
                </div>
                {price(i.price_agorot) && <span className="text-base font-semibold text-black">{price(i.price_agorot)}</span>}
              </li>
            ))}
          </ul>
        </div>
      ))}
    </section>
  );
}

const DAYS: Record<number, [string, string]> = { 1: ['שני', 'Mon'], 2: ['שלישי', 'Tue'], 3: ['רביעי', 'Wed'], 4: ['חמישי', 'Thu'], 5: ['שישי', 'Fri'], 6: ['שבת', 'Sat'], 7: ['ראשון', 'Sun'] };

/** Location & Hours: the address, the map, and the hours — the days the
 *  business published, else its hours as written, else Google's. */
function LocationCard({ v }: { v: View }) {
  const { b, t, he } = v;
  const days = [1, 2, 3, 4, 5, 6, 7].filter((d) => v.hours.some((h) => h.day === d));
  return (
    <div id="hours" className="scroll-mt-24 rounded-xl border border-line bg-white py-4">
      <div className="px-5">
        <h2 className="font-nunito text-xl font-semibold text-midblue">{t('מיקום ושעות', 'Location & Hours')}</h2>
        {b.address && <p dir={dirOf(b.address)} className={`mt-1.5 text-sm text-[#6D6D6D] ${he ? 'text-right' : 'text-left'}`}>{b.address}</p>}
      </div>
      {v.hasPlace && <BusinessMap businessId={b.id} lat={b.latitude!} lng={b.longitude!} lang={v.lang} label={t('פתיחה ב-Google Maps', 'Open in Google Maps')} />}
      {days.length > 0 ? (
        <ul className="mt-4 flex flex-col gap-5 px-5">
          {days.map((d) => {
            const open = v.hours.filter((h) => h.day === d && h.open && h.close);
            return (
              <li key={d} className="flex items-center justify-between text-sm font-medium text-[#3D3D3D]">
                <span>{DAYS[d][he ? 0 : 1]}</span>
                {open.length === 0
                  ? <span className="text-[#F21C1C]">{t('סגור', 'Close')}</span>
                  : <span dir="ltr">{open.map((h) => `${clock(h.open!, v.lang)} - ${clock(h.close!, v.lang)}`).join(', ')}</span>}
              </li>
            );
          })}
        </ul>
      ) : v.hoursText ? (
        // As the business wrote them: read into rows they would be guesses.
        <div className="mt-4 px-5">
          <p className="text-sm font-semibold text-[#3D3D3D]">{t('שעות פתיחה', 'Opening hours')}</p>
          <div className="mt-2"><HoursLines text={v.hoursText} he={he} /></div>
        </div>
      ) : b.google_place_id ? (
        <GoogleHours placeId={b.google_place_id} lang={v.lang} />
      ) : null}
    </div>
  );
}

/** Each line in its own direction, all at the page's start edge: a line of
 *  only times set right to left would read "18:00 - 08:00". */
function HoursLines({ text, he }: { text: string; he: boolean }) {
  return (
    <>
      {text.split('\n').map((line, i) => (
        <p key={i} dir={dirOf(line)} className={`min-h-[1.6em] text-sm font-medium leading-[1.6] text-[#3D3D3D] ${he ? 'text-right' : 'text-left'}`}>{line}</p>
      ))}
    </>
  );
}

function InfoRow({ icon, label, value, blue = false, external = false }: { icon: React.ReactNode; label: string; value: string; blue?: boolean; external?: boolean }) {
  return (
    <span className="flex items-center gap-4">
      <span className="flex size-5 shrink-0 items-center justify-center">{icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block text-sm text-[#5D5D5D]">{label}</span>
        <span className="mt-1 flex items-center gap-1.5">
          <span dir="ltr" className={`truncate text-[15px] font-medium ${blue ? 'text-midblue' : 'text-black'}`}>{value}</span>
          {external && <img src="/web/business/external.svg" alt="" width={16} height={16} />}
        </span>
      </span>
    </span>
  );
}

/** More Info: website, phone, WhatsApp, Instagram, share. */
function MoreInfo({ v }: { v: View }) {
  const { t, he } = v;
  return (
    <div className="flex flex-col gap-5 rounded-xl border border-line p-6">
      <h2 className="mb-1 font-nunito text-xl font-semibold text-midblue">{t('מידע נוסף', 'More Info')}</h2>
      {v.website && (
        <TrackedLink stat="website" href={webLink(v.website)}>
          <InfoRow icon={<img src="/web/business/website.svg" alt="" width={20} height={20} />} label={t('אתר', 'Website')} value={shownUrl(v.website)} blue external />
        </TrackedLink>
      )}
      {v.phone && (
        <CallMenu phone={v.phone} he={he}>
          <InfoRow icon={<img src="/web/business/call.svg" alt="" width={20} height={20} />} label={t('טלפון', 'Call')} value={v.phone} />
        </CallMenu>
      )}
      {v.whatsapp && (
        <TrackedLink stat="whatsapp" href={`https://wa.me/${waNumber(v.whatsapp)}`}>
          <InfoRow icon={<WhatsAppMark size={20} />} label="WhatsApp" value={v.whatsapp} />
        </TrackedLink>
      )}
      {v.instagram && (
        <TrackedLink stat="instagram" href={webLink(v.instagram)}>
          <InfoRow icon={<img src="/web/business/website.svg" alt="" width={20} height={20} />} label="Instagram" value={shownUrl(v.instagram)} blue external />
        </TrackedLink>
      )}
      <ShareMenu title={v.name} he={he}>
        <InfoRow icon={<ShareMark size={20} className="text-black" />} label={t('שיתוף', 'Share')} value={t('שלחו את העמוד', 'Send this page')} />
      </ShareMenu>
    </div>
  );
}

const BADGES: Record<string, [string, string]> = {
  'cafe-bakery': ['card_badge_ring.svg', 'card_badge_cafe.svg'],
  restaurants: ['card_badge_ring_green.svg', 'card_badge_restaurant.svg'],
};

/** A neighbour's card: photo, the round badge on its edge, name, kind,
 *  address, rating. */
function SmallCard({ x, kind, lang }: { x: BusinessCard; kind?: Kind; lang: Lang }) {
  const t = tr(lang);
  const name = localName(x.name, x.name_en, lang);
  const subtitle = kind ? localName(kind.category.name, kind.category.name_en, lang) : (x.short_description ?? x.full_description ?? '');
  const address = x.address || (x.neighborhoods ? localName(x.neighborhoods.name, x.neighborhoods.name_en, lang) : '');
  const badge = kind ? BADGES[kind.rootSlug] : undefined;
  const photo = x.cover_url || x.og_image_url || x.logo_url;
  return (
    <Link href={href(`/business/${x.slug || x.id}/`)} className="flex h-[348px] flex-col overflow-hidden rounded-xl border border-line bg-white">
      <span className="flex h-[200px] shrink-0 items-center justify-center bg-gradient-to-r from-[#0058B5] to-[#010A36]">
        {photo ? <img src={sized(photo, 320)} alt="" loading="lazy" className="size-full object-cover" /> : <Shop size={40} color="rgba(255,255,255,0.6)" />}
      </span>
      <span className="relative flex-1 p-4">
        {badge && (
          <span className="absolute -top-[22px] end-3.5 flex size-11 items-center justify-center">
            <img src={`/web/home/${badge[0]}`} alt="" className="absolute inset-0 size-11" />
            <img src={`/web/home/${badge[1]}`} alt="" width={20} height={20} className="relative" />
          </span>
        )}
        <span className="block h-[50px]">
          <span dir={dirOf(name)} className="block truncate font-nunito text-xl font-semibold leading-[1.25] text-navy">{name}</span>
          <span dir={dirOf(subtitle)} className="mt-2 block truncate text-sm leading-[1.21] text-[#5F5E5A]">{subtitle}</span>
        </span>
        {address && (
          <span className="mt-4 flex items-center gap-2">
            <img src="/web/home/card_pin.svg" alt="" width={12} height={16} className="mx-0.5" />
            <span dir={dirOf(address)} className={`min-w-0 flex-1 truncate text-sm leading-[1.21] text-[#5F5E5A] ${lang === 'he' ? 'text-right' : 'text-left'}`}>{address}</span>
          </span>
        )}
        <span className="mt-4 flex items-center gap-2 text-sm leading-[1.21]">
          {(x.review_count ?? 0) === 0
            ? <span className="text-[#6D6D6D]">{t('אין דירוג עדיין', 'Not rated yet')}</span>
            : <><img src="/web/home/card_star.svg" alt="" width={16} height={16} /><span className="font-medium text-black">{(x.rating ?? 0).toFixed(1)}</span><span className="text-[#6D6D6D]">({x.review_count})</span></>}
        </span>
      </span>
    </Link>
  );
}

// ═══════════════════════════ Phone ═══════════════════════════

const phoneTitle = 'text-base font-semibold text-[#1F1F1F]';

function Phone({ v }: { v: View }) {
  const { b, t, he } = v;
  const kosher = kosherLabel(b.kosher_level);
  const count = b.review_count ?? 0;
  const now = v.hours.length ? openNow(v.hours) : null;
  const neighborhood = b.neighborhoods ? localName(b.neighborhoods.name, b.neighborhoods.name_en, v.lang) : '';
  const place = [b.address ?? '', neighborhood].filter(Boolean).join(', ');
  const hasPlace = b.latitude || b.longitude;
  const waze = hasPlace
    ? `https://waze.com/ul?ll=${b.latitude},${b.longitude}&navigate=yes`
    // No location on record: Waze searches the address, not 0,0.
    : `https://waze.com/ul?q=${encodeURIComponent(`${(b.address ?? '').trim()}, מודיעין`)}&navigate=yes`;
  const circle = 'flex size-10 items-center justify-center rounded-full border border-line bg-white';

  const tabs = [
    { label: t('סקירה', 'Overview'), index: 0, content: <PhoneOverview v={v} /> },
    ...(!v.isPark && v.menu.length > 0 ? [{ label: t('תפריט', 'Menu'), index: 1, content: <PhoneMenu v={v} /> }] : []),
    { label: t('תמונות', 'Photos'), index: 2, content: <PhonePhotos v={v} /> },
    { label: t('ביקורות', 'Reviews'), index: 3, content: <div className="pt-12"><PhoneSummary v={v} /><div className="mt-6"><PhoneReviewList v={v} /></div></div> },
  ];

  return (
    <div className="pb-8">
      {/* The photo, with the logo half over its lower edge. */}
      <div className="relative h-[310px]">
        <div className="relative h-[260px] overflow-hidden bg-gradient-to-b from-[#010A36] to-[#0058B5]">
          {v.cover && <img src={sized(v.cover, 430)} alt={v.name} className="absolute inset-0 size-full object-cover" />}
          <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
          {!v.cover && <span className="absolute inset-0 flex items-center justify-center"><Reserve size={60} color="rgba(255,255,255,0.25)" /></span>}
          <div className="absolute start-3 top-[7px]"><BackButton fallback={href('/businesses/')} label={t('חזרה', 'Back')} /></div>
          <ShareMenu title={v.name} he={he} nativeFirst className="!absolute end-3 top-[7px]">
            <span className="flex size-10 items-center justify-center rounded-full bg-white"><Export size={20} color="#3D3D3D" /></span>
          </ShareMenu>
          {v.photos.length > 0 && <div className="absolute bottom-3.5 end-[13px]"><ShowAllPhotos phone label={t('הצג את כל התמונות', 'Show all photos')} /></div>}
        </div>
        <span className={`absolute start-4 top-[210px] flex size-[100px] items-center justify-center overflow-hidden rounded-full border-[3px] border-white shadow-[0_0_12px_rgba(0,0,0,0.08)] ${b.logo_url ? 'bg-white' : 'bg-gradient-to-br from-[#0058B5] to-[#010A36]'}`}>
          {b.logo_url ? <img src={sized(b.logo_url, 100)} alt="" className="size-full object-contain p-3" /> : <Shop size={36} color="rgba(255,255,255,0.6)" />}
        </span>
        {kosher && (
          <span className="absolute end-[15px] top-[276px] flex items-center gap-1.5 rounded-md border border-line bg-white px-2 py-1.5 text-sm font-medium text-midblue">
            <Verify size={14} color="#123A72" />{he ? kosher : 'Kosher'}
          </span>
        )}
      </div>

      <div className="mt-3 px-4">
        <h1 className="font-nunito text-[28px] font-semibold leading-tight text-black">{v.heading}</h1>
        <p className="mt-1.5 text-sm text-[#6D6D6D]">{v.kind ?? b.short_description ?? b.full_description ?? ''}</p>
      </div>

      <div className="mt-4 flex items-center px-4 text-sm">
        {count === 0 ? <span className="text-[#6D6D6D]">{t('אין דירוג עדיין', 'Not rated yet')}</span> : (
          <><Star1 size={16} color="#FFC107" variant="Bold" /><span className="ms-1.5 font-medium text-black">{(b.rating ?? 0).toFixed(1)}</span><span className="ms-1 text-[#6D6D6D]">({count})</span></>
        )}
        {now && (
          <span className="ms-4 flex items-center gap-2 font-medium" style={{ color: now.open ? '#00BA00' : '#E74C3C' }}>
            <span className="flex size-4 items-center justify-center rounded-full text-[10px] leading-none text-white" style={{ background: now.open ? '#00BA00' : '#E74C3C' }}>{now.open ? '✓' : '✕'}</span>
            {now.open ? t('פתוח עכשיו', 'Open now') : t('סגור', 'Closed')}
          </span>
        )}
      </div>

      <p className="mt-4 flex items-center gap-2 px-4 text-sm text-[#6D6D6D]">
        <Location size={16} color="#888888" className="shrink-0" /><span className="truncate">{place}</span>
      </p>
      {b.neighborhood_id && neighborhood && (
        <Link href={href(`/neighborhood/${b.neighborhood_id}/`)} className="mx-4 mt-2 flex items-center gap-2 text-sm font-medium text-midblue">
          <Buildings2 size={16} color="#123A72" /><span className="truncate">{neighborhood}</span><ArrowLeft2 size={14} color="#123A72" className="ltr:-scale-x-100" />
        </Link>
      )}

      {/* Directions at the start; the phone, the website and the rest at the
          end, each only where the business has one (none for a park). */}
      <div className="mt-7 flex items-center gap-3 px-4">
        <TrackedLink stat="directions" href={waze} className="flex h-10 items-center gap-1.5 rounded-full bg-midblue px-6 text-sm font-medium text-white">
          <DirectionMark size={16} className="text-white" />{t('ניווט', 'Get Directions')}
        </TrackedLink>
        <span className="flex-1" />
        {v.phone && <TrackedLink stat="call" href={`tel:${v.phone}`} newTab={false} className={circle} label={t('התקשרו', 'Call')}><Call size={20} color="#17A9D0" /></TrackedLink>}
        {v.website && <TrackedLink stat="website" href={webLink(v.website)} className={circle} label={t('אתר', 'Website')}><Global size={20} color="#17A9D0" /></TrackedLink>}
        {v.whatsapp && <TrackedLink stat="whatsapp" href={`https://wa.me/${waNumber(v.whatsapp)}`} className={circle} label="WhatsApp"><Messages2 size={20} color="#17A9D0" /></TrackedLink>}
        {v.instagram && <TrackedLink stat="instagram" href={webLink(v.instagram)} className={circle} label="Instagram"><Instagram size={20} color="#17A9D0" /></TrackedLink>}
      </div>

      <div className="mt-4"><PhoneTabs tabs={tabs} /></div>
    </div>
  );
}

/** Overview: About and the hours, the gallery strip, the reviews. */
function PhoneOverview({ v }: { v: View }) {
  const { t, he } = v;
  const byDay = new Map(v.hours.map((h) => [h.day, h]));
  const days: Record<number, [string, string]> = { 1: ['יום שני', 'Mon'], 2: ['יום שלישי', 'Tue'], 3: ['יום רביעי', 'Wed'], 4: ['יום חמישי', 'Thu'], 5: ['יום שישי', 'Fri'], 6: ['שבת', 'Sat'], 7: ['יום ראשון', 'Sun'] };
  return (
    <>
      <section className="mx-4 border-b border-line py-6">
        <h2 className={phoneTitle}>{t(`אודות ${v.name}`, `About ${v.name}`)}</h2>
        {v.about && <div className="mt-3"><ExpandableText text={v.about} more={t('הצג עוד', 'See more')} less={t('הצג פחות', 'See less')} className="text-sm leading-[1.6] text-[#3D3D3D]" /></div>}
        {v.hours.length > 0 ? (
          <>
            <h3 className={`mt-6 ${phoneTitle}`}>{t('שעות פתיחה', 'Working Hours')}</h3>
            <ul className="mt-5 flex flex-col gap-5">
              {[1, 2, 3, 4, 5, 6, 7].map((d) => {
                const h = byDay.get(d);
                const closed = !h || !h.open || !h.close;
                return (
                  <li key={d} className="flex justify-between text-sm font-medium text-[#3D3D3D]">
                    <span>{days[d][he ? 0 : 1]}</span>
                    <span dir="ltr" className={closed ? 'text-[#F21C1C]' : ''}>{closed ? t('סגור', 'Closed') : `${h!.open} - ${h!.close}`}</span>
                  </li>
                );
              })}
            </ul>
          </>
        ) : v.hoursText ? (
          <>
            <h3 className={`mt-6 ${phoneTitle}`}>{t('שעות פתיחה', 'Opening hours')}</h3>
            <div className="mt-3"><HoursLines text={v.hoursText} he={he} /></div>
          </>
        ) : v.b.google_place_id ? <GoogleHours placeId={v.b.google_place_id} lang={v.lang} phone /> : null}
      </section>
      {v.photos.length > 0 && (
        <section className="border-b border-line py-6">
          <h2 className={`px-4 ${phoneTitle}`}>{t('גלריית העסק', 'Business Gallery')}</h2>
          <div className="mt-4 flex gap-2.5 overflow-x-auto px-4 [scrollbar-width:none]">
            {v.photos.map((_, i) => <PhotoThumb key={i} index={i} width={100} className="size-[100px] rounded-lg" />)}
          </div>
        </section>
      )}
      <section className="border-b border-line py-6">
        <h2 className={`px-4 ${phoneTitle}`}>{t(`ביקורות על ${v.name}`, `Reviews for ${v.name}`)}</h2>
        <div className="mt-4"><PhoneSummary v={v} /></div>
        <div className="mt-6"><PhoneReviewList v={v} /></div>
      </section>
    </>
  );
}

/** The score and its spread; "Not rated yet" when nobody has rated it. */
function PhoneSummary({ v }: { v: View }) {
  const { t } = v;
  const total = v.reviews.length;
  if (!total) return <p className="px-4 py-2 text-sm text-[#6D6D6D]">{t('אין דירוג עדיין', 'Not rated yet')}</p>;
  const avg = v.reviews.reduce((s, r) => s + r.rating, 0) / total;
  const pct = (score: number) => Math.round((v.reviews.filter((r) => r.rating === score).length / total) * 100);
  return (
    <div className="flex items-start gap-4 px-4">
      <div className="w-[153px] shrink-0 border-e border-line py-4 pe-4">
        <p className="text-[32px] font-semibold leading-tight text-black">{avg.toFixed(1)}</p>
        <PhoneStars value={Math.round(avg)} size={20} className="mt-4 gap-[5.83px]" />
        <p className="mt-4 text-xs text-[#3D3D3D]">{t(`מבוסס על ${total} ביקורות`, `Based on ${total} reviews`)}</p>
      </div>
      <div className="flex flex-1 flex-col gap-2">
        {[5, 4, 3, 2, 1].map((s) => (
          <div key={s} className="flex h-[22px] items-center">
            <span className="w-3 text-sm font-medium text-black">{s}</span>
            <Star1 size={12} color="#FFC107" variant="Bold" className="ms-2" />
            <span className="ms-[11px] h-1.5 flex-1 overflow-hidden rounded-md bg-line"><span className="block h-full rounded-md bg-turquoise" style={{ width: `${pct(s)}%` }} /></span>
            <span className="ms-[11px] w-[38px] text-end text-xs font-medium text-[#6D6D6D]">{pct(s)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function PhoneStars({ value, size, className = '' }: { value: number; size: number; className?: string }) {
  return (
    <span className={`flex ${className}`}>
      {[1, 2, 3, 4, 5].map((i) => <Star1 key={i} size={size} color={i <= value ? '#FFC107' : '#D1D1D1'} variant="Bold" />)}
    </span>
  );
}

/** The approved reviews and their residents' replies; an empty state when
 *  there are none. */
function PhoneReviewList({ v }: { v: View }) {
  const { t } = v;
  if (!v.reviews.length) {
    return (
      <div className="flex flex-col items-center px-4 py-8 text-center">
        <span className="flex size-16 items-center justify-center rounded-full bg-[#F5F5F5]"><MessageText1 size={28} color="#6D6D6D" /></span>
        <p className="mt-4 text-base font-semibold text-[#1F1F1F]">{t('אין עדיין ביקורות', 'No reviews yet')}</p>
        <p className="mt-1.5 text-[13px] text-[#6D6D6D]">{t('היו הראשונים לכתוב ביקורת על המקום הזה', 'Be the first to review this place')}</p>
      </div>
    );
  }
  return (
    <ul className="px-4">
      {v.reviews.map((r) => (
        <li key={r.id} className="flex gap-3 border-b border-line py-4 last:border-b-0">
          <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-turquoise text-[11.2px] font-semibold text-white">{r.initials}</span>
          <div className="min-w-0 flex-1">
            <p className="flex flex-wrap items-center gap-x-3">
              <span className="text-sm font-medium text-black">{r.author}</span>
              <span className="text-[10px] text-[#6D6D6D]">{r.date}</span>
            </p>
            <PhoneStars value={r.rating} size={14} className="mt-[7px] gap-1" />
            <p className="mt-[7px] whitespace-pre-line text-xs leading-[1.4] text-[#3D3D3D]">{r.body}</p>
            {r.replies.map((x) => (
              <div key={x.id} className="mt-2.5 flex gap-2 border-s-2 border-line py-1 ps-2.5">
                <span className="flex size-6 shrink-0 items-center justify-center rounded-full bg-[#E8EEF7] text-[9px] font-semibold text-midblue">{x.author ? initials(x.author) : '?'}</span>
                <div className="min-w-0 flex-1">
                  <p className="flex flex-wrap items-center gap-x-2">
                    <span className="text-xs font-medium text-black">{x.author}</span>
                    <span className="text-[10px] text-[#6D6D6D]">{x.date}</span>
                  </p>
                  <p className="mt-1 whitespace-pre-line text-xs leading-[1.4] text-[#3D3D3D]">{x.body}</p>
                </div>
              </div>
            ))}
          </div>
        </li>
      ))}
    </ul>
  );
}

function PhoneMenu({ v }: { v: View }) {
  return (
    <div className="p-4">
      {sections(v.menu, false).map(([sec, items]) => (
        <div key={sec} className="pt-2">
          {sec && <h3 className="mb-3 text-base font-semibold text-[#1F1F1F]">{sec}</h3>}
          {items.map((i) => (
            <div key={i.id} className="flex items-start gap-3 pb-3">
              <div className="min-w-0 flex-1">
                <p className="text-sm text-[#3D3D3D]">{i.name}</p>
                {i.description && <p className="mt-0.5 text-xs text-[#6D6D6D]">{i.description}</p>}
              </div>
              {price(i.price_agorot) && <span className="text-sm font-medium text-black">{price(i.price_agorot)}</span>}
            </div>
          ))}
          <hr className="my-3 border-line" />
        </div>
      ))}
    </div>
  );
}

function PhonePhotos({ v }: { v: View }) {
  if (!v.photos.length) {
    return (
      <div className="flex flex-col items-center px-4 py-8">
        <span className="flex size-16 items-center justify-center rounded-full bg-[#F5F5F5]"><Gallery size={28} color="#6D6D6D" /></span>
        <p className="mt-4 text-base font-semibold text-[#1F1F1F]">{v.t('אין עדיין תמונות', 'No photos yet')}</p>
      </div>
    );
  }
  return (
    <div className="grid grid-cols-3 gap-2 p-4 min-[732px]:grid-cols-4">
      {v.photos.map((_, i) => <PhotoThumb key={i} index={i} width={240} className="aspect-square w-full rounded-[10px]" />)}
    </div>
  );
}
