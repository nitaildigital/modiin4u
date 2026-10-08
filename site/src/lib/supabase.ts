import { createClient } from '@supabase/supabase-js';
import { REVALIDATE, SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

/** The public client, the app's public key: it reads what anyone may read,
 *  through the same row-level security as the app. Every read is cached for
 *  [REVALIDATE] seconds, so a page costs the database a query a couple of
 *  minutes at most however often it is opened. */
export const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
  global: {
    fetch: (input, init) => fetch(input, { ...init, next: { revalidate: REVALIDATE } }),
  },
});

/** The client a browser uses (a tracked view, a click). */
export function browserDb() {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}
