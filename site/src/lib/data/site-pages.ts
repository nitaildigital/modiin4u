import { cache } from 'react';
import { db } from '../supabase';
import type { Lang } from '../i18n';

// The fixed information pages the client writes in the panel (עמודי מידע,
// migration 00037): About Us, the Accessibility Statement, the Terms of Use,
// the Privacy Policy and how to delete an account (site_page_provider.dart).

export type SitePage = {
  slug: string; title_he: string; title_en: string; body_he: string; body_en: string; updated_at: string | null;
};

/** The published page with this slug, or null while it is not published.
 *  Published is asked for explicitly, as the app does. */
export const sitePage = cache(async (slug: string): Promise<SitePage | null> => {
  const { data } = await db.from('site_pages').select('slug,title_he,title_en,body_he,body_en,updated_at')
    .eq('slug', slug).eq('is_published', true).maybeSingle();
  if (!data) return null;
  const s = (v: unknown) => String(v ?? '').trim();
  return {
    slug: s(data.slug), title_he: s(data.title_he), title_en: s(data.title_en),
    body_he: s(data.body_he), body_en: s(data.body_en), updated_at: (data.updated_at as string | null) ?? null,
  };
});

/** Which language the page is read in: the reader's, unless the client wrote
 *  only the other one — then that one, rather than an empty page. Null when
 *  neither body has been written. */
export function contentLang(p: SitePage | null, want: Lang): Lang | null {
  if (!p) return null;
  const wanted = want === 'he' ? p.body_he : p.body_en;
  const other = want === 'he' ? p.body_en : p.body_he;
  if (wanted) return want;
  if (other) return want === 'he' ? 'en' : 'he';
  return null;
}

/** The title in [lang], or the other language's when that one is empty. */
export function pageTitle(p: SitePage, lang: Lang): string {
  const wanted = lang === 'he' ? p.title_he : p.title_en;
  return wanted || (lang === 'he' ? p.title_en : p.title_he);
}

/** The page's name while there is no published text to take it from — the
 *  same names the footer links print (sitePageFallbackTitle). */
export function fallbackTitle(slug: string, lang: Lang): string {
  const he = lang === 'he';
  switch (slug) {
    case 'accessibility': return he ? 'הצהרת נגישות' : 'Accessibility Statement';
    case 'terms': return he ? 'תקנון תנאי שימוש ומדיניות פרטיות' : 'Terms of Use & Privacy Policy';
    case 'privacy': return he ? 'מדיניות הפרטיות' : 'Privacy Policy';
    case 'delete-account': return he ? 'מחיקת חשבון' : 'Delete account';
    default: return he ? 'אודות' : 'About Us';
  }
}

/** "29.9.2026" in Israel's time — digits and dots, which read the same way
 *  round in a Hebrew line and an English one. */
export function sitePageDate(iso: string): string {
  const [y, m, d] = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Jerusalem', year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(new Date(iso)).split('-').map(Number);
  return `${d}.${m}.${y}`;
}
