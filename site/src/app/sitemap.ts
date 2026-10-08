import type { MetadataRoute } from 'next';
import { SITE_URL } from '@/lib/config';
import { href, wpPage, wpPaths } from '@/lib/seo';
import { db } from '@/lib/supabase';

export const revalidate = 600;

/** Every page search engines should know: each article, business, park and
 *  category from the database, the sections, and every address the
 *  WordPress site had. One entry per address. */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [arts, biz, cats] = await Promise.all([
    db.from('articles').select('slug, updated_at, published_at, noindex').eq('status', 'published').limit(5000),
    db.from('businesses').select('slug, updated_at, noindex').eq('status', 'active').limit(5000),
    db.from('categories').select('slug, scope, updated_at').eq('is_active', true).in('scope', ['business', 'article']),
  ]);
  const out = new Map<string, string | undefined>();
  for (const p of ['/', '/news/', '/businesses/', '/restaurants/', '/events/', '/deals/', '/realestate/', '/municipal/', '/parks/', '/shabbat/', '/community/']) out.set(p, undefined);
  for (const a of arts.data ?? []) if (a.slug && !a.noindex) out.set(`/news/${a.slug}/`, a.updated_at ?? a.published_at);
  for (const b of biz.data ?? []) if (b.slug && !b.noindex) out.set(`/business/${b.slug}/`, b.updated_at);
  for (const c of cats.data ?? []) if (c.slug) out.set(`/${c.scope === 'business' ? 'business-cat' : 'new'}/${c.slug}/`, c.updated_at);
  for (const p of wpPaths()) if (!out.has(p)) out.set(p, undefined);
  // An address WordPress redirects is redirected here too: not listed.
  for (const p of [...out.keys()]) if (wpPage(p)?.redirect_to) out.delete(p);
  return [...out].map(([path, lastmod]) => ({ url: SITE_URL + href(path), ...(lastmod ? { lastModified: lastmod } : {}) }));
}
