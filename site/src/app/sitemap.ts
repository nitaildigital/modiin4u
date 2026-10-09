import type { MetadataRoute } from 'next';
import { SITE_URL } from '@/lib/config';
import { href, wpPage, wpPaths } from '@/lib/seo';
import { db } from '@/lib/supabase';
import { categoryPath } from '@/lib/routes';

export const revalidate = 600;

/** The categories something is filed under. One with nothing in it is an
 *  empty page, and is not offered. Read a thousand links at a time, the
 *  most the database returns at once. */
async function filedCategories(): Promise<Set<string>> {
  const ids = new Set<string>();
  for (let from = 0; ; from += 1000) {
    const { data } = await db.from('entity_categories').select('category_id')
      .in('entity_type', ['business', 'article']).order('category_id').range(from, from + 999);
    for (const r of data ?? []) ids.add(r.category_id);
    if (!data || data.length < 1000) break;
  }
  return ids;
}

/** Every row a query matches, a thousand at a time — the most the database
 *  returns at once, which would otherwise cut the list without saying so
 *  (673 articles now; the thousand-and-first would be left out of Google's
 *  list). [page] builds the query for one range, in a fixed order. */
async function allRows<T>(page: (from: number, to: number) => PromiseLike<{ data: T[] | null }>): Promise<T[]> {
  const out: T[] = [];
  for (let from = 0; ; from += 1000) {
    const { data } = await page(from, from + 999);
    out.push(...(data ?? []));
    if (!data || data.length < 1000) return out;
  }
}

/** Every page search engines should know: each article, business, park and
 *  category from the database, the sections, and every address the
 *  WordPress site had. One entry per address. */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [arts, biz, cats, used] = await Promise.all([
    allRows((a, b) => db.from('articles').select('slug, updated_at, published_at, noindex').eq('status', 'published').order('id').range(a, b)),
    allRows((a, b) => db.from('businesses').select('slug, updated_at, noindex').eq('status', 'active').order('id').range(a, b)),
    db.from('categories').select('id, slug, scope, updated_at').eq('is_active', true).in('scope', ['business', 'article']),
    filedCategories(),
  ]);
  const out = new Map<string, string | undefined>();
  for (const p of ['/', '/news/', '/business/', '/search-rest-modiin/', '/events/', '/deals/', '/search-apartments/', '/municipal/', '/parks/', '/shabat-times-modiin/', '/community/']) out.set(p, undefined);
  for (const a of arts) if (a.slug && !a.noindex) out.set(`/news/${a.slug}/`, a.updated_at ?? a.published_at);
  for (const b of biz) if (b.slug && !b.noindex) out.set(`/business/${b.slug}/`, b.updated_at);
  for (const c of cats.data ?? []) if (c.slug && used.has(c.id)) out.set(c.scope === 'business' ? categoryPath(c.slug) : `/new/${c.slug}/`, c.updated_at);
  for (const p of wpPaths()) if (!out.has(p)) out.set(p, undefined);
  // An address WordPress redirects is redirected here too: not listed.
  for (const p of [...out.keys()]) if (wpPage(p)?.redirect_to) out.delete(p);
  return [...out].map(([path, lastmod]) => ({ url: SITE_URL + href(path), ...(lastmod ? { lastModified: lastmod } : {}) }));
}
