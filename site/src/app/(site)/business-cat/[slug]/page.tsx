import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { slugParam } from '@/lib/params';
import { pageMetadata, plain, SUFFIX, wpPage } from '@/lib/seo';
import { businessCategoryBySlug, sizedPhoto } from '@/lib/data/businesses';
import { CategoryPage } from '@/components/businesses/CategoryPage';
import { DirectoryPage } from '@/components/businesses/DirectoryPage';

type Props = { params: Promise<{ slug: string }> };

/** WordPress's addresses for three categories that have English slugs now:
 *  each keeps its own address, title and H1, and lists the category. */
const RENAMED: Record<string, string> = {
  'בריאות': 'health',
  'ספורט-וכושר': 'sports-fitness',
  'רכב': 'automotive',
};

/** What an address under /business-cat/ shows: a category by its slug or its
 *  old one, or — for a category WordPress had and the directory does not,
 *  such as the empty "הטבות" and "חוגים" in the old menu — the directory. */
async function resolve(slug: string) {
  const path = `/business-cat/${slug}/`;
  const renamed = RENAMED[slug];
  const category = await businessCategoryBySlug(renamed ?? slug);
  if (category) return { path, category, old: !!renamed };
  if (wpPage(path)) return { path, category: null, old: true };
  return null;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const r = await resolve(slugParam((await params).slug));
  if (!r) return {};
  if (r.old || !r.category) return pageMetadata({ path: r.path });
  const c = r.category;
  return pageMetadata({
    path: r.path,
    title: c.meta_title || (c.name + SUFFIX),
    description: c.meta_description || plain(c.description, 160),
    image: sizedPhoto(c.image_url, 1200),
  });
}

/** A business category (web_business_list_screen.dart, business_list_screen.dart). */
export default async function BusinessCategoryPage({ params }: Props) {
  const r = await resolve(slugParam((await params).slug));
  if (!r) notFound();
  return r.category ? <CategoryPage path={r.path} category={r.category} /> : <DirectoryPage path={r.path} />;
}
