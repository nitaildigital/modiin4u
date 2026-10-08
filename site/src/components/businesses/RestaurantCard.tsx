import Link from 'next/link';
import { TruckFast } from 'iconsax-react';
import { CardPill, KindBadge, Rating } from './BusinessCard';
import { ContactButton } from './ContactButton';
import { Photo } from './Photo';

/** One place to eat as the Restaurants page draws it (RestaurantPlace). */
export type FoodCard = {
  id: string; href: string; name: string;
  /** "Restaurant", "Cafe", "Bar" — or "Restaurant · Asian" on the compact card. */
  type: string;
  address: string; photo: string | null; rating: number; reviews: number;
  kind: 'restaurant' | 'cafe' | 'bar';
  /** The cuisine in the photograph's pill (large card only). */
  pill: string | null;
  kosher: boolean; delivery: boolean;
  phone: string | null; whatsapp: string | null;
};

/** The design's place card (restaurant_place_card.dart): 404 high with
 *  Contact, 348 without it ("Most Loved", "Lunch Nearby"). No heart — saving
 *  belongs to an account, and accounts to the app. */
export function RestaurantCard({ p, lang, compact = false, showDelivery = false }: {
  p: FoodCard; lang: 'he' | 'en'; compact?: boolean; showDelivery?: boolean;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const align = lang === 'he' ? 'text-right' : 'text-left';
  return (
    <article className={`group relative flex flex-col overflow-hidden rounded-xl border border-line bg-white ${compact ? 'h-[348px]' : 'h-[404px]'}`}>
      <div className="relative h-[200px] shrink-0">
        <Photo src={p.photo} alt={p.name} glyph={null} className="size-full" />
        {!compact && p.pill && <CardPill className="absolute end-3.5 top-[15px] flex max-w-[70%]"><span dir="auto" className="truncate">{p.pill}</span></CardPill>}
        {p.kosher && (
          <CardPill className="absolute start-3 top-[161px] flex">
            <img src="/web/home/card_kosher.svg" alt="" className="size-3.5" />{t('כשר', 'Kosher')}
          </CardPill>
        )}
      </div>
      <KindBadge kind={p.kind} />
      <div className="min-w-0 p-4">
        <div className="h-[50px]">
          <h3 className={`truncate font-nunito text-xl font-semibold leading-[1.25] text-navy ${align}`}>
            <Link href={p.href} dir="auto" className="after:absolute after:inset-0">{p.name}</Link>
          </h3>
          <p className="mt-2 truncate text-sm leading-[17px] text-gray-text">{p.type}</p>
        </div>
        {p.address && (
          <p className="mt-4 flex items-center gap-2 text-sm text-gray-text">
            <img src="/web/home/card_pin.svg" alt="" className="mx-0.5 h-4 w-3 shrink-0" />
            <span dir="auto" className={`min-w-0 flex-1 truncate ${align}`}>{p.address}</span>
          </p>
        )}
        <div className="mt-4 flex h-[17px] items-center gap-10">
          <span className="min-w-[100px]"><Rating rating={p.rating} reviews={p.reviews} rated={p.rating > 0 || p.reviews > 0} lang={lang} /></span>
          {showDelivery && p.delivery && (
            <span className="flex items-center gap-2 text-sm font-medium text-black"><TruckFast size={16} color="#5D5D5D" />{t('משלוחים', 'Delivery')}</span>
          )}
        </div>
        {!compact && p.phone && (
          <div className="mt-4">
            <ContactButton phone={p.phone} whatsapp={p.whatsapp} lang={lang}
              className="flex h-10 items-center gap-2 rounded-full border border-midblue px-4 text-sm font-medium text-midblue transition-colors group-hover:bg-midblue group-hover:text-white">
              <img src="/web/home/card_phone.svg" alt="" className="size-4 group-hover:hidden" />
              <img src="/web/home/card_phone_white.svg" alt="" className="hidden size-4 group-hover:block" />
              {t('צור קשר', 'Contact')}
            </ContactButton>
          </div>
        )}
      </div>
    </article>
  );
}
