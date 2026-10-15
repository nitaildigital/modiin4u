import { db } from './supabase';
import { WP_MENU, key } from './seo';
import type { Lang } from './i18n';
import { BUSINESS_CAT_RENAMED, NEWS_OLD_SLUGS, PROFESSIONALS_MOVED } from './old-slugs';

export type MenuLink = { path: string; label: string };
export type Menus = {
  businesses: MenuLink[];
  professionals: MenuLink[];
  news: MenuLink[];
  /** The rest of the old menu: real estate, contact. */
  more: MenuLink[];
};

/** The site's own English for the sections the old menu links, as the
 *  header and the footer already name the same pages (nav-items.ts,
 *  Footer.tsx). The agents' page has no English name anywhere: it keeps
 *  WordPress's. */
const SECTIONS_EN: Record<string, string> = {
  '/business/': 'Businesses',
  '/search-rest-modiin/': 'Restaurants in Modiin',
  '/modiin-news/': 'Modiin News',
  '/search-apartments/': 'Real Estate',
  '/professionals/': 'Professionals',
  '/יצירת-קשר/': 'Contact Us',
};

/** The category slug an old menu address lists — its slug, or the one the
 *  panel renamed it to, as its page resolves it — or null for an address
 *  that lists no category of its own. */
function categoryOf(path: string): string | null {
  const [section, slug] = key(path).split('/').filter(Boolean);
  if (!slug) return null;
  if (section === 'business-cat') return BUSINESS_CAT_RENAMED[slug] ?? slug;
  // The nine WordPress kept empty all list Services; their trade has no
  // English name of its own.
  if (section === 'professionals-cat') return PROFESSIONALS_MOVED[slug] ?? null;
  if (section === 'new') return NEWS_OLD_SLUGS[slug] ?? slug;
  return null;
}

/** The old site's header menu, link for link, in its groups: every page
 *  carries these links with their text, as every WordPress page did. In
 *  English, a category's English name where the panel has one, and a
 *  section's where the site has one; otherwise WordPress's Hebrew stands.
 *  Hebrew pages — and Google, which sends no cookie — get WordPress's text
 *  unchanged. */
export async function getMenus(lang: Lang): Promise<Menus> {
  let english: Record<string, string> = {};
  if (lang === 'en') {
    // The menu is drawn on every page: should the read fail, the WordPress
    // (Hebrew) wording stands rather than the page failing.
    try {
      const { data } = await db.from('categories').select('slug, name_en').not('name_en', 'is', null);
      english = Object.fromEntries((data ?? []).map((c) => [c.slug as string, String(c.name_en).trim()]));
    } catch { /* the snapshot's wording */ }
  }
  const label = (path: string, text: string) => {
    if (lang !== 'en') return text;
    const slug = categoryOf(path);
    return (slug ? english[slug] : SECTIONS_EN[key(path)]) || text;
  };
  const menus: Menus = { businesses: [], professionals: [], news: [], more: [] };
  for (const [path, text] of WP_MENU) {
    const link = { path, label: label(path, text) };
    if (path.startsWith('/business') || path === '/search-rest-modiin/') menus.businesses.push(link);
    else if (path.startsWith('/professionals')) menus.professionals.push(link);
    else if (path.startsWith('/new/') || path === '/modiin-news/') menus.news.push(link);
    else menus.more.push(link);
  }
  return menus;
}
