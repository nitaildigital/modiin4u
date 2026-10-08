import type { Banner as B } from '@/lib/data/banners';

/** One paid banner: its creative, linked where the campaign points. */
export function BannerImage({ banner, className = '' }: { banner: B; className?: string }) {
  const img = <img src={banner.image_url} alt={banner.name} className={`w-full rounded-xl object-cover ${className}`} loading="lazy" />;
  return banner.destination_url
    ? <a href={banner.destination_url} target="_blank" rel="noopener sponsored">{img}</a>
    : img;
}
