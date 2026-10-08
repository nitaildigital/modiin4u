import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { slugParam } from '@/lib/params';
import { pageMetadata, wpPage } from '@/lib/seo';
import { businessBySlugOrId } from '@/lib/data/business';
import { businessCategoryBySlug } from '@/lib/data/businesses';
import { BusinessPage } from '@/components/business/BusinessPage';
import { CategoryPage } from '@/components/businesses/CategoryPage';

type Props = { params: Promise<{ slug: string }> };

/** The old site's address for a professional: the business of the same slug,
 *  under the title and description Google knows this address by. */
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const slug = slugParam((await params).slug);
  const path = `/professionals/${slug}/`;
  const b = await businessBySlugOrId(slug);
  if (!b && !wpPage(path)) return {};
  return pageMetadata({ path });
}

/** /professionals/<slug>/ — WordPress's address for a professional's card,
 *  answered with the business page itself rather than a redirect. A card
 *  WordPress had whose business is not here (lak-gell-modiin) keeps its
 *  address too, with the professionals list under its heading. */
export default async function ProfessionalRoute({ params }: Props) {
  const slug = slugParam((await params).slug);
  const path = `/professionals/${slug}/`;
  // By slug only: an old address never carried an id.
  const b = await businessBySlugOrId(slug);
  if (b && b.slug === slug) return <BusinessPage b={b} path={path} />;
  if (wpPage(path)) return <CategoryPage path={path} category={await businessCategoryBySlug('services')} />;
  notFound();
}
