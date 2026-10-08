import type { Metadata } from 'next';
import wp from '@/data/wp_pages.json';
import site from '@/data/site.json';
import { SEO_LIVE, SITE_URL } from './config';

type WpPage = { title?: string; description?: string; robots?: string; h1?: string; redirect_to?: string };
const WP_PAGES = (wp as unknown as { pages: Record<string, WpPage> }).pages;

/** The old site's header menu, link for link (path, text): every page carries
 *  these links with this text, as every WordPress page did. */
export const WP_MENU = (wp as unknown as { menu: [string, string][] }).menu;

export const SITE_NAME: string = site.site_name;
export const SUFFIX: string = site.title_suffix;
export const SITE_JSON = site as typeof site & { sections: Record<string, { title?: string; description?: string }> };

/** An address as the snapshot keys it: decoded, with the trailing slash. */
export function key(path: string): string {
  let p = path || '/';
  try { p = decodeURIComponent(p); } catch { /* already decoded */ }
  return p.endsWith('/') ? p : p + '/';
}

/** `/news/<slug>/` as it goes into an href or a canonical: each part
 *  percent-encoded, the slashes kept. */
export function href(path: string): string {
  return key(path).split('/').map((s) => (s ? encodeURIComponent(s) : s)).join('/');
}

/** What Google reads at this address on the WordPress site today. */
export function wpPage(path: string): WpPage | undefined {
  return WP_PAGES[key(path)];
}

/** The heading Google knows for this address — WordPress's H1 where it had
 *  a page, the name otherwise. */
export function h1For(path: string, fallback: string): string {
  return wpPage(path)?.h1 || fallback;
}

type Meta = {
  path: string;
  /** From the panel's SEO fields (copied from Yoast), else WordPress's, else
   *  the name with the old site's suffix. */
  title?: string | null;
  description?: string | null;
  image?: string | null;
  type?: 'website' | 'article';
  noindex?: boolean;
  publishedTime?: string | null;
  modifiedTime?: string | null;
  /** For sharing (SMO): the panel's own social title and text where set. */
  ogTitle?: string | null;
  ogDescription?: string | null;
  keywords?: string | null;
};

export function pageMetadata(m: Meta): Metadata {
  const wpp = wpPage(m.path);
  const title = m.title || wpp?.title || SITE_NAME;
  const description = m.description || wpp?.description || undefined;
  const url = SITE_URL + href(m.path);
  const index = SEO_LIVE && !m.noindex;
  const ogTitle = m.ogTitle || title;
  const ogDescription = m.ogDescription || description;
  return {
    title: { absolute: title },
    description,
    ...(m.keywords ? { keywords: m.keywords } : {}),
    alternates: { canonical: url },
    robots: index
      ? { index: true, follow: true, googleBot: { index: true, follow: true, 'max-image-preview': 'large' } }
      : { index: false, follow: false },
    openGraph: {
      locale: 'he_IL',
      siteName: site.og_site_name,
      title: ogTitle,
      description: ogDescription,
      url,
      type: m.type ?? 'website',
      ...(m.image ? { images: [{ url: m.image }] } : {}),
      ...(m.publishedTime ? { publishedTime: m.publishedTime } : {}),
      ...(m.modifiedTime ? { modifiedTime: m.modifiedTime } : {}),
    },
    twitter: { card: 'summary_large_image', title: ogTitle, description: ogDescription, ...(m.image ? { images: [m.image] } : {}) },
  };
}

/** Plain text from stored HTML, folded, cut at [limit] on a word. */
export function plain(s: string | null | undefined, limit?: number): string {
  let t = (s ?? '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"').replace(/&#039;|&#8217;/g, "'").replace(/\s+/g, ' ').trim();
  if (limit && t.length > limit) t = t.slice(0, limit).replace(/\s+\S*$/, '') + '…';
  return t;
}

export function organization() {
  return {
    '@type': 'Organization',
    name: site.site_name,
    alternateName: site.alternate_name,
    url: SITE_URL + '/',
    logo: SITE_URL + '/icons/Icon-512.png',
  };
}

export function breadcrumb(items: [string, string][]) {
  return {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map(([name, path], i) => ({
      '@type': 'ListItem', position: i + 1, name, item: SITE_URL + href(path),
    })),
  };
}

/** Every address WordPress had that answers with a page here (not its
 *  redirects), for the sitemap. */
export function wpPaths(): string[] {
  return Object.entries(WP_PAGES).filter(([, p]) => !p.redirect_to).map(([path]) => path);
}
