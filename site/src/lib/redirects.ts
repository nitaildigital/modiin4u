import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

/** The panel's redirects (Redirects section, table `redirects`): an old
 *  address sent to a new one, as Yoast's redirect manager did on WordPress.
 *  WordPress's own redirects and the sections the new site renamed stay in
 *  next.config.ts; these are the ones the client adds himself. */
type Rule = { to: string; code: 301 | 302 };

/** Read at most this often. Every request is checked against the list, so
 *  it is held in memory rather than asked for each time — the database sees
 *  one small read every five minutes, whatever the traffic. */
const TTL = 5 * 60 * 1000;

/** How soon a failed read is tried again while no list has been read at
 *  all — a server starting while the database is slow to answer would
 *  otherwise send every redirected address to a 404 for five minutes. */
const RETRY = 15 * 1000;

let rules = new Map<string, Rule>();
let readAt = 0;
/** Whether a list has ever been read; until then a failure retries soon. */
let loaded = false;
let reading: Promise<void> | null = null;

/** An address as the panel keeps it (lib/features/admin/providers/
 *  admin_redirects_provider.dart, `siteAddress`): decoded, single slashes,
 *  ending in a slash unless it names a file. */
export function redirectKey(path: string): string {
  let p = path || '/';
  try { p = decodeURIComponent(p); } catch { /* a stray %: kept as it came */ }
  p = p.replace(/\/{2,}/g, '/');
  const last = p.split('/').pop() ?? '';
  return p.endsWith('/') || last.includes('.') ? p : p + '/';
}

async function read(): Promise<void> {
  try {
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/redirects?select=old_path,new_path,status_code&is_active=eq.true`,
      {
        headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}` },
        cache: 'no-store',
        signal: AbortSignal.timeout(5000),
      },
    );
    if (!res.ok) return;
    const rows: { old_path: string; new_path: string; status_code: number }[] = await res.json();
    rules = new Map(rows.map((r) => [redirectKey(r.old_path), { to: r.new_path, code: r.status_code === 302 ? 302 : 301 }]));
    loaded = true;
    readAt = Date.now();
  } catch {
    // The database did not answer: the last list stays, and the next read
    // is tried after the same wait rather than on every request — or, with
    // no list yet, after RETRY.
  } finally {
    // The next read comes after TTL — or after RETRY while there is no list
    // yet. (A successful read set readAt itself, just above.)
    if (!loaded) readAt = Date.now() - TTL + RETRY;
    else if (Date.now() - readAt > TTL) readAt = Date.now();
  }
}

/** Where [path] is sent, or undefined. The first call waits for the list;
 *  after that a stale list is used while a fresh one is read. */
export async function redirectFor(path: string): Promise<Rule | undefined> {
  if (Date.now() - readAt > TTL) {
    reading ??= read().finally(() => { reading = null; });
    if (!loaded) await reading;
  }
  return rules.get(redirectKey(path));
}

/** A destination as a Location header: a link elsewhere as it is; an
 *  address on the site with each part of its path percent-encoded, as
 *  href() writes them, and its `?…` kept. */
export function locationOf(to: string): string {
  if (/^https?:\/\//i.test(to)) return to;
  const q = to.indexOf('?');
  const path = q >= 0 ? to.slice(0, q) : to;
  const query = q >= 0 ? to.slice(q) : '';
  return path.split('/').map((s) => (s ? encodeURIComponent(s) : s)).join('/') + encodeURI(query);
}
