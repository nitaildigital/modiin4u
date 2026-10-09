import { createClient } from '@supabase/supabase-js';
import { REVALIDATE, SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

/** The public client, the app's public key: it reads what anyone may read,
 *  through the same row-level security as the app. Every read is cached for
 *  [REVALIDATE] seconds, so a page costs the database a query a couple of
 *  minutes at most however often it is opened. */
export const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
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

const newBrowserDb = () => createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
let browserClient: ReturnType<typeof newBrowserDb> | null = null;

/** The client a browser uses (a tracked view, a click, the bell): one per
 *  page, shared — several would each start their own auth helper. */
export function browserDb() {
  return (browserClient ??= newBrowserDb());
}
