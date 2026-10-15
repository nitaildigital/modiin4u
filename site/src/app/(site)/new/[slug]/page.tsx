import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { slugParam } from '@/lib/params';
import { pageMetadata, h1For, plain, SUFFIX } from '@/lib/seo';
import { newsCategoryBySlug } from '@/lib/data/news';
import { CategoryListing, pageParam, pagedMetadata } from '@/components/news/NewsListing';
import { NEWS_OLD_SLUGS } from '@/lib/old-slugs';

type Props = {
  params: Promise<{ slug: string }>;
  searchParams: Promise<Record<string, string | string[] | undefined>>;
};

async function resolve(params: Props['params']) {
  const slug = slugParam((await params).slug);
  // A category the panel has renamed: its old address shows it under its new
  // slug, with WordPress's title, description and heading.
  const old = NEWS_OLD_SLUGS[slug];
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
