import type { Metadata } from 'next';
import { pageMetadata, h1For } from '@/lib/seo';
import { NewsListing, pageParam, pagedMetadata } from '@/components/news/NewsListing';

type Props = { searchParams: Promise<Record<string, string | string[] | undefined>> };

const PATH = '/news/';

// WordPress's title and description for /news/ (it has no row of its own).
export async function generateMetadata({ searchParams }: Props): Promise<Metadata> {
  return pagedMetadata(pageMetadata({ path: PATH }), PATH, await pageParam(searchParams));
}

/** The news (web_news_screen.dart, news_screen.dart), and its later pages
 *  at `?page=N`, which hold every story the front page does not. */
export default async function NewsPage({ searchParams }: Props) {
  return <NewsListing path={PATH} page={await pageParam(searchParams)} h1={h1For(PATH, 'חדשות')} />;
}
