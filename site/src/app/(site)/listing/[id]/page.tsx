import type { Metadata } from 'next';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { ArrowLeft2, Box1, Brush2, Export, HomeHashtag, Location, Map1, Profile2User, User } from 'iconsax-react';
import { getLang, tr } from '@/lib/i18n';
import { breadcrumb, href, organization, pageMetadata, plain, SITE_NAME, SUFFIX, h1For } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { agentContact, hoodBusinesses, listingById, nearbyListings } from '@/lib/data/realestate';
import { JsonLd } from '@/components/JsonLd';
import { MapView } from '@/components/map/MapView';
import { ListingCard } from '@/components/realestate/ListingCard';
import { BusinessCard } from '@/components/realestate/BusinessCard';
import { Carousel } from '@/components/realestate/Carousel';
import { Mosaic, PhoneGallery } from '@/components/realestate/Gallery';
import { ContactMenu, ShareMenu } from '@/components/realestate/Menus';
import { contactOptions, hoodName, kindLabel, paragraphs, priceOf, roomsText, shekels } from '@/components/realestate/format';

type Props = { params: Promise<{ id: string }> };

const A = '/web/realestate';

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;
  const l = await listingById(id);
  if (!l) return {};
  return pageMetadata({
    path: `/listing/${id}/`,
    title: l.title + SUFFIX,
    description: plain(l.description, 160) || null,
    image: l.cover_url || l.gallery?.[0] || null,
    modifiedTime: l.updated_at,
  });
}

/**
 * One apartment (web_listing_detail_screen.dart; phone: listing_detail_screen
 * .dart): the title, the photographs, the price and figures, what the flat
 * has, where it is, the neighbourhood, and whom to call — then the other
 * flats and the businesses in the same neighbourhood. Everything from the
 * listing row, its agent and its neighbourhood; a section with nothing
 * behind it is left out. The heart (saving) and the report button need an
 * account, and accounts are the app's.
 */
export default async function ListingPage({ params }: Props) {
  const { id } = await params;
  const l = await listingById(id);
  if (!l) notFound();
  const lang = await getLang();
  const t = tr(lang);
  const path = `/listing/${l.id}/`;
  const hood = hoodName(l, lang);
  const [nearby, agent, businesses] = await Promise.all([
    nearbyListings(l),
    agentContact(l.agent_id),
    l.neighborhood_id && hood ? hoodBusinesses(l.neighborhood_id, lang) : Promise.resolve([]),
  ]);

  const photos = [...(l.cover_url ? [l.cover_url] : []), ...(l.gallery ?? []).filter((u) => u && u !== l.cover_url)];
  const price = priceOf(l);
  const rent = l.kind === 'rent';
  const where = l.address ?? hood;
  const about = (l.description ?? '').trim();
  const hoodText = paragraphs(l.neighborhoods?.description);
  const url = SITE_URL + href(path);

  // Whom to call: the agent, or the contact the client entered with the
  // listing. Nothing at all when the listing has neither.
  const name = l.real_estate_agents?.name ?? l.contact_name;
  const phone = l.real_estate_agents?.phone ?? l.contact_phone;
  const isAgent = !!l.real_estate_agents?.name;
  const reach = contactOptions({ phone: agent?.phone ?? phone, whatsapp: agent?.whatsapp ?? agent?.phone ?? phone, email: agent?.email }, lang, false);

  const highlights: { label: string; value: string; icon: string }[] = [];
  if (l.rooms != null) highlights.push({ label: t('חדרים', 'Rooms'), value: roomsText(l.rooms), icon: 'detail_hl_rooms' });
  if (l.bathrooms != null) highlights.push({ label: t('חדרי רחצה', 'Bathrooms'), value: String(l.bathrooms), icon: 'detail_hl_bath' });
  if (l.sqm != null) highlights.push({ label: t('שטח בנוי', 'Built-up Area'), value: t(`${l.sqm} מ״ר`, `${l.sqm} m²`), icon: 'detail_hl_area' });
  if (l.floor != null) highlights.push({ label: t('קומה', 'Floor'), value: l.floor === 0 ? t('קומת קרקע', 'Ground Floor') : t(`קומה ${l.floor}`, `${l.floor} Floor`), icon: 'detail_hl_floor' });

  // The design's four with the row's answer under each, then any further
  // feature the flat has. The phone layout lists only what the flat has.
  const specs: { label: string; on: boolean; icon: React.ReactNode; phone: number | null }[] = [
    { label: t('מרפסת', 'Balcony'), on: !!l.has_balcony, icon: <img src={`${A}/detail_spec_balcony.svg`} alt="" className="size-8 p-[3px] desk:p-0" />, phone: 1 },
    { label: t('חניה', 'Parking'), on: !!l.has_parking, icon: <img src={`${A}/detail_spec_parking.svg`} alt="" className="size-8 p-[3px] desk:p-0" />, phone: 2 },
    { label: t('מעלית', 'Elevator'), on: !!l.has_elevator, icon: <img src={`${A}/detail_spec_elevator.svg`} alt="" className="size-8 p-[3px] desk:p-0" />, phone: 3 },
    { label: t('ממ״ד', 'Protected Space'), on: !!l.has_mamad, icon: <img src={`${A}/detail_spec_mamad.svg`} alt="" className="size-8 p-[3px] desk:p-0" />, phone: 5 },
    ...(l.has_storage ? [{ label: t('מחסן', 'Storage'), on: true, icon: <Box1 size={30} color="#123A72" />, phone: 4 }] : []),
    ...(l.is_furnished ? [{ label: t('מרוהטת', 'Furnished'), on: true, icon: <HomeHashtag size={30} color="#123A72" />, phone: null }] : []),
    ...(l.is_accessible ? [{ label: t('נגישה', 'Accessible'), on: true, icon: <Profile2User size={30} color="#123A72" />, phone: null }] : []),
    ...(l.is_renovated ? [{ label: t('משופצת', 'Renovated'), on: true, icon: <Brush2 size={30} color="#123A72" />, phone: null }] : []),
  ];
  const phoneSpecs = specs.some((s) => s.on && s.phone != null);

  // Text from the database reads in its own direction, lined up with the
  // page (DetailText): a Hebrew paragraph on the English page starts on the left.
  const align = lang === 'he' ? 'text-right' : 'text-left';
  const heading = 'text-base font-semibold text-[#1F1F1F] desk:font-nunito desk:text-2xl desk:leading-[30px] desk:text-midblue';
  const residence = l.property_type === 'villa' ? 'SingleFamilyResidence' : l.property_type === 'other' ? 'Residence' : 'Apartment';
  const hoodPath = l.neighborhood_id ? `/neighborhood/${l.neighborhood_id}/` : null;

  return (
    <article className="pb-10 desk:pb-[167px]">
      <JsonLd data={[
        {
          '@context': 'https://schema.org', '@type': 'Offer', name: l.title, url,
          ...(about ? { description: plain(about, 500) } : {}),
          ...(photos.length ? { image: photos.slice(0, 6) } : {}),
          businessFunction: rent ? 'http://purl.org/goodrelations/v1#LeaseOut' : 'http://purl.org/goodrelations/v1#Sell',
          ...(price != null ? { price, priceCurrency: 'ILS' } : {}),
          ...(price != null && rent ? { priceSpecification: { '@type': 'UnitPriceSpecification', price, priceCurrency: 'ILS', unitCode: 'MON' } } : {}),
          availability: 'https://schema.org/InStock',
          ...(isAgent ? { offeredBy: { '@type': 'RealEstateAgent', name: l.real_estate_agents!.name, ...(phone ? { telephone: phone } : {}) } } : { seller: organization() }),
          itemOffered: {
            '@type': residence, name: l.title,
            ...(l.rooms != null ? { numberOfRooms: l.rooms } : {}),
            ...(l.bathrooms != null ? { numberOfBathroomsTotal: l.bathrooms } : {}),
            ...(l.sqm != null ? { floorSize: { '@type': 'QuantitativeValue', value: l.sqm, unitCode: 'MTK' } } : {}),
            ...(l.floor != null ? { floorLevel: String(l.floor) } : {}),
            ...(l.address ? { address: { '@type': 'PostalAddress', streetAddress: l.address, addressCountry: 'IL' } } : {}),
            ...(l.latitude != null && l.longitude != null ? { geo: { '@type': 'GeoCoordinates', latitude: l.latitude, longitude: l.longitude } } : {}),
            ...(hood ? { containedInPlace: { '@type': 'Place', name: hood, ...(hoodPath ? { url: SITE_URL + href(hoodPath) } : {}) } } : {}),
            amenityFeature: specs.slice(0, 4).map((s) => ({ '@type': 'LocationFeatureSpecification', name: s.label, value: s.on }))
              .concat(specs.slice(4).map((s) => ({ '@type': 'LocationFeatureSpecification', name: s.label, value: true }))),
          },
        },
        breadcrumb([[SITE_NAME, '/'], ['נדל״ן', '/search-apartments/'], ...(hood && hoodPath ? [[hood, hoodPath] as [string, string]] : []), [l.title, path]]),
      ]} />

      {/* PHONE — the photographs, then the price. */}
      <div className="desk:hidden">
        <PhoneGallery photos={photos} alt={l.title} back="/search-apartments/" backLabel={t('חזרה לנדל״ן', 'Back to Real Estate')}
          corner={<ShareMenu url={url} title={l.title} lang={lang} place="end"
            className="flex size-10 items-center justify-center rounded-full bg-white text-[#3D3D3D]" icon={<Export size={20} color="currentColor" />} />} />
        {price != null && (
          <p className="flex items-center gap-1.5 px-4 pt-6">
            <span dir="ltr" className="font-nunito text-[28px] font-semibold text-black">{shekels(price)}</span>
            {rent && <span className="text-sm text-gray-text">{t('לחודש', '/ month')}</span>}
          </p>
        )}
      </div>

      {/* TITLE — back, title, where, kind */}
      <div className="px-4 desk:px-[clamp(24px,4.5vw,80px)]">
        <header className="mx-auto max-w-[1200px] pt-3 desk:pt-8">
          <div className="flex items-center gap-2 desk:min-h-10">
            <Link href="/search-apartments/" aria-label={t('חזרה לנדל״ן', 'Back to Real Estate')} className="hidden shrink-0 desk:block">
              <img src={`${A}/detail_back.svg`} alt="" width={24} height={24} className="rtl:-scale-x-100" />
            </Link>
            <h1 dir="auto" className="text-lg font-semibold text-black desk:font-nunito desk:text-[28px] desk:leading-[34px] desk:text-navy">{h1For(path, l.title)}</h1>
          </div>
          <div className="mt-3 flex items-center gap-4">
            {where && (
              <p className="flex min-w-0 items-center gap-2 text-sm text-[#6D6D6D] desk:text-black">
                <Location size={16} color="#888888" className="shrink-0 desk:hidden" />
                <span className="hidden size-4 shrink-0 items-center justify-center desk:flex"><img src={`${A}/detail_pin.svg`} alt="" width={12} height={16} /></span>
                <span dir="auto" className="truncate">{where}</span>
              </p>
            )}
            <span className="hidden shrink-0 rounded-full bg-[#0033AC]/20 px-4 py-1.5 text-xs font-medium leading-[15px] text-[#0033AC] desk:inline">{kindLabel(l.kind, lang, false)}</span>
          </div>
        </header>
      </div>

      <div className="px-4 desk:px-[clamp(24px,4.5vw,80px)]">
        <div className="mx-auto max-w-[1200px]">
          {/* DESKTOP — the photographs */}
          <div className="mt-8 hidden desk:block">
            <Mosaic photos={photos} alt={l.title} fourUp height={514} radius={12} gap={10} inset={16} showAll={t('כל התמונות', 'Show all photos')} />
          </div>

          <div className="desk:mt-7 desk:grid desk:grid-cols-[minmax(0,720px)_minmax(32px,1fr)_374px] desk:items-start">
            {/* Price (desktop) */}
            <div className="hidden desk:col-start-1 desk:block">
              {price == null
                ? <p className="text-[22px] font-semibold text-navy">{t('מחיר לפי בקשה', 'Price on request')}</p>
                : <p className="flex items-baseline gap-2"><span dir="ltr" className="text-[32px] font-semibold leading-[39px] text-navy">{shekels(price)}</span>{rent && <span className="text-base text-gray-text">{t('/ לחודש', '/ month')}</span>}</p>}
              {where && <p className="mt-4 flex items-center gap-2 text-sm"><span className="flex size-4 items-center justify-center"><img src={`${A}/detail_pin.svg`} alt="" width={12} height={16} /></span>{where}</p>}
            </div>

            {/* Highlights (desktop): only the figures the row carries, two
                to a row. The listing records rooms, not bedrooms. */}
            {highlights.length > 0 && (
              <section className="mt-12 hidden max-w-[683px] desk:col-start-1 desk:block">
                <h2 className={heading}>{t('נקודות בולטות', 'Highlights')}</h2>
                <div className="mt-8 grid grid-cols-2 gap-x-5 gap-y-8">
                  {highlights.map((h) => (
                    <div key={h.icon} className="flex items-start gap-4">
                      <img src={`${A}/${h.icon}.svg`} alt="" width={32} height={32} className="size-8" />
                      <div>
                        <p className="text-xs text-gray-text">{h.label}</p>
                        <p className="mt-1.5 text-lg font-semibold leading-[22px]">{h.value}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </section>
            )}

            {/* Area, rooms, bathrooms (phone) */}
            {(l.sqm != null || l.rooms != null || l.bathrooms != null) && (
              <div className="mt-5 flex gap-2.5 desk:hidden">
                {[
                  l.sqm != null && ['m_realestate_stat_area', String(l.sqm), t('מ״ר', 'm²')],
                  l.rooms != null && ['m_realestate_stat_bed', roomsText(l.rooms), t('חדרים', 'Rooms')],
                  l.bathrooms != null && ['m_realestate_stat_bath', String(l.bathrooms), t('חדרי רחצה', 'Bathrooms')],
                ].filter((x): x is string[] => !!x).map(([icon, value, unit]) => (
                  <div key={icon} className="flex h-[77px] min-w-0 flex-1 flex-col justify-between rounded-lg border border-line p-3">
                    <img src={`/icons/${icon}.svg`} alt="" width={20} height={20} className="size-5" />
                    <p className="flex min-w-0 items-baseline gap-1"><span className="text-base font-medium text-black">{value}</span><span className="truncate text-sm text-[#3D3D3D]">{unit}</span></p>
                  </div>
                ))}
              </div>
            )}

            {/* Whom to call (desktop card) */}
            {(name || phone) && (
              <aside className="hidden rounded-xl border border-line bg-white p-4 desk:col-start-3 desk:row-span-6 desk:row-start-1 desk:mt-1.5 desk:block">
                <p className="text-lg font-semibold leading-[22px] text-navy">{t('צרו קשר לגבי הנכס', 'Contact This Property')}</p>
                {isAgent && <p className="mt-2 text-sm text-[#3D3D3D]">{t('דברו עם מומחה הנדל״ן שלנו', 'Get in touch with our real estate expert')}</p>}
                <div className="mt-[25px] flex items-center gap-3">
                  <AgentPhoto url={l.real_estate_agents?.photo_url ?? null} size={56} />
                  <div className="min-w-0">
                    <p className="truncate text-base font-semibold">{name ?? phone}</p>
                    {l.real_estate_agents?.agency && <p className="mt-2 truncate text-xs text-[#6D6D6D]">{l.real_estate_agents.agency}</p>}
                  </div>
                </div>
                {(phone || l.agent_id) && reach.length > 0 && (
                  <div className="mt-[26px]">
                    <ContactMenu options={reach} label={t('צרו קשר', 'Contact')} place="match"
                      className="flex h-11 w-full items-center justify-center rounded-[60px] bg-midblue text-base font-medium text-white hover:bg-midblue/90" />
                  </div>
                )}
                <div className="mt-3">
                  <ShareMenu url={url} title={l.title} lang={lang} label={t('שיתוף', 'Share')} place="match"
                    className="flex h-11 w-full items-center justify-center rounded-[60px] border border-midblue text-base font-medium text-midblue hover:bg-midblue/5" />
                </div>
              </aside>
            )}

            {/* Whom to call (phone) */}
            {(name || phone) && (
              <section className="mt-6 desk:hidden">
                <h2 className={heading}>{t('איש קשר', 'Contact person')}</h2>
                <div className="mt-3 flex items-center gap-3 rounded-xl bg-[#F6F6F6] p-3">
                  <AgentPhoto url={l.real_estate_agents?.photo_url ?? null} size={40} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium text-black">{name ?? phone}</p>
                    {l.real_estate_agents?.agency && <p className="mt-1 truncate text-xs text-[#6D6D6D]">{l.real_estate_agents.agency}</p>}
                  </div>
                  {(phone || l.agent_id) && reach.length > 0 && (
                    <ContactMenu options={reach} direct label={t('צור קשר', 'Contact')}
                      className="flex h-[37px] shrink-0 items-center rounded-[60px] bg-midblue px-[18px] text-sm font-medium text-white" />
                  )}
                </div>
              </section>
            )}

            {/* About this property */}
            {about && (
              <section className="mt-8 desk:col-start-1 desk:mt-[63px]">
                <h2 className={heading}>{t('על הנכס', 'About This Property')}</h2>
                <div className="mt-3 flex max-w-[620px] flex-col gap-4 text-sm leading-[1.6] text-[#3D3D3D] desk:mt-6 desk:text-base">
                  {paragraphs(about).map((p, i) => <p key={i} dir="auto" className={`whitespace-pre-line ${align}`}>{p}</p>)}
                </div>
              </section>
            )}

            {/* Property specifications */}
            <section className={`mt-8 desk:col-start-1 desk:mt-[63px] desk:block ${phoneSpecs ? '' : 'hidden'}`}>
              <h2 className={heading}>{t('מפרט הנכס', 'Property Specifications')}</h2>
              <div className="mt-3 grid grid-cols-2 gap-3 desk:mt-[23px] desk:grid-cols-4 desk:gap-4">
                {specs.map((s) => (
                  <div key={s.label}
                    style={{ order: s.phone ?? undefined }}
                    className={`flex flex-col items-center rounded-xl border border-line bg-white px-[9px] py-5 text-center desk:!order-none desk:flex desk:px-4 ${s.on && s.phone != null ? '' : 'hidden'}`}>
                    <span className="flex size-8 items-center justify-center">{s.icon}</span>
                    <p className="mt-3 truncate text-sm font-medium text-black desk:mt-4">{s.label}</p>
                    <p className="mt-1 text-sm text-black desk:mt-2">
                      <span className="desk:hidden">{t('כן', 'Yes')}</span>
                      <span className="hidden desk:inline">{s.on ? t('יש', 'Yes') : t('אין', 'No')}</span>
                    </p>
                  </div>
                ))}
              </div>
            </section>

            {/* Where you'll be: the listing on the map, only when it has
                coordinates. The map's tiles drawn pale, as designed. */}
            {l.latitude != null && l.longitude != null && (
              <section className="mt-8 desk:col-start-1 desk:mt-16">
                <h2 className={heading}>
                  <span className="desk:hidden">{t('איפה זה נמצא', "Where You'll Be")}</span>
                  <span className="hidden desk:inline">{t('איפה זה', 'Where You’ll Be')}</span>
                </h2>
                <div className="relative mt-3 h-[230px] overflow-hidden rounded-xl desk:mt-6 desk:h-80 desk:rounded-2xl desk:[&_.leaflet-tile-pane]:[filter:saturate(.35)_brightness(1.04)]">
                  <MapView pins={[{ id: l.id, lat: l.latitude, lng: l.longitude, icon: `${A}/detail_map_marker.svg`, size: [48, 52] }]}
                    center={[l.latitude, l.longitude]} zoom={15} interactive={false} lang={lang} />
                  <a href={`https://www.google.com/maps/search/?api=1&query=${l.latitude},${l.longitude}`} target="_blank" rel="noopener"
                    className="absolute bottom-[17px] left-1/2 z-[500] flex -translate-x-1/2 items-center gap-1.5 rounded-full bg-white px-4 py-3 text-sm font-medium text-navy shadow-[0_4px_8px_rgba(0,0,0,0.15)] desk:hidden">
                    <Map1 size={16} color="currentColor" />{t('הצג במפה', 'View on Map')}
                  </a>
                </div>
              </section>
            )}

            {/* About the neighbourhood: a taste of what the client wrote,
                faded, with "Read More" leading to the neighbourhood's own
                page. The website opens on the paragraphs after the first,
                which the neighbourhood page uses as its introduction. */}
            {hood && (
              <section className={`mt-8 desk:col-start-1 desk:mt-16 ${hoodText.length ? '' : 'desk:hidden'}`}>
                <h2 className={heading}>
                  {hoodPath
                    ? <Link href={hoodPath} className="flex items-center justify-between gap-2 desk:inline">{t(`על ${hood}`, `About ${hood}`)}<ArrowLeft2 size={18} color="#123A72" className="shrink-0 ltr:-scale-x-100 desk:hidden" /></Link>
                    : t(`על ${hood}`, `About ${hood}`)}
                </h2>
                {hoodText.length > 0 && <HoodText paras={hoodText} more={hoodPath} label={t('קראו עוד', 'Read More')} less={t('הצג פחות', 'Show less')} align={align} />}
              </section>
            )}
          </div>
        </div>
      </div>

      {/* Other flats in the same neighbourhood */}
      {nearby.length > 0 && hood && (
        <>
          <section className="mt-8 px-4 desk:hidden">
            <h2 className={heading}>{t(`נכסים ב${hood}`, `Properties in ${hood}`)}</h2>
            <div className="mt-3 flex flex-col gap-4">{nearby.map((n) => <ListingCard key={n.id} l={n} lang={lang} variant="phone" />)}</div>
          </section>
          <Strip title={t(`נכסים ב${hood}`, `Properties in ${hood}`)} lang={lang} arrowTop={111}>
            {nearby.map((n) => (
              <div key={n.id} className="h-[261px] w-[calc((100%-48px)/4)] shrink-0 snap-start">
                <ListingCard l={n} lang={lang} variant="small" />
              </div>
            ))}
          </Strip>
        </>
      )}

      {/* The businesses filed under the same neighbourhood (website) */}
      {businesses.length > 0 && hood && (
        <Strip title={t(`עסקים ב${hood}`, `Businesses in ${hood}`)} lang={lang} arrowTop={104}>
          {businesses.map((b) => (
            <div key={b.id} className="h-[248px] w-[calc((100%-48px)/4)] shrink-0 snap-start">
              <BusinessCard b={b} lang={lang} />
            </div>
          ))}
        </Strip>
      )}
    </article>
  );
}

/** A heading over a carousel, in the 1200 column (DetailStrip). */
function Strip({ title, lang, arrowTop, children }: { title: string; lang: 'he' | 'en'; arrowTop: number; children: React.ReactNode }) {
  return (
    <section className="mt-16 hidden px-[clamp(24px,4.5vw,80px)] desk:block">
      <div className="mx-auto max-w-[1200px]">
        <h2 className="line-clamp-2 font-nunito text-2xl font-semibold leading-[30px] text-midblue">{title}</h2>
        <div className="mt-6">
          <Carousel arrowTop={arrowTop} lang={lang}>{children}</Carousel>
        </div>
      </div>
    </section>
  );
}

function AgentPhoto({ url, size }: { url: string | null; size: number }) {
  return url
    ? <img src={url} alt="" width={size} height={size} className="shrink-0 rounded-full object-cover" style={{ width: size, height: size }} />
    : <span className="flex shrink-0 items-center justify-center rounded-full bg-[linear-gradient(135deg,#0058B5,#010A36)] text-white/30" style={{ width: size, height: size }}><User size={size * 0.43} color="currentColor" variant="Bold" /></span>;
}

/** The neighbourhood's text, faded under "Read More": five lines on a phone,
 *  opened in place there (listing_detail_screen.dart); about two paragraphs
 *  on the website, where it opens the neighbourhood's page. A short text is
 *  shown whole. The phone's toggle is a checkbox, so it needs no script. */
function HoodText({ paras, more, label, less, align }: { paras: string[]; more: string | null; label: string; less: string; align: string }) {
  const shownOnDesk = paras.length > 1 ? paras.slice(1) : paras;
  const long = (n: string[]) => n.join(' ').length > 240;
  const fadePhone = long(paras);
  const fadeDesk = long(shownOnDesk);
  const fade = (fadePhone ? 'max-h-[112px] overflow-hidden max-desk:group-has-[:checked]:max-h-none' : '') + ' ' + (fadeDesk ? 'desk:max-h-[232px] desk:overflow-hidden' : 'desk:max-h-none');
  return (
    <div className="group relative mt-3 desk:mt-6">
      {fadePhone && <input type="checkbox" id="hood-more" className="peer sr-only desk:hidden" />}
      <div className="relative">
        <div className={`flex flex-col gap-3 text-sm leading-[1.6] text-[#3D3D3D] desk:gap-6 desk:text-base ${fade}`}>
          {paras.map((p, i) => <p key={i} dir="auto" className={`whitespace-pre-line ${align} ${i === 0 && paras.length > 1 ? 'desk:hidden' : ''}`}>{p}</p>)}
        </div>
        <span className={`pointer-events-none absolute inset-x-0 bottom-0 h-[60px] bg-gradient-to-b from-white/0 to-white max-desk:group-has-[:checked]:hidden desk:top-2.5 desk:h-auto desk:bg-[linear-gradient(to_bottom,rgba(255,255,255,0),#fff_98%)] ${fadePhone ? '' : 'hidden'} ${fadeDesk ? 'desk:block' : 'desk:hidden'}`} />
      </div>
      {fadePhone && (
        <div className="mt-3 flex justify-center desk:hidden">
          <label htmlFor="hood-more" className="cursor-pointer rounded-[60px] border border-midblue bg-white px-6 py-2 text-sm font-medium text-midblue">
            <span className="group-has-[:checked]:hidden">{label}</span>
            <span className="hidden group-has-[:checked]:inline">{less}</span>
          </label>
        </div>
      )}
      {fadeDesk && more && (
        <div className="hidden desk:absolute desk:inset-x-0 desk:bottom-[7px] desk:flex desk:justify-center">
          <Link href={more} className="rounded-[60px] border border-midblue bg-white px-8 py-2.5 text-base font-medium leading-6 text-midblue">{label}</Link>
        </div>
      )}
    </div>
  );
}
