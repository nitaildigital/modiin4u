import Link from 'next/link';
import { Home2 } from 'iconsax-react';
import { href } from '@/lib/seo';
import type { Lang } from '@/lib/i18n';
import type { Listing } from '@/lib/data/realestate';
import { hoodName, isNew, kindLabel, photo, priceOf, roomsText, shekels } from './format';

const A = '/web/realestate';

/** A listing's photograph, or the brand panel with a house where it has none
 *  (NetworkPhoto's fallback), at the same size either way. */
export function ListingPhoto({ url, width, alt, className = '', iconSize = 48 }: {
  url: string | null; width: number; alt: string; className?: string; iconSize?: number;
}) {
  if (!url) {
    return (
      <span className={`flex items-center justify-center bg-[linear-gradient(135deg,#0058B5,#010A36)] text-white/30 ${className}`}>
        <Home2 size={iconSize} color="currentColor" variant="Bold" />
      </span>
    );
  }
  return <img src={photo(url, width)} alt={alt} loading="lazy" className={`object-cover ${className}`} />;
}

function Badge({ children, broker = false, className = '' }: { children: React.ReactNode; broker?: boolean; className?: string }) {
  return (
    <span className={`absolute rounded-full py-1.5 text-xs font-medium leading-[15px] ${broker ? 'bg-[#CCD6EE] px-4 text-[#0033AC]' : 'bg-turquoise px-2 text-white'} ${className}`}>
      {children}
    </span>
  );
}

function Spec({ icon, text }: { icon: string; text: string }) {
  return (
    <span className="flex items-center gap-2 whitespace-nowrap text-xs leading-[15px] text-[#3D3D3D]">
      <img src={icon} alt="" width={14} height={14} className="size-3.5" />{text}
    </span>
  );
}

function Pin() {
  return <span className="flex size-4 shrink-0 items-center justify-center"><img src={`${A}/card_pin.svg`} alt="" width={12} height={16} /></span>;
}

/** The figures a listing carries — each only where the row has it. */
function specs(l: Listing, lang: Lang, set: 'card' | 'detail', oneRoom: boolean) {
  const he = lang === 'he';
  const icons = set === 'card'
    ? [`${A}/spec_sqm.svg`, `${A}/spec_rooms.svg`, `${A}/spec_floor.svg`]
    : [`${A}/detail_card_area.svg`, `${A}/detail_card_rooms.svg`, `${A}/detail_card_floor.svg`];
  const out: { icon: string; text: string }[] = [];
  if (l.sqm != null) out.push({ icon: icons[0], text: he ? `${l.sqm} מ״ר` : `${l.sqm} m²` });
  if (l.rooms != null) {
    const r = roomsText(l.rooms);
    out.push({ icon: icons[1], text: oneRoom && l.rooms === 1 ? (he ? 'חדר 1' : '1 Room') : (he ? `${r} חדרים` : `${r} Rooms`) });
  }
  if (l.floor != null) out.push({ icon: icons[2], text: l.floor === 0 ? (he ? 'קומת קרקע' : 'Ground Floor') : (he ? `קומה ${l.floor}` : `Floor ${l.floor}`) });
  return out;
}

/** The price line: the amount in the rounded face, "/ month" for a rental,
 *  and the kind at the far end. */
function PriceRow({ l, lang, onRequest }: { l: Listing; lang: Lang; onRequest: 'display' | 'muted' | 'none' }) {
  // The phone layout writes "לחודש", the website "/ לחודש".
  const month = onRequest === 'none' ? (lang === 'he' ? 'לחודש' : '/ month') : (lang === 'he' ? '/ לחודש' : '/ month');
  const price = priceOf(l);
  const he = lang === 'he';
  return (
    <div className="flex items-center gap-2">
      <div className="flex min-w-0 flex-1 items-center gap-2">
        {price == null ? (
          onRequest === 'none' ? null
            : <span className={onRequest === 'display' ? 'font-nunito text-base font-semibold text-navy' : 'truncate text-sm text-gray-text'}>{he ? 'מחיר לפי בקשה' : 'Price on request'}</span>
        ) : (
          <>
            <span dir="ltr" className="font-nunito text-xl font-semibold leading-[25px] text-navy">{shekels(price)}</span>
            {l.kind === 'rent' && <span className="truncate text-sm leading-[17px] text-gray-text">{month}</span>}
          </>
        )}
      </div>
      <span className="shrink-0 text-xs font-medium leading-[15px] text-turquoise">{kindLabel(l.kind, lang)}</span>
    </div>
  );
}

/**
 * One listing as a card, in the three sizes the design draws:
 *  - `desk`: the website's card (web_realestate_screen.dart, and the
 *    neighbourhood page's large card): bordered, a 200 photo with the "New"
 *    and "Via Broker" badges, then price, place and figures;
 *  - `small`: the listing page's "Properties in …" strip (288 × 261);
 *  - `phone`: the phone layout's card, the photo rounded on its own and the
 *    text under it with no frame.
 * The heart the design draws saves to an account, and accounts are the app's.
 */
export function ListingCard({ l, lang, variant, detail = false }: { l: Listing; lang: Lang; variant: 'desk' | 'small' | 'phone'; detail?: boolean }) {
  const he = lang === 'he';
  const link = href(`/listing/${l.id}/`);
  const hood = hoodName(l, lang);
  const fresh = isNew(l);

  if (variant === 'phone') {
    const place = l.address || hood || l.title;
    const figures = specs(l, lang, 'card', false);
    return (
      <Link href={link} className="block">
        <span className="relative block h-[200px] overflow-hidden rounded-xl">
          <ListingPhoto url={l.cover_url} width={400} alt={l.title} className="size-full" />
          {l.is_broker && <Badge broker className="bottom-3 left-3">{he ? 'באמצעות מתווך' : 'Via Broker'}</Badge>}
          {fresh && <Badge className="right-3 bottom-3">{he ? 'חדש' : 'New'}</Badge>}
        </span>
        <span className="flex flex-col gap-3 py-4">
          <PriceRow l={l} lang={lang} onRequest="none" />
          {place && <span className="flex items-center gap-2 text-sm text-gray-text"><Pin /><span dir="auto" className="truncate">{place}</span></span>}
          {figures.length > 0 && <span className="flex flex-wrap gap-6">{figures.map((s) => <Spec key={s.icon} {...s} />)}</span>}
        </span>
      </Link>
    );
  }

  if (variant === 'small') {
    const place = l.address ?? hood;
    const figures = specs(l, lang, 'detail', false);
    return (
      <Link href={link} className="block h-full overflow-hidden rounded-xl border border-line bg-white transition-colors hover:border-[#CFCFCF]">
        <ListingPhoto url={l.cover_url} width={290} alt={l.title} className="h-[150px] w-full" iconSize={40} />
        <span className="flex flex-col gap-3.5 p-3">
          <PriceRow l={l} lang={lang} onRequest="muted" />
          <span className="flex gap-[31px]">{figures.map((s) => <Spec key={s.icon} {...s} />)}</span>
          {place
            ? <span className="flex items-center gap-1.5 text-sm leading-[17px] text-gray-text"><Pin /><span dir="auto" className="truncate">{place}</span></span>
            : <span className="h-[17px]" />}
        </span>
      </Link>
    );
  }

  // [detail]: the neighbourhood page's large card (DetailListingCard), which
  // spaces its figures evenly and leaves an unknown place blank.
  const place = detail ? l.address ?? hood : l.address ?? hood ?? l.title;
  const figures = specs(l, lang, detail ? 'detail' : 'card', !detail);
  return (
    <Link href={link} className="block h-full overflow-hidden rounded-xl border border-line bg-white transition-shadow hover:shadow-[0_4px_16px_rgba(0,0,0,0.08)]">
      <span className="relative block h-[200px]">
        <ListingPhoto url={l.cover_url} width={400} alt={l.title} className="size-full" />
        {fresh && <Badge className="end-[14px] top-[15px]">{he ? 'חדש' : 'New'}</Badge>}
        {l.is_broker && <Badge broker className="start-3 bottom-3">{he ? 'דרך מתווך' : 'Via Broker'}</Badge>}
      </span>
      <span className="flex flex-col gap-4 p-4">
        <PriceRow l={l} lang={lang} onRequest={detail ? 'muted' : 'display'} />
        {place
          ? <span className="flex items-center gap-2 text-sm leading-[17px] text-gray-text"><Pin /><span dir="auto" className="truncate">{place}</span></span>
          : <span className="h-[17px]" />}
        <span className={`flex flex-wrap gap-y-2 ${detail ? 'gap-x-[31px]' : 'gap-x-4 min-[1530px]:gap-x-[31px]'}`}>{figures.map((s) => <Spec key={s.icon} {...s} />)}</span>
      </span>
    </Link>
  );
}
