import type { NextConfig } from 'next';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { CATEGORY_MOVES, SECTION_MOVES } from './src/lib/routes';

/** WordPress's own redirects, which the snapshot saw (`redirect_to`): kept
 *  as the same 301s, so an address WordPress sent elsewhere goes to the same
 *  place here. Every other old address is a page of its own. */
function wordpressRedirects() {
  const file = join(__dirname, 'src', 'data', 'wp_pages.json');
  if (!existsSync(file)) return [];
  const pages: Record<string, { redirect_to?: string }> = JSON.parse(readFileSync(file, 'utf8')).pages;
  return Object.entries(pages)
    .filter(([, p]) => p.redirect_to)
    .map(([from, p]) => ({
      source: encodeURI(from.replace(/\/$/, '')),
      destination: encodeURI(p.redirect_to!),
      // 301 as WordPress answered, not Next's default 308.
      statusCode: 301 as const,
    }));
}

const nextConfig: NextConfig = {
  // The old site's addresses end in a slash (/news/<slug>/), and that is how
  // Google knows every one of them.
  trailingSlash: true,
  // A self-contained server for our own machine (deploy/next).
  output: 'standalone',
  // This folder is the project, not the repo around it (which has its own
  // lockfiles): the standalone server lands at .next/standalone/server.js.
  outputFileTracingRoot: __dirname,
  poweredByHeader: false,
  // Titles, descriptions, canonicals and sharing tags always in <head>, for
  // every reader. Next streams them into the body when a page is slow to
  // render, which Google copes with but Bing, Facebook, WhatsApp and most
  // other crawlers do not: they read the head only.
  htmlLimitedBots: /.*/,
  images: {
    // The widths ownPhoto asks for (src/lib/photos.ts), and nothing else.
    deviceSizes: [800, 1200, 1600, 2000, 2500],
    imageSizes: [200, 400, 600],
    // One quality, the one ownPhoto asks for: any other `q` would make
    // another copy of every photo, kept a year.
    qualities: [75],
    // A stored photo never changes under its name (a new upload gets a new
    // one), so each copy is made once and kept.
    minimumCacheTTL: 60 * 60 * 24 * 365,
    remotePatterns: [
      // Our storage's public files only: nothing else is resized here.
      { protocol: 'https', hostname: 'zbtgietqoxkglfxfocrb.supabase.co', pathname: '/storage/v1/object/public/**' },
    ],
  },
  async redirects() {
    return [
      ...wordpressRedirects(),
      // The sections the app's design named anew, and the categories filed
      // under another slug, to the address WordPress had for them
      // (src/lib/routes.ts); a search's `?` fields go along.
      ...SECTION_MOVES.map(([from, to]) => ({ source: from.replace(/\/$/, ''), destination: encodeURI(to), statusCode: 301 as const })),
      ...Object.entries(CATEGORY_MOVES).map(([slug, to]) => ({ source: `/business-cat/${slug}`, destination: encodeURI(to), statusCode: 301 as const })),
      // Two WordPress pages its sitemaps never listed, so the snapshot has
      // neither: the accessibility statement, and the terms and privacy in
      // one page — the new site has each as its own page.
      { source: encodeURI('/הצהרת-נגישות'), destination: '/accessibility/', statusCode: 301 as const },
      { source: encodeURI('/תקנון-תנאי-שימוש-ומדיניות-פרטיות'), destination: '/terms/', statusCode: 301 as const },
      // The Flutter site's own search addresses, in links people kept.
      { source: '/apartments-sale', destination: '/search-apartments/?kind=sale', statusCode: 301 as const },
      { source: '/apartments-rent', destination: '/search-apartments/?kind=rent', statusCode: 301 as const },
      // A link in an article's own text that led nowhere on WordPress either:
      // the business is here under another address.
      { source: encodeURI('/business/ג׳פטו-בר'), destination: '/business/geppeto-bar-modiin/', statusCode: 301 as const },
    ];
  },
};

export default nextConfig;
