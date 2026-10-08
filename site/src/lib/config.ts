import supabase from '@/data/supabase.json';

/** The address Google knows the site by. Every canonical link points here,
 *  in the old site's address form, whatever address the page was read at. */
export const SITE_URL = 'https://www.modiin4u.co.il';

/** Until launch the site is a copy of live content on another address, which
 *  Google must not index beside the WordPress site: every page says noindex
 *  and robots.txt disallows all. SEO_LIVE=1 at launch opens both, and turns
 *  on the analytics the old site carried. */
export const SEO_LIVE = process.env.SEO_LIVE === '1';

export const SUPABASE_URL = supabase.url;
export const SUPABASE_ANON_KEY = supabase.anonKey;

/** How long a page's data is reused before it is read again, in seconds.
 *  A panel edit shows on the site within this. */
export const REVALIDATE = 120;

/** The client's contact details, as the footer has always published them. */
export const CONTACT = {
  phone: '058-4770195',
  email: 'modiin4uoffice@gmail.com',
  whatsapp: '972584770195',
  facebook: 'https://www.facebook.com/profile.php?id=61557667173369',
  instagram: 'https://www.instagram.com/modiin4u',
  tiktok: 'https://www.tiktok.com/@modiin4u',
};

/** The old site's analytics, kept for continuity (GA4, Clarity, Hotjar). */
export const ANALYTICS = {
  ga4: 'G-NVPTYVDZ40',
  clarity: 't0xe9flxif',
  hotjar: '4988942',
};
