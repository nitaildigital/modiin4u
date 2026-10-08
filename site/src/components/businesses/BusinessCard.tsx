import Link from 'next/link';
import { BRAND_BG, Photo } from './Photo';
import { ContactButton } from './ContactButton';

/** One business as the lists draw it — every text already in the reader's
 *  language, so the card can be drawn on the server or in a list that
 *  filters in the browser. Built by `toCard` (card-data.ts). */
export type BizCard = {
  id: string;
  /** The page's address, encoded (`/business/<slug>/`). */
  href: string;
  name: string;
  /** Under the name on the desktop card: the business's own line, else the
   *  category's name. */
  subtitle: string;
  /** Under the name on a phone card: the category's name, else the
   *  business's own line (businessKind). */
  kind: string;
  /** The street address, else the neighbourhood. */
  address: string;
  neighborhood: string;
  photo: string | null;
  rating: number;
  reviews: number;
  /** The certificate's Hebrew name; the English page prints "Kosher". */
  kosher: string | null;
  delivery: boolean;
  phone: string | null;
  whatsapp: string | null;
  email: string | null;
  /** The pill on the photograph: the most specific category. */
  category: string | null;
  /** The round badge on the photograph's edge, by the top of that branch. */
  badge: 'restaurant' | 'cafe' | null;
};

const BADGE = {
  restaurant: ['/web/home/card_badge_ring_green.svg', '/web/home/card_badge_restaurant.svg'],
  cafe: ['/web/home/card_badge_ring.svg', '/web/home/card_badge_cafe.svg'],
  bar: ['/web/home/card_badge_ring_red.svg', '/web/home/card_badge_bar.svg'],
} as const;

/** The round badge on the photograph's edge, 44 across with its white ring,
 *  half over the 200-high photograph of a card. */
export function KindBadge({ kind, className = '' }: { kind: keyof typeof BADGE; className?: string }) {
  const [ring, icon] = BADGE[kind];
  return (
    <span className={`absolute end-[15px] top-[178px] grid size-11 place-items-center ${className}`} aria-hidden>
      <img src={ring} alt="" className="absolute inset-0 size-11" />
      <img src={icon} alt="" className="relative size-5" />
    </span>
  );
}

/** The blue pill on a photograph: a category, or the kosher mark. */
export function CardPill({ children, className = '' }: { children: React.ReactNode; className?: string }) {
  return <span className={`items-center gap-1.5 rounded-full bg-[#0033AC] px-2 py-1.5 text-xs font-medium leading-[15px] text-white ${className}`}>{children}</span>;
}

/** The stars, or "Not rated yet" — a gold star beside "0.0 (0)" reads as a
 *  bad score rather than none. [small] is the phone row's smaller type. */
export function Rating({ rating, reviews, lang, small = false, rated = reviews > 0 }: { rating: number; reviews: number; lang: 'he' | 'en'; small?: boolean; rated?: boolean }) {
  if (!rated) {
    return <span className={small ? 'text-xs text-gray-light desk:text-sm desk:text-[#6D6D6D]' : 'text-sm text-[#6D6D6D]'}>{lang === 'he' ? 'אין דירוג עדיין' : 'Not rated yet'}</span>;
  }
  return (
    <span className={`flex items-center gap-2 ${small ? 'text-[13px] desk:text-sm' : 'text-sm'}`}>
      <img src="/web/home/card_star.svg" alt="" className="size-4" />
      <span className="font-medium text-black">{rating.toFixed(1)}</span>
      <span className="text-[#6D6D6D]">({reviews})</span>
    </span>
  );
}

/** One business (WebBusinessCard): at desktop width the design's 404-high
 *  card — the photograph with the category pill and the kosher mark, the
 *  round café or restaurant badge on its edge, then the name, its line, the
 *  address, the rating and Contact. Below 1100 it is the phone's card:
 *  `tile` the directory's row with a square thumbnail (business_card.dart),
 *  `place` a category page's photograph card (m_business_place_card.dart).
 *
 *  It prints what the row carries and nothing else: the rating only once a
 *  review has earned one, no view count (no column holds one), no heart
 *  (saving belongs to an account, and accounts to the app), and Contact
 *  only where there is a number or an address to reach. */
export function BusinessCard({ b, lang, variant = 'place' }: { b: BizCard; lang: 'he' | 'en'; variant?: 'tile' | 'place' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  // Directory text reads in its own direction but lines up with the page.
  const align = lang === 'he' ? 'text-right' : 'text-left';
  const tile = variant === 'tile';
  const kosher = b.kosher ? (lang === 'he' ? b.kosher : 'Kosher') : null;
  const phoneLine = tile ? [b.kind, b.neighborhood].filter(Boolean).join(' · ') : b.kind;

  return (
    <article className={tile
      ? 'group relative flex h-[110px] overflow-hidden rounded-xl border-[0.5px] border-line bg-white desk:h-[404px] desk:flex-col desk:border'
      : 'group relative flex flex-col desk:h-[404px] desk:overflow-hidden desk:rounded-xl desk:border desk:border-line desk:bg-white'}>
      <div className={tile ? 'relative w-[110px] shrink-0 desk:h-[200px] desk:w-full' : 'relative h-[200px] w-full shrink-0'}>
        {/* The phone's row has a pale tint behind its thumbnail, the cards
            the brand gradient. */}
        <Photo src={b.photo} alt={b.name} icon={tile ? 34 : 40}
          bg={tile ? 'bg-midblue/8 desk:bg-[linear-gradient(to_bottom_right,#0058B5,#010A36)]' : BRAND_BG} iconClass={tile ? 'text-midblue/30 desk:text-white/30' : 'text-white/30'}
          className={tile ? 'size-full' : 'size-full rounded-xl desk:rounded-none'} />
        {b.category && (
          <CardPill className="absolute end-3.5 top-[15px] hidden max-w-[70%] desk:flex">
            <span dir="auto" className="truncate">{b.category}</span>
          </CardPill>
        )}
        {kosher && (
          <CardPill className="absolute start-3 top-[161px] hidden desk:flex">
            <img src="/web/home/card_kosher.svg" alt="" className="size-3.5" />{kosher}
          </CardPill>
        )}
      </div>
      {b.badge && <KindBadge kind={b.badge} className="hidden desk:grid" />}

      {/* Not positioned: the name's link covers the whole card from here. */}
      <div className={tile ? 'min-w-0 flex-1 p-3 desk:p-4' : 'min-w-0 pt-4 desk:p-4'}>
        <div className="desk:h-[50px]">
          <h3 className={`truncate ${align} ${tile
            ? 'font-rubik text-[15px] font-semibold text-ink desk:font-nunito desk:text-xl desk:leading-[1.25] desk:text-navy'
            : 'font-nunito text-xl font-semibold leading-[1.25] text-navy'}`}>
            {/* The whole card opens the business; Contact sits above the link. */}
            <Link href={b.href} dir="auto" className="after:absolute after:inset-0">{b.name}</Link>
          </h3>
          {phoneLine && (
            <p dir="auto" className={`truncate ${align} desk:hidden ${tile ? 'mt-1 font-rubik text-[13px] text-gray-text' : 'mt-2 text-sm text-gray-text'}`}>{phoneLine}</p>
          )}
          {b.subtitle && <p dir="auto" className={`mt-2 hidden truncate text-sm leading-[17px] text-gray-text desk:block ${align}`}>{b.subtitle}</p>}
        </div>
        {b.address && (
          <p className={`items-center gap-2 text-sm text-gray-text ${tile ? 'hidden desk:mt-4 desk:flex' : 'mt-3 flex desk:mt-4'}`}>
            <img src="/web/home/card_pin.svg" alt="" className="mx-0.5 h-4 w-3 shrink-0" />
            <span dir="auto" className={`min-w-0 flex-1 truncate ${align}`}>{b.address}</span>
          </p>
        )}
        <div className={`flex items-center gap-2.5 ${tile ? 'mt-2 desk:mt-4' : 'mt-3 desk:mt-4'}`}>
          <Rating rating={b.rating} reviews={b.reviews} lang={lang} small={tile} />
          {tile && kosher && <span className="rounded bg-midblue/8 px-1.5 py-0.5 font-rubik text-[11px] font-medium text-midblue desk:hidden">{kosher}</span>}
        </div>
        {b.phone && (
          <div className="mt-4 hidden desk:block">
            <ContactButton phone={b.phone} whatsapp={b.whatsapp} email={b.email} lang={lang}
              className="flex items-center gap-2 rounded-full border border-midblue px-4 py-2 text-sm font-medium leading-6 text-midblue transition-colors group-hover:bg-midblue group-hover:text-white">
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
