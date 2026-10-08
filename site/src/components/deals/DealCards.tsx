import Link from 'next/link';
import { DiscountShape, Shop } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { href } from '@/lib/seo';
import type { Deal } from '@/lib/data/deals';
import { Photo } from '@/components/events/Photo';
import { businessName, dealBadge, isHebrew, neighborhood, phoneTimeLeft, residentsOnly, timeLeftLabel } from './labels';

/** The orange label on a deal's photograph. */
export function Badge({ label, small = false }: { label: string; small?: boolean }) {
  return (
    <span dir={isHebrew(label) ? 'rtl' : 'ltr'}
      className={`inline-block max-w-full truncate rounded-md bg-orange px-3 py-1.5 font-semibold leading-[1.21] text-white ${small ? 'text-xs' : 'text-sm'}`}>
      {label}
    </span>
  );
}

/** The business's mark in a thin grey ring. */
export function LogoRing({ url, size }: { url: string | null; size: number }) {
  return (
    <span className="block shrink-0 rounded-full border-[0.878px] border-line bg-white" style={{ width: size, height: size, padding: size * 0.0488 }}>
      <Photo url={url} alt="" className="size-full rounded-full" icon={Shop} iconSize={size * 0.28} />
    </span>
  );
}

/** Database text keeps its own direction, but lines up with the page's start. */
function align(lang: Lang) {
  return lang === 'he' ? 'text-right' : 'text-left';
}

/** The website's deal card, 480 × 353 (web_deals_screen.dart, _DealCard): the
 *  photograph with its badge, the business's mark, the headline, the business
 *  and where it is, the time left, "Residents Only", and the button. */
export function WebDealCard({ deal: d, lang }: { deal: Deal; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const badge = dealBadge(d.name);
  const left = timeLeftLabel(d, lang);
  const place = neighborhood(d, lang) ?? d.business?.address ?? null;
  const biz = businessName(d, lang) ?? '';
  return (
    <Link href={href(`/deal/${d.id}/`)} className="block w-[480px] shrink-0 rounded-xl border border-line bg-white p-4 transition-colors hover:border-midblue">
      <div className="flex h-[250px]">
        <div className="relative h-[191px] w-[157px] shrink-0">
          <Photo url={d.image_url ?? d.business?.cover} alt={d.name} className="size-full rounded-xl" icon={DiscountShape} iconSize={30} />
          {badge && <span className="absolute inset-x-3 top-3 flex"><Badge label={badge} /></span>}
        </div>
        <div className="ms-[17px] flex min-w-0 flex-1 flex-col">
          <LogoRing url={d.business?.logo ?? d.business?.cover ?? null} size={72} />
          <p dir={isHebrew(d.name) ? 'rtl' : 'ltr'} className={`mt-[13px] line-clamp-2 h-[54px] text-[22px] font-semibold leading-[1.21] text-midblue ${align(lang)}`}>{d.name}</p>
          <p dir={isHebrew(biz) ? 'rtl' : 'ltr'} className={`mt-2 h-[17px] truncate text-sm font-medium leading-[1.21] text-[#1C1C1E] ${align(lang)}`}>{biz}</p>
          <div className="mt-3 h-[17px]">
            {place && (
              <span className="flex items-center gap-2">
                <img src="/web/deals/card_pin.svg" alt="" className="size-4 shrink-0" />
                <span dir={isHebrew(place) ? 'rtl' : 'ltr'} className={`min-w-0 flex-1 truncate text-sm leading-[1.21] text-[#3D3D3D] ${align(lang)}`}>{place}</span>
              </span>
            )}
          </div>
          <div className="mt-auto flex h-9 items-center">
            {left && (
              <>
                <img src="/web/deals/card_clock.svg" alt="" className="size-5 shrink-0" />
                <span className="ms-2 flex shrink-0 flex-col">
                  <span dir="ltr" className={`text-base font-semibold leading-[1.19] text-navy ${align(lang)}`}>{left}</span>
                  <span className="mt-0.5 text-xs leading-[1.25] text-gray-text">{t('זמן שנותר', 'Time Left')}</span>
                </span>
                <span className="w-11 shrink-0" />
              </>
            )}
            {residentsOnly(d) && (
              <span className="flex min-w-0 items-center gap-2">
                <img src="/web/deals/card_lock.svg" alt="" className="size-5 shrink-0" />
                <span className="whitespace-pre-line text-xs font-semibold leading-[1.25] text-orange">{t('לתושבים\nבלבד', 'Residents\nOnly')}</span>
              </span>
            )}
          </div>
        </div>
      </div>
      <span className="mt-[25px] flex h-11 items-center justify-center rounded-[60px] bg-midblue text-base font-medium leading-6 text-white">{t('צפו במבצע', 'View Deal')}</span>
    </Link>
  );
}

/** The phone's deal card (m_deal_card.dart): the photograph with its badge
 *  and the business's mark, the headline, the business, where it is, the
 *  time left, "Residents Only", and the button. */
export function MDealCard({ deal: d, lang }: { deal: Deal; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const badge = dealBadge(d.name);
  const left = phoneTimeLeft(d, lang);
  const place = neighborhood(d, lang) ?? d.business?.address ?? null;
  const biz = businessName(d, lang);
  const logo = d.business?.logo ?? d.business?.cover ?? null;
  return (
    <Link href={href(`/deal/${d.id}/`)} className="block pb-4">
      <div className="relative h-[200px]">
        <Photo url={d.image_url ?? d.business?.cover} alt={d.name} className="size-full rounded-xl" icon={DiscountShape} iconSize={40} />
        {logo && (
          <span className="absolute start-3 top-[141px] size-[47px] rounded-full bg-white p-[2.34px]">
            <Photo url={logo} alt="" className="size-full rounded-full" icon={Shop} iconSize={18} />
          </span>
        )}
        {badge && <span className="absolute start-3 top-3"><Badge label={badge} /></span>}
      </div>
      <p className="mt-4 font-nunito text-xl font-semibold text-navy">{d.name}</p>
      {biz && <p className="mt-2 text-sm text-gray-text">{biz}</p>}
      {place && (
        <p className="mt-3 flex items-center gap-2">
          <span className="flex size-4 shrink-0 items-center justify-center"><img src="/icons/m_deals_pin.svg" alt="" className="h-4 w-3" /></span>
          <span className="truncate text-sm text-gray-text">{place}</span>
        </p>
      )}
      {(left || residentsOnly(d)) && (
        <div className="mt-3 flex items-center">
          {left && (
            <>
              <img src="/web/deals/card_clock.svg" alt="" className="size-4" />
              <span className="ms-2 text-sm font-medium text-black">{left}</span>
              <span className="ms-2 text-sm text-[#6D6D6D]">{t('נותר', 'Time Left')}</span>
            </>
          )}
          {residentsOnly(d) && (
            <span className="ms-auto flex items-center gap-2">
              <img src="/web/deals/card_lock.svg" alt="" className="size-4" />
              <span className="text-sm font-medium text-orange">{t('לתושבים בלבד', 'Residents Only')}</span>
            </span>
          )}
        </div>
      )}
      <span className="mt-5 flex h-11 items-center justify-center rounded-[60px] bg-midblue text-sm font-medium leading-6 text-white">{t('לצפייה במבצע', 'View Deal')}</span>
      <span className="block h-4" />
    </Link>
  );
}

/** A 252-wide card in the phone's "More Deals from …" row. */
export function MDealMiniCard({ deal: d, lang }: { deal: Deal; lang: Lang }) {
  const badge = dealBadge(d.name);
  const left = phoneTimeLeft(d, lang);
  return (
    <Link href={href(`/deal/${d.id}/`)} className="block w-[252px] shrink-0">
      <div className="relative h-[140px]">
        <Photo url={d.image_url ?? d.business?.cover} alt={d.name} className="size-full rounded-lg" icon={DiscountShape} iconSize={32} />
        {badge && <span className="absolute start-2.5 top-2.5"><Badge label={badge} small /></span>}
      </div>
      <p className="mt-2.5 line-clamp-2 font-nunito text-base font-semibold text-navy">{d.name}</p>
      {left && (
        <p className="mt-2 flex items-center gap-1.5 text-xs">
          <img src="/icons/m_deals_clock14.svg" alt="" className="size-3.5" />
          <span className="text-black">{left}</span>
          <span className="text-[#6D6D6D]">{lang === 'he' ? 'נותר' : 'Time Left'}</span>
        </p>
      )}
    </Link>
  );
}
