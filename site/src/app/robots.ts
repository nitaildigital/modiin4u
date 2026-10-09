import type { MetadataRoute } from 'next';
import { SEO_LIVE, SITE_URL } from '@/lib/config';

// Read when asked, not at build: SEO_LIVE is set on the server at launch,
// and a robots.txt made at build time would keep saying Disallow.
export const dynamic = 'force-dynamic';

/** Until launch nothing may be indexed beside the WordPress site. */
export default function robots(): MetadataRoute.Robots {
  if (!SEO_LIVE) return { rules: { userAgent: '*', disallow: '/' } };
  return {
    rules: { userAgent: '*', allow: '/', disallow: ['/admin', '/login', '/join/', '/search', '/steps'] },
    sitemap: `${SITE_URL}/sitemap.xml`,
  };
}
