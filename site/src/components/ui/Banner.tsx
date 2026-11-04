import type { Banner as B } from '@/lib/data/banners';
import { ownPhoto } from '@/lib/photos';

/** One paid banner: its creative, linked where the campaign points;
 *  [eager] for one the page opens on, so it is not left until scrolled to.
 *  [phone]: below the desktop width the campaign's mobile image is shown in
 *  its place, when it has one — for a slot as wide as the page, where a
 *  wide desktop banner is a thin strip on a phone. */
export function BannerImage({ banner, className = '', eager = false, phone = false }: { banner: B; className?: string; eager?: boolean; phone?: boolean }) {
  const img = <img src={ownPhoto(banner.image_url, 1200) ?? banner.image_url} alt={banner.name} className={`w-full rounded-xl object-cover ${className}`} loading={eager ? 'eager' : 'lazy'} />;
  const mobile = phone ? banner.mobile_image_url : null;
  // 1099px: the site's phone layout ends where `desk` (1100px) begins.
  const shown = mobile
    ? <picture><source media="(max-width: 1099px)" srcSet={ownPhoto(mobile, 800) ?? mobile} />{img}</picture>
    : img;
  return banner.destination_url
    ? <a href={banner.destination_url} target="_blank" rel="noopener sponsored">{shown}</a>
    : shown;
}
