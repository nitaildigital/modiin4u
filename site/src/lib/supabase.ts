import { createClient } from '@supabase/supabase-js';
import { REVALIDATE, SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

const server = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
  global: {
    // Ten seconds, then the read fails: when the database does not answer
    // (9 Oct, the project restricted for an hour) a page says so at once
    // rather than waiting minutes for a connection that will not come.
    fetch: (input, init) => fetch(input, {
      ...init,
      signal: init?.signal ? AbortSignal.any([init.signal, AbortSignal.timeout(10_000)]) : AbortSignal.timeout(10_000),
      next: { revalidate: REVALIDATE },
    }),
  },
});

/** The public client, the app's public key: it reads what anyone may read,
 *  through the same row-level security as the app. Every read is cached for
 *  [REVALIDATE] seconds, so a page costs the database a query a couple of
 *  minutes at most however often it is opened.
 *
 *  A failed read throws (9 Oct). Supabase answers a failure with an error
 *  beside empty data, and most reads took the empty data: a database that
 *  did not answer drew "no businesses" with status 200, or "page not found"
 *  with a 404 that tells Google an article is gone. Now the page fails, as a
 *  500 ("הדף לא זמין כרגע", (site)/error.tsx), which a search engine retries
 *  — and nginx goes on serving the last good copy (deploy/next/proxy.conf).
 *  "No such row" is not a failure: it still comes back empty. A read whose
 *  absence costs nothing (a banner, the footer's store links) catches its
 *  own failure. */
export const db = new Proxy(server, {
  get(target, prop, receiver) {
    if (prop === 'rpc') {
      return (...args: Parameters<typeof target.rpc>) => target.rpc(...args).throwOnError();
    }
    if (prop === 'from') {
      return (table: string) => {
        const query = target.from(table);
        return new Proxy(query, {
          get(q, p, r) {
            const value = Reflect.get(q, p, r);
            if (typeof value !== 'function') return value;
            // Every way a query begins carries the flag down its chain.
            if (p === 'select' || p === 'insert' || p === 'upsert' || p === 'update' || p === 'delete') {
              return (...args: unknown[]) => (value as (...a: unknown[]) => { throwOnError: () => unknown }).apply(q, args).throwOnError();
            }
            return value.bind(q);
          },
        });
      };
    }
    return Reflect.get(target, prop, receiver);
  },
});

const newBrowserDb = () => createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
let browserClient: ReturnType<typeof newBrowserDb> | null = null;

/** The client a browser uses (a tracked view, a click, the bell): one per
 *  page, shared — several would each start their own auth helper. */
export function browserDb() {
  return (browserClient ??= newBrowserDb());
}
