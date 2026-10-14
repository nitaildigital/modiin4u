import { SITE_URL } from '@/lib/config';
import { db } from '@/lib/supabase';
import { href, plain, SITE_NAME } from '@/lib/seo';

/** The newest articles as RSS 2.0, at WordPress's /feed/ address — readers
 *  and Google's Discover follow a site by its feed, and WordPress had one.
 *  Built at most every ten minutes, whatever the traffic: one small read. */
export const revalidate = 600;

const esc = (s: string) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

type Row = { slug: string; title: string; excerpt: string | null; meta_description: string | null; featured_image: string | null; published_at: string | null; updated_at: string | null };

export async function GET() {
  const { data } = await db.from('articles')
    .select('slug,title,excerpt,meta_description,featured_image,published_at,updated_at')
    .eq('status', 'published').not('published_at', 'is', null).or('noindex.is.null,noindex.eq.false')
    .order('published_at', { ascending: false }).limit(30);
  const rows = (data ?? []) as Row[];
  const items = rows.map((a) => {
    const link = SITE_URL + href(`/news/${a.slug}/`);
    const text = plain(a.meta_description || a.excerpt, 300);
    return [
      '<item>',
      `<title>${esc(a.title)}</title>`,
      `<link>${esc(link)}</link>`,
      `<guid isPermaLink="true">${esc(link)}</guid>`,
      `<pubDate>${new Date(a.published_at!).toUTCString()}</pubDate>`,
      text ? `<description>${esc(text)}</description>` : '',
      a.featured_image ? `<media:content url="${esc(a.featured_image)}" medium="image" />` : '',
      '</item>',
    ].filter(Boolean).join('');
  });
  const newest = rows[0]?.updated_at ?? rows[0]?.published_at;
  const xml = '<?xml version="1.0" encoding="UTF-8"?>'
    + '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:media="http://search.yahoo.com/mrss/"><channel>'
    + `<title>${esc(SITE_NAME)}</title><link>${SITE_URL}/</link><description>${esc(SITE_NAME)}</description><language>he</language>`
    + `<atom:link href="${SITE_URL}/feed/" rel="self" type="application/rss+xml" />`
    + (newest ? `<lastBuildDate>${new Date(newest).toUTCString()}</lastBuildDate>` : '')
    + items.join('') + '</channel></rss>';
  return new Response(xml, { headers: { 'Content-Type': 'application/rss+xml; charset=utf-8' } });
}
