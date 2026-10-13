import type { Banner as B } from '@/lib/data/banners';
import { ownPhoto } from '@/lib/photos';

/** One paid banner: its creative, linked where the campaign points;
 *  [eager] for one the page opens on, so it is not left until scrolled to. */
export function BannerImage({ banner, className = '', eager = false }: { banner: B; className?: string; eager?: boolean }) {
  const img = <img src={ownPhoto(banner.image_url, 1200) ?? banner.image_url} alt={banner.name} className={`w-full rounded-xl object-cover ${className}`} loading={eager ? 'eager' : 'lazy'} />;
  return banner.destination_url
    ? <a href={banner.destination_url} target="_blank" rel="noopener sponsored">{img}</a>
    : img;
}
