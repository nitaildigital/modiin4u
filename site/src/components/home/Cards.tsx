import { ContactButton } from './ContactButton';

/** What a business card prints, worked out on the server: only what the
 *  row carries. No view count (`businesses` has no such column) and no
 *  heart (saving belongs to an account, and accounts to the app). */
export type BizCardData = {
  id: string; href: string; name: string; subtitle: string; address: string;
  image: string | null; logo: string | null; category: string; kosher: string | null;
  rating: number; reviews: number; phone: string | null; whatsapp: string | null; email: string | null;
  /** The round badge on the photograph's edge: cafés and restaurants only. */
  badge: 'cafe' | 'restaurant' | null;
};

/** A line of the directory's own text — a name, an address — which reads in
 *  its own direction (Hebrew whatever the page's language) while it lines
 *  up with the rest of the card. */
export function DataText({ text, lang, className = '' }: { text: string; lang: 'he' | 'en'; className?: string }) {
  return <span dir="auto" className={`block truncate ${lang === 'he' ? 'text-right' : 'text-left'} ${className}`}>{text}</span>;
}

/** The photograph, or the soft panel with the shop glyph where there is none. */
function Photo({ src, alt, className }: { src: string | null; alt: string; className: string }) {
  if (src) return <img src={src} alt={alt} loading="lazy" className={`object-cover ${className}`} />;
  return (
    <span className={`flex items-center justify-center bg-[linear-gradient(135deg,#E0E8F0,#C8D4E0)] ${className}`}>
      <img src="/web/home/card_businesses.svg" alt="" width={40} height={40} className="size-10 opacity-40" />
    </span>
  );
}

/** The dark blue pill on a card's photograph. */
function Pill({ children }: { children: React.ReactNode }) {
  return <span className="flex items-center gap-1.5 whitespace-nowrap rounded-[50px] bg-[#0033AC] px-2 py-1.5 text-xs font-medium leading-[1.21] text-white">{children}</span>;
}

/** One business in the design's card (web_home_screen.dart, _BusinessCard):
 *  200 of photograph with the category in a pill and the kosher certificate,
 *  the name, its line, the address, the rating where reviews earned one,
 *  and Contact where the row has a number. The whole card opens the page. */
export function BusinessCard({ b, lang }: { b: BizCardData; lang: 'he' | 'en' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <article className="group/card relative flex h-[404px] flex-col overflow-hidden rounded-xl border border-line bg-white">
      <div className="relative h-[200px] shrink-0">
        <Photo src={b.image ?? b.logo} alt={b.name} className="size-full" />
        {b.category && <span className="absolute end-3.5 top-[15px] max-w-[80%]"><Pill><span className="truncate">{b.category}</span></Pill></span>}
        {b.kosher && (
          <span className="absolute start-3 top-[161px]">
            <Pill><img src="/web/home/card_kosher.svg" alt="" width={14} height={14} className="size-3.5" />{lang === 'he' ? b.kosher : 'Kosher'}</Pill>
          </span>
        )}
      </div>
      <div className="relative flex flex-1 flex-col p-4">
        {b.badge && (
          <span className="absolute end-[15px] -top-[22px] flex size-11 items-center justify-center">
            <img src={b.badge === 'cafe' ? '/web/home/card_badge_ring.svg' : '/web/home/card_badge_ring_green.svg'} alt="" className="absolute inset-0 size-11" />
            <img src={b.badge === 'cafe' ? '/web/home/card_badge_cafe.svg' : '/web/home/card_badge_restaurant.svg'} alt="" className="relative size-5" />
          </span>
        )}
        <div className="h-[50px]">
          <h3 className="min-w-0">
            <a href={b.href} className="block after:absolute after:inset-0 after:content-['']">
              <DataText text={b.name} lang={lang} className="font-nunito text-xl font-semibold leading-[1.22] text-navy" />
            </a>
          </h3>
          {b.subtitle && <DataText text={b.subtitle} lang={lang} className="mt-2 text-sm leading-[1.21] text-gray-text" />}
        </div>
        {b.address && (
          <div className="mt-4 flex items-center gap-2">
            <span className="flex size-4 shrink-0 items-center justify-center"><img src="/web/home/card_pin.svg" alt="" width={12} height={16} /></span>
            <DataText text={b.address} lang={lang} className="min-w-0 flex-1 text-sm leading-[1.21] text-gray-text" />
          </div>
        )}
        <div className="mt-4 text-sm leading-[1.21]">
          {b.reviews === 0
            ? <span className="text-[#6D6D6D]">{t('אין דירוג עדיין', 'Not rated yet')}</span>
            : (
              <span className="flex items-center gap-2">
                <img src="/web/home/card_star.svg" alt="" width={16} height={16} className="size-4" />
                <span className="font-medium text-black">{b.rating.toFixed(1)}</span>
                <span className="text-[#6D6D6D]">({b.reviews})</span>
              </span>
            )}
        </div>
        {b.phone?.trim() && (
          <div className="relative z-10 mt-4">
            <ContactButton phone={b.phone} whatsapp={b.whatsapp} email={b.email} label={t('צור קשר', 'Contact')} lang={lang} />
          </div>
        )}
      </div>
    </article>
  );
}

/** One professional (web_home_screen.dart, _ProfessionalCard): the
 *  business's own photograph in the circle, its trade under the name, and
 *  Call Now with its own number. */
export function ProfessionalCard({ b, trade, lang }: { b: BizCardData; trade: string; lang: 'he' | 'en' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const face = b.logo ?? b.image;
  return (
    <article className="group/card relative flex h-[302px] flex-col items-center rounded-xl border border-line p-5">
      {face
        ? <img src={face} alt={b.name} loading="lazy" className="size-[120px] shrink-0 rounded-full object-cover" />
        : <span className="flex size-[120px] shrink-0 items-center justify-center rounded-full bg-[linear-gradient(135deg,#DDE4EC,#C0CCD8)]" />}
      <h3 className="mt-4 w-full">
        <a href={b.href} className="block after:absolute after:inset-0 after:content-['']">
          <span dir="auto" className="block truncate text-center font-nunito text-xl font-semibold leading-[1.22] text-navy">{b.name}</span>
        </a>
      </h3>
      <p dir="auto" className="mt-2 w-full truncate text-center text-sm leading-[1.21] text-gray-text">{trade}</p>
      {b.phone?.trim() && (
        <div className="relative z-10 mt-auto w-full">
          <ContactButton phone={b.phone} whatsapp={b.whatsapp} email={b.email} label={t('התקשר עכשיו', 'Call Now')} lang={lang} wide />
        </div>
      )}
    </article>
  );
}
