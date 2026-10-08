import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { slugParam } from '@/lib/params';
import { pageMetadata, plain, SUFFIX } from '@/lib/seo';
import { businessBySlugOrId, type Business } from '@/lib/data/business';
import { BusinessPage } from '@/components/business/BusinessPage';

type Props = { params: Promise<{ slug: string }> };

/** The page's own address: by its slug, as WordPress had it, even when it
 *  was opened by id (the app's cards link that way). */
function pathOf(b: Business, key: string): string {
  return `/business/${b.slug || key}/`;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const key = slugParam((await params).slug);
  const b = await businessBySlugOrId(key);
  if (!b) return {};
  return pageMetadata({
    path: pathOf(b, key),
    title: b.meta_title || (b.name + SUFFIX),
    description: b.meta_description || plain(b.short_description || b.full_description, 160),
    image: b.og_image_url || b.cover_url,
    noindex: !!b.noindex,
    modifiedTime: b.updated_at,
    ogTitle: b.og_title,
    ogDescription: b.og_description,
    keywords: b.meta_keywords,
  });
}

/** /business/<slug>/ — a business or a park, by its slug or its id. */
export default async function BusinessRoute({ params }: Props) {
  const key = slugParam((await params).slug);
  const b = await businessBySlugOrId(key);
  if (!b) notFound();
  return <BusinessPage b={b} path={pathOf(b, key)} />;
}
