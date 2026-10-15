import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { slugParam } from '@/lib/params';
import { pageMetadata, wpPage } from '@/lib/seo';
import { businessCategoryBySlug } from '@/lib/data/businesses';
import { CategoryPage } from '@/components/businesses/CategoryPage';
import { PROFESSIONALS_MOVED as MOVED } from '@/lib/old-slugs';

type Props = { params: Promise<{ slug: string }> };

/** The category an old address lists: the one it became, or for the nine
 *  WordPress kept empty, the professionals (Services). Null for an address
 *  WordPress never had. */
async function resolve(slug: string) {
  const path = `/professionals-cat/${slug}/`;
  if (MOVED[slug]) return { path, category: await businessCategoryBySlug(MOVED[slug]) };
  if (wpPage(path)) return { path, category: await businessCategoryBySlug('services') };
  return null;
}

/** Every address here is WordPress's: its own title, description and H1. */
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const r = await resolve(slugParam((await params).slug));
  return r ? pageMetadata({ path: r.path }) : {};
}

/** An old professionals category, served where it was. */
export default async function OldProfessionalsCategory({ params }: Props) {
  const r = await resolve(slugParam((await params).slug));
  if (!r) notFound();
  return <CategoryPage path={r.path} category={r.category} />;
}
