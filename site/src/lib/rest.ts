import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

/** A database function called with the public key over plain HTTP, for the
 *  browser's small calls on every page (the bell's feed, filing a push
 *  token). supabase-js would bring its sign-in and realtime code — about a
 *  quarter of the JavaScript every page loaded (6 Nov) — to make a request
 *  this does in a few lines. Answers as supabase-js does: data or an error,
 *  never a throw. */
export async function anonRpc<T = unknown>(fn: string, args: Record<string, unknown>): Promise<{ data: T | null; error: Error | null }> {
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
      method: 'POST',
      headers: { apikey: SUPABASE_ANON_KEY, Authorization: `Bearer ${SUPABASE_ANON_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(args),
    });
    const text = await res.text();
    if (!res.ok) return { data: null, error: new Error(`${fn}: ${res.status} ${text.slice(0, 200)}`) };
    return { data: (text ? JSON.parse(text) : null) as T | null, error: null };
  } catch (e) {
    return { data: null, error: e instanceof Error ? e : new Error(String(e)) };
  }
}
