import { NextResponse, type NextRequest } from 'next/server';
import { locationOf, redirectFor, redirectKey } from '@/lib/redirects';

/** The panel's redirects (src/lib/redirects.ts). Runs after next.config.ts's
 *  own redirects, so WordPress's stay as they were whatever is added here. */
export async function middleware(req: NextRequest) {
  const rule = await redirectFor(req.nextUrl.pathname);
  if (!rule) return NextResponse.next();
  const location = locationOf(rule.to);
  // A redirect to the address it came from would loop; the panel refuses
  // one, and this keeps a row written some other way from doing it.
  if (!/^https?:\/\//i.test(rule.to) && redirectKey(rule.to.split('?')[0]) === redirectKey(req.nextUrl.pathname)) {
    return NextResponse.next();
  }
  // A destination without its own `?…` keeps the visitor's, as WordPress
  // did (a campaign's utm_ tags survive the move).
  const search = rule.to.includes('?') ? '' : req.nextUrl.search;
  // Middleware must answer with a full address. Behind nginx the request's
  // own origin is the server's inside one (http://127.0.0.1:3100), so the
  // site's is taken from what nginx passes on (deploy/next/proxy.conf).
  const host = req.headers.get('x-forwarded-host') ?? req.headers.get('host') ?? req.nextUrl.host;
  const proto = req.headers.get('x-forwarded-proto') ?? req.nextUrl.protocol.replace(':', '');
  const target = /^https?:\/\//i.test(location) ? location : `${proto}://${host}${location}`;
  return NextResponse.redirect(target + search, rule.code);
}

export const config = {
  // Pages only: not Next's own files, the API, or the files nginx serves.
  matcher: ['/((?!_next/|api/|icons/|web/|images/|wp-content/|favicon\\.ico|robots\\.txt|sitemap\\.xml).*)'],
};
