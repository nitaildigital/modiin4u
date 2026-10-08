import type { Metadata } from 'next';
import { pageMetadata, h1For } from '@/lib/seo';
import { NewsListing, pageParam, pagedMetadata } from '@/components/news/NewsListing';

type Props = { searchParams: Promise<Record<string, string | string[] | undefined>> };

/** WordPress's news address. It keeps answering with the news, under its
 *  own title, description and heading — no redirect. */
const PATH = '/modiin-news/';

export async function generateMetadata({ searchParams }: Props): Promise<Metadata> {
  return pagedMetadata(pageMetadata({ path: PATH }), PATH, await pageParam(searchParams));
}

export default async function ModiinNewsPage({ searchParams }: Props) {
  return <NewsListing path={PATH} page={await pageParam(searchParams)} h1={h1For(PATH, 'חדשות')} />;
}
