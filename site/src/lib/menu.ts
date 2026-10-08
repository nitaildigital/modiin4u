import { db } from './supabase';
import { WP_MENU, key } from './seo';
import type { Lang } from './i18n';

export type MenuLink = { path: string; label: string };
export type Menus = {
  businesses: MenuLink[];
  professionals: MenuLink[];
  news: MenuLink[];
  /** The rest of the old menu: real estate, contact. */
  more: MenuLink[];
};

/** The old professional categories, filed under the business categories that
 *  replaced them (tool/seo/url_map.csv) — for their English names. */
const PROFESSIONAL_SLUGS: Record<string, string> = {
  'בונה-אתרים': 'web-design', 'הנדימן': 'handyman', 'חשמלאי': 'electrician',
  'טכנאי-מקררים': 'fridge-technician', 'לק-ג׳ל': 'gel-nails', 'עורך-דין': 'lawyer', 'שיפוצניק': 'renovations',
};

/** The old site's header menu, link for link, in its groups: every page
 *  carries these links with their text, as every WordPress page did. In
 *  English, a category's English name where the panel has one. */
export async function getMenus(lang: Lang): Promise<Menus> {
  let english: Record<string, string> = {};
  if (lang === 'en') {
    const { data } = await db.from('categories').select('slug, name_en').not('name_en', 'is', null);
    english = Object.fromEntries((data ?? []).map((c) => [c.slug as string, c.name_en as string]));
  }
  const label = (path: string, text: string) => {
    if (lang !== 'en') return text;
    const parts = key(path).split('/').filter(Boolean);
    const slug = parts[0] === 'professionals-cat' ? PROFESSIONAL_SLUGS[parts[1]] : parts[1];
    return (slug && english[slug]) || text;
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
