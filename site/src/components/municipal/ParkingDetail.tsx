'use client';
import { useEffect, useMemo, useState } from 'react';
import { Call, Car, Card, Clock, Global, Note1, Star1, Ticket } from 'iconsax-react';
import { MapView, type MapPin } from '@/components/map/MapView';
import type { Lang } from '@/lib/i18n';
import { googleMapsUrl, lotName, wazeUrl, type ParkingLot } from '@/lib/data/municipal-shared';
import { Directions } from './Directions';
import { FreeTag } from './ParkingExplorer';

/** The website's Places key, restricted by Google to the site's addresses.
 *  Without it — a local build — the page shows what the client entered. */
const KEY = process.env.NEXT_PUBLIC_PLACES_WEB_KEY ?? '';

/** What Google Maps knows about a car park (google_place.dart). Google's
 *  terms let us keep a place's ID but not its details, so they are asked for
 *  each time the page opens, in the page's language, and shown with
 *  Google's attribution. A field Google lacks is left out. */
type Google = {
  name: string | null; address: string | null; hours: string[]; rating: number | null; ratingCount: number;
  photos: { name: string; authors: string[] }[];
  cards: boolean | null; debit: boolean | null; cashOnly: boolean | null; nfc: boolean | null;
  phone: string | null; website: string | null; mapsUri: string | null;
};

async function fetchPlace(placeId: string, lang: Lang): Promise<Google | null> {
  try {
    const r = await fetch(`https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?languageCode=${lang}`, {
      headers: {
        'X-Goog-Api-Key': KEY,
        'X-Goog-FieldMask': 'displayName,formattedAddress,regularOpeningHours.weekdayDescriptions,rating,userRatingCount,photos,paymentOptions,nationalPhoneNumber,websiteUri,googleMapsUri',
      },
    });
    if (!r.ok) return null;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const j: any = await r.json();
    const pay = j.paymentOptions ?? {};
    return {
      name: j.displayName?.text ?? null,
      address: j.formattedAddress ?? null,
      hours: j.regularOpeningHours?.weekdayDescriptions ?? [],
      rating: typeof j.rating === 'number' ? j.rating : null,
      ratingCount: j.userRatingCount ?? 0,
      // Four at most: each photo shown is a billed request.
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      photos: (j.photos ?? []).slice(0, 4).map((p: any) => ({
        name: p.name as string,
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        authors: (p.authorAttributions ?? []).map((a: any) => a.displayName ?? '').filter(Boolean),
      })),
      cards: pay.acceptsCreditCards ?? null, debit: pay.acceptsDebitCards ?? null,
      cashOnly: pay.acceptsCashOnly ?? null, nfc: pay.acceptsNfc ?? null,
      phone: j.nationalPhoneNumber ?? null, website: j.websiteUri ?? null, mapsUri: j.googleMapsUri ?? null,
    };
  } catch {
    return null;
  }
}

/** Google's "יום ראשון: 7:00–0:00" with the hours isolated left to right,
 *  so a range reads from opening to closing in Hebrew too. */
function hoursLine(line: string): string {
  const i = line.indexOf(': ');
  return i < 0 ? line : `${line.slice(0, i + 2)}⁦${line.slice(i + 2)}⁩`;
}

function Section({ icon, title, children }: { icon: React.ReactNode; title: string; children?: React.ReactNode }) {
  return (
    <div className="mb-2.5 flex items-start gap-2.5 rounded-xl border border-line p-3.5">
      <span className="shrink-0">{icon}</span>
      <div className="min-w-0 flex-1">
        <p dir="auto" className="text-sm font-semibold leading-[1.4] text-[#1C1C1E]">{title}</p>
        {children && <div className="mt-1.5 text-[13px] leading-[1.4] text-gray-text">{children}</div>}
      </div>
    </div>
  );
}

/** One car park (parking_detail_screen.dart): what Google Maps knows about
 *  it where it is linked to Google, what the client entered, a small map,
 *  and the way there. */
export function ParkingDetail({ lot, lang }: { lot: ParkingLot; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [g, setG] = useState<Google | null>(null);
  const [loading, setLoading] = useState(!!(KEY && lot.google_place_id));
  useEffect(() => {
    if (!KEY || !lot.google_place_id) return;
    let live = true;
    fetchPlace(lot.google_place_id, lang).then((r) => { if (live) { setG(r); setLoading(false); } });
    return () => { live = false; };
  }, [lot.google_place_id, lang]);

  const title = g?.name ?? lotName(lot, lang);
  const address = g?.address ?? lot.address;
  const pay = g ? [g.cashOnly && t('מזומן בלבד', 'Cash only'), g.cards && t('כרטיסי אשראי', 'Credit cards'),
    g.debit && t('כרטיסי חיוב', 'Debit cards'), g.nfc && t('תשלום ללא מגע', 'Contactless')].filter(Boolean) as string[] : [];
  const pins = useMemo<MapPin[]>(() => [{ id: lot.id, lat: lot.latitude, lng: lot.longitude, icon: '/web/map/pin_parking.svg', size: [40, 43] }], [lot]);
  // Google Maps shows the destination by its name when Google lists it.
  const google = g?.name ? `https://www.google.com/maps/dir/?api=1&destination=${encodeURIComponent([g.name, g.address].filter(Boolean).join(', '))}${lot.google_place_id ? `&destination_place_id=${lot.google_place_id}` : ''}` : googleMapsUrl(lot);
  const side = lang === 'he' ? 'text-right' : 'text-left';

  return (
    <div>
      {g && g.photos.length > 0 && (
        <div className="mb-4 flex h-[200px] gap-2 overflow-x-auto">
          {g.photos.map((p) => (
            <figure key={p.name} className={`relative h-full shrink-0 overflow-hidden rounded-xl bg-[#F0F2F5] ${g.photos.length === 1 ? 'w-full' : 'w-[300px]'}`}>
              {/* Fetched (and billed) only as it scrolls into view. */}
              <img src={`https://places.googleapis.com/v1/${p.name}/media?maxWidthPx=900&key=${KEY}`} alt="" loading="lazy" decoding="async" className="size-full object-cover" />
              {/* Who took it, as Google requires for its photos. */}
              {p.authors.length > 0 && (
                <figcaption className="absolute inset-x-0 bottom-0 truncate bg-black/45 px-2 py-1 text-[11px] text-white">{t(`צילום: ${p.authors.join(', ')}`, `Photo: ${p.authors.join(', ')}`)}</figcaption>
              )}
            </figure>
          ))}
        </div>
      )}
      <div className="flex items-start gap-2">
        <h1 dir="auto" className={`flex-1 text-[22px] font-bold leading-[1.4] text-[#1C1C1E] ${side}`}>{title}</h1>
        {lot.is_free != null && <span className="mt-1.5"><FreeTag free={lot.is_free} lang={lang} large /></span>}
      </div>
      {address && <p dir="auto" className={`mt-1.5 text-sm leading-[1.4] text-gray-text ${side}`}>{address}</p>}
      {g?.rating != null && g.ratingCount > 0 && (
        <p className="mt-2.5 flex items-center gap-1 text-[13px] text-gray-text">
          <Star1 size={18} color="#FAB005" variant="Bold" />
          {t(`${g.rating.toFixed(1)} · ${g.ratingCount} דירוגים בגוגל`, `${g.rating.toFixed(1)} · ${g.ratingCount} ratings on Google`)}
        </p>
      )}
      {loading && <div className="mt-4 h-0.5 animate-pulse bg-midblue/40" />}
      <div className="mt-[18px] flex gap-2">
        <Directions waze={wazeUrl(lot.latitude, lot.longitude)} google={google} lang={lang} variant="filled" />
        {g?.phone && (
          <a href={`tel:${g.phone}`} aria-label={t('התקשרות', 'Call')} className="flex size-[46px] items-center justify-center rounded-xl border border-midblue text-midblue"><Call size={20} color="currentColor" /></a>
        )}
        {g?.website && (
          <a href={g.website} target="_blank" rel="noopener" aria-label="Website" className="flex size-[46px] items-center justify-center rounded-xl border border-midblue text-midblue"><Global size={20} color="currentColor" /></a>
        )}
      </div>
      <div className="mt-5">
        {g && g.hours.length > 0 ? (
          <Section icon={<Clock size={18} color="#17A9D0" />} title={t('שעות פתיחה', 'Opening hours')}>
            {g.hours.map((h) => <p key={h}>{hoursLine(h)}</p>)}
          </Section>
        ) : lot.hours && (
          <Section icon={<Clock size={18} color="#17A9D0" />} title={t('שעות פתיחה', 'Opening hours')}><p dir="auto">{lot.hours}</p></Section>
        )}
        {pay.length > 0 && <Section icon={<Card size={18} color="#17A9D0" />} title={t('תשלום', 'Payment')}><p>{pay.join(' · ')}</p></Section>}
        {lot.price_note && <Section icon={<Ticket size={18} color="#17A9D0" />} title={t('תשלום', 'Payment')}><p dir="auto">{lot.price_note}</p></Section>}
        {lot.capacity != null && <Section icon={<Car size={18} color="#17A9D0" />} title={t(`${lot.capacity} מקומות חניה`, `${lot.capacity} spaces`)} />}
        {lot.notes && <Section icon={<Note1 size={18} color="#17A9D0" />} title={lot.notes} />}
      </div>
      <div className="mt-2 h-[200px] overflow-hidden rounded-xl">
        <MapView pins={pins} lang={lang} center={[lot.latitude, lot.longitude]} zoom={16} interactive={false} fit={false} />
      </div>
      {lot.google_place_id && KEY && (
        // Google's terms: data from Places is shown with Google's mark.
        <p className="mt-3.5 flex flex-wrap items-center gap-x-2.5 gap-y-1.5 text-xs text-gray-text">
          <img src="/web/common/google_logo.png" alt="Google" className="h-[18px] w-auto" />
          {t('מידע מתוך Google Maps', 'Information from Google Maps')}
          {g?.mapsUri && <a href={g.mapsUri} target="_blank" rel="noopener" className="font-semibold text-midblue">{t('צפייה ב-Google Maps', 'View on Google Maps')}</a>}
        </p>
      )}
    </div>
  );
}
