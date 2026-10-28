import type { MetadataRoute } from 'next';
import { SITE_URL } from '@/lib/config';
import { href, wpPage, wpPaths } from '@/lib/seo';
import { db } from '@/lib/supabase';
import { categoryPath } from '@/lib/routes';
import { redirectKey } from '@/lib/redirects';

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

/** Yesterday's date in Israel, "2026-10-12". */
function yesterday(): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jerusalem', year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(new Date(Date.now() - 86_400_000));
}

/** Every page search engines should know: each article, business, park,
 *  coming event, open job, listing, neighbourhood and category from the
 *  database, the sections, and every address the WordPress site had. One
 *  entry per address. */
export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [arts, biz, evs, hoods, cats, used, moved, jobs, listings] = await Promise.all([
    allRows((a, b) => db.from('articles').select('slug, updated_at, published_at, noindex').eq('status', 'published').order('id').range(a, b)),
    allRows((a, b) => db.from('businesses').select('slug, updated_at, noindex').eq('status', 'active').order('id').range(a, b)),
    // Events still to come (or undated), from yesterday in Israel so one
    // running today is kept: a past one stays a page, but is not offered.
    allRows((a, b) => db.from('events').select('id, updated_at, noindex').eq('status', 'published')
      .or(`start_date.gte.${yesterday()},end_date.gte.${yesterday()},start_date.is.null`).order('id').range(a, b)),
    db.from('neighborhoods').select('id, updated_at').eq('is_active', true),
    db.from('categories').select('id, slug, scope, updated_at').eq('is_active', true).in('scope', ['business', 'article']),
    filedCategories(),
    db.from('redirects').select('old_path').eq('is_active', true),
    // Open jobs (13 Oct): Google lists jobs from their JobPosting data.
    db.from('jobs').select('id, updated_at').eq('status', 'active')
      .or(`expires_at.is.null,expires_at.gt.${new Date().toISOString()}`),
    // Published apartments (28 Oct): Google otherwise reaches them only
    // through links. One that sells or expires leaves 'active' and the list.
    allRows((a, b) => db.from('listings').select('id, updated_at').eq('status', 'active').order('id').range(a, b)),
  ]);
  const out = new Map<string, string | undefined>();
  // The sections, but not one WordPress kept out of Google (the apartment
  // search is `noindex, follow`): listing a page that asks not to be indexed
  // is an error in Search Console.
  for (const p of ['/', '/news/', '/business/', '/search-rest-modiin/', '/events/', '/deals/', '/search-apartments/', '/municipal/', '/parks/', '/shabat-times-modiin/', '/community/', '/jobs/']) {
    if (!/noindex/i.test(wpPage(p)?.robots ?? '')) out.set(p, undefined);
  }
  for (const a of arts) if (a.slug && !a.noindex) out.set(`/news/${a.slug}/`, a.updated_at ?? a.published_at);
  for (const b of biz) if (b.slug && !b.noindex) out.set(`/business/${b.slug}/`, b.updated_at);
  for (const e of evs) if (!e.noindex) out.set(`/event/${e.id}/`, e.updated_at);
  for (const n of hoods.data ?? []) out.set(`/neighborhood/${n.id}/`, n.updated_at);
  for (const j of jobs.data ?? []) out.set(`/jobs/${j.id}/`, j.updated_at);
  for (const l of listings) out.set(`/listing/${l.id}/`, l.updated_at);
  for (const c of cats.data ?? []) if (c.slug && used.has(c.id)) out.set(c.scope === 'business' ? categoryPath(c.slug) : `/new/${c.slug}/`, c.updated_at);
  for (const p of wpPaths()) if (!out.has(p)) out.set(p, undefined);
  // An address WordPress redirects is redirected here too: not listed.
  for (const p of [...out.keys()]) if (wpPage(p)?.redirect_to) out.delete(p);
  // So is one the panel redirects (Redirects): Google is told of its new
  // address by the redirect, not asked to crawl the old one.
  for (const r of moved.data ?? []) out.delete(redirectKey(r.old_path));
  return [...out].map(([path, lastmod]) => ({ url: SITE_URL + href(path), ...(lastmod ? { lastModified: lastmod } : {}) }));
}
