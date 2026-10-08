import Link from 'next/link';
import { Shop } from 'iconsax-react';
import { href } from '@/lib/seo';
import type { Lang } from '@/lib/i18n';
import { localName, type HoodBusiness } from '@/lib/data/realestate';
import { photo } from './format';

const A = '/web/realestate';

/**
 * A business filed under the neighbourhood (DetailBusinessCard). The small
 * card (listing page): photo, name, what it is, where. The large one
 * (neighbourhood page) adds the round café or restaurant badge on the
 * photo's edge and the star rating — only once someone has reviewed the
 * place, since nought out of nought reads as a bad score. The heart is the
 * app's; `businesses` keeps no view count.
 */
export function BusinessCard({ b, lang, large = false }: { b: HoodBusiness; lang: Lang; large?: boolean }) {
  const align = lang === 'he' ? 'text-right' : 'text-left';
  const name = localName(b.name, b.name_en, lang);
  const subtitle = b.kind?.name ?? (b.short_description ?? b.full_description ?? '').trim();
  const hood = b.neighborhoods ? localName(b.neighborhoods.name, b.neighborhoods.name_en, lang) : '';
  const address = b.address?.trim() || hood;
  const image = b.cover_url || b.og_image_url || b.logo_url;
  const badge = b.kind?.rootSlug === 'cafe-bakery' ? ['detail_badge_ring_blue', 'detail_badge_cafe']
    : b.kind?.rootSlug === 'restaurants' ? ['detail_badge_ring_green', 'detail_badge_restaurant'] : null;
  return (
    <Link href={href(`/business/${b.slug || b.id}/`)}
      className={`relative block h-full overflow-hidden rounded-xl border border-line bg-white transition-colors hover:border-[#CFCFCF]`}>
      {image
        ? <img src={photo(image, 310)} alt={name} loading="lazy" className={`w-full object-cover ${large ? 'h-[200px]' : 'h-[150px]'}`} />
        : <span className={`flex w-full items-center justify-center bg-[linear-gradient(135deg,#0058B5,#010A36)] text-white/30 ${large ? 'h-[200px]' : 'h-[150px]'}`}><Shop size={36} color="currentColor" /></span>}
      {large && badge && (
        <span className="absolute end-3.5 top-[178px] flex size-11 items-center justify-center">
          <img src={`${A}/${badge[0]}.svg`} alt="" className="absolute inset-0 size-11" />
          <img src={`${A}/${badge[1]}.svg`} alt="" className="relative size-5" />
        </span>
      )}
      <span className={`block ${large ? 'p-4' : 'p-3'}`}>
        <span dir="auto" className={`block truncate ${align} font-nunito font-semibold text-navy ${large ? 'text-xl leading-[25px]' : 'text-lg leading-[22px]'}`}>{name}</span>
        {subtitle
          ? <span dir="auto" className={`block truncate ${align} text-sm leading-[17px] text-gray-text ${large ? 'mt-2' : 'mt-1'}`}>{subtitle}</span>
          : <span className={`block h-[17px] ${large ? 'mt-2' : 'mt-1'}`} />}
        {address && (
          <span className={`flex items-center text-sm leading-[17px] text-gray-text ${large ? 'mt-4 gap-2' : 'mt-3 gap-1.5'}`}>
            <span className="flex size-4 shrink-0 items-center justify-center"><img src={`${A}/detail_pin.svg`} alt="" width={12} height={16} /></span>
            <span dir="auto" className="truncate">{address}</span>
          </span>
        )}
        {large && (b.review_count ?? 0) > 0 && (
          <span className="mt-4 flex items-center gap-2 text-sm">
            <img src={`${A}/detail_star.svg`} alt="" width={16} height={16} />
            <span className="font-medium">{Number(b.rating ?? 0).toFixed(1)}</span>
            <span className="text-[#6D6D6D]">({b.review_count})</span>
          </span>
        )}
      </span>
    </Link>
  );
}
