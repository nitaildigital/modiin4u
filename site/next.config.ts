import type { NextConfig } from 'next';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

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
    remotePatterns: [
      { protocol: 'https', hostname: 'zbtgietqoxkglfxfocrb.supabase.co' },
      { protocol: 'https', hostname: 'www.modiin4u.co.il' },
      { protocol: 'https', hostname: 'modiin4u.co.il' },
    ],
  },
  async redirects() {
    return [
      ...wordpressRedirects(),
      // The Flutter site's own search addresses, in links people kept.
      { source: '/apartments-sale', destination: '/realestate/?kind=sale', statusCode: 301 as const },
      { source: '/apartments-rent', destination: '/realestate/?kind=rent', statusCode: 301 as const },
      // A link in an article's own text that led nowhere on WordPress either:
      // the business is here under another address.
      { source: encodeURI('/business/ג׳פטו-בר'), destination: '/business/geppeto-bar-modiin/', statusCode: 301 as const },
    ];
  },
};

export default nextConfig;
