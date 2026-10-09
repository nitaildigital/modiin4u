import { NextResponse } from 'next/server';
import { db } from '@/lib/supabase';
import { href } from '@/lib/seo';
import { isUuid, slugParam } from '@/lib/params';

/** The Flutter site's own addresses, by row id (`/article/<id>`,
 *  `/business/category/<id>` …): links people kept from it and the app's
 *  older shares. Each answers with a 301 to the page that replaced it, and
 *  to its section when the row is gone, so nothing they kept ends in a 404. */
export function moved(req: Request, path: string) {
  // A relative address: behind nginx, `req.url` is the server's own
  // (127.0.0.1:3100), and a redirect built from it would send the reader
  // there. What the address carried goes along: a notification's `?push=`
  // is how its opening is counted.
  return new NextResponse(null, { status: 301, headers: { Location: href(path) + new URL(req.url).search } });
}

/** A row's slug by its id, or by its slug when the address already had one. */
export async function slugOf(table: 'articles' | 'businesses' | 'categories', key: string, scope?: 'article' | 'business'): Promise<string | null> {
  const k = slugParam(key);
  let q = db.from(table).select('slug').eq(isUuid(k) ? 'id' : 'slug', k);
  if (scope) q = q.eq('scope', scope);
  const { data } = await q.maybeSingle();
  return (data as { slug: string | null } | null)?.slug ?? null;
}
