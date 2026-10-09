'use client';
import { useEffect, useState } from 'react';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config';

// Signing in on the website, for Messages only (9 Oct — the client agreed to
// this exception to "accounts are the app's"). Accounts are still made in
// the app; here a resident or a business owner signs in to read and answer
// their conversations. The session lives in this browser under its own key —
// not the one the e-mail links' page uses (AuthLanding), which ends its
// session as soon as the link is spent.

let client: SupabaseClient | null = null;

/** The signed-in browser's client: one per page, shared. */
export function sessionDb(): SupabaseClient {
  return (client ??= createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false, storageKey: 'modiin4u-site-session' },
  }));
}

/** The current session, and whether it has been read back yet — until then
 *  "no session" does not yet mean signed out. */
export function useSession(): { session: Session | null; ready: boolean } {
  const [state, setState] = useState<{ session: Session | null; ready: boolean }>({ session: null, ready: false });
  useEffect(() => {
    const db = sessionDb();
    let alive = true;
    db.auth.getSession().then(({ data }) => { if (alive) setState({ session: data.session, ready: true }); });
    const { data: sub } = db.auth.onAuthStateChange((_event, session) => {
      if (alive) setState({ session, ready: true });
    });
    return () => { alive = false; sub.subscription.unsubscribe(); };
  }, []);
  return state;
}

const UNREAD_KEY = 'modiin4u-unread';
const UNREAD_TTL = 60_000;

/** The count on the header's Messages icon. Read at most once a minute per
 *  browser tab — the header is on every page, and each read is a query. */
export function useUnreadMessages(signedIn: boolean): number {
  const [n, setN] = useState(0);
  useEffect(() => {
    if (!signedIn) { setN(0); return; }
    let alive = true;
    const read = async (force = false) => {
      try {
        const cached = JSON.parse(sessionStorage.getItem(UNREAD_KEY) ?? 'null') as { n: number; at: number } | null;
        if (!force && cached && Date.now() - cached.at < UNREAD_TTL) { setN(cached.n); return; }
      } catch {}
      const { data, error } = await sessionDb().rpc('my_unread_messages');
      if (error || !alive) return;
      const value = typeof data === 'number' ? data : 0;
      setN(value);
      try { sessionStorage.setItem(UNREAD_KEY, JSON.stringify({ n: value, at: Date.now() })); } catch {}
    };
    read();
    const onFocus = () => read();
    const onChanged = () => read(true);
    window.addEventListener('focus', onFocus);
    window.addEventListener('modiin4u-unread-changed', onChanged);
    return () => { alive = false; window.removeEventListener('focus', onFocus); window.removeEventListener('modiin4u-unread-changed', onChanged); };
  }, [signedIn]);
  return n;
}

/** Tells the header a conversation was read, so its count is asked again. */
export function unreadChanged() {
  try { sessionStorage.removeItem(UNREAD_KEY); } catch {}
  window.dispatchEvent(new Event('modiin4u-unread-changed'));
}
