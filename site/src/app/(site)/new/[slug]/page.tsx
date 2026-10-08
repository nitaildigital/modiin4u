import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { slugParam } from '@/lib/params';
import { pageMetadata, h1For, plain, SUFFIX } from '@/lib/seo';
import { newsCategoryBySlug } from '@/lib/data/news';
import { CategoryListing, pageParam, pagedMetadata } from '@/components/news/NewsListing';

type Props = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

/** WordPress's names for categories the panel has since renamed: their old
 *  addresses show the category under its new slug, with WordPress's title,
 *  description and heading. WordPress's "עירוני" (/new/municipal/) holds the
 *  municipal stories, which are filed under `municipal-news` here; the
 *  panel's own `municipal` category is empty. */
const OLD_SLUGS: Record<string, string> = {
  business: 'business-news',
  culinary: 'food',
  municipal: 'municipal-news',
};

async function resolve(params: Props['params']) {
  const slug = slugParam((await params).slug);
  const old = OLD_SLUGS[slug];
  const category = await newsCategoryBySlug(old ?? slug);
  return { path: `/new/${slug}/`, category, old: !!old };
}

export async function generateMetadata({ params, searchParams }: Props): Promise<Metadata> {
  const { path, category, old } = await resolve(params);
  if (!category) return {};
  const meta = old
    ? pageMetadata({ path })
    : pageMetadata({
      path,
      title: category.meta_title || category.name + SUFFIX,
      description: category.meta_description || plain(category.description, 160),
    });
  return pagedMetadata(meta, path, await pageParam(searchParams));
}

/** A news category (/new/<slug>/). */
export default async function NewsCategoryPage({ params, searchParams }: Props) {
  const { path, category } = await resolve(params);
  if (!category) notFound();
  return <CategoryListing path={path} category={category} page={await pageParam(searchParams)} h1={h1For(path, category.name)} />;
}
