'use client';
import { useEffect, useState } from 'react';
import type { Session } from '@supabase/supabase-js';

// The header's view of the Messages sign-in, on every page. supabase-js
// (./session) is loaded only when this browser has a stored session, or
// once another part of the page has started it (the sign-in form, a chat):
// most visitors never sign in, and the library was about a quarter of the
// JavaScript every page loaded (6 Nov).

/** Where supabase-js keeps the session (./session's storageKey). */
export const SESSION_KEY = 'modiin4u-site-session';
/** Fired on window when ./session creates its client. */
export const SESSION_CLIENT_EVENT = 'modiin4u-session-client';
export const UNREAD_KEY = 'modiin4u-unread';
export const UNREAD_EVENT = 'modiin4u-unread-changed';
const UNREAD_TTL = 60_000;

let clientStarted = false;
/** Called by ./session when its client is made. */
export function sessionClientStarted() {
  clientStarted = true;
  window.dispatchEvent(new Event(SESSION_CLIENT_EVENT));
}

function storedSession(): boolean {
  try { return localStorage.getItem(SESSION_KEY) != null; } catch { return false; }
}

/** As ./session's useSession, without loading supabase-js for a browser
 *  that has never signed in. */
export function useHeaderSession(): { session: Session | null; ready: boolean } {
  const [state, setState] = useState<{ session: Session | null; ready: boolean }>({ session: null, ready: false });
  useEffect(() => {
    let alive = true;
    let attached = false;
    let unsubscribe = () => {};
    const attach = async () => {
      if (attached) return;
      attached = true;
      const { sessionDb } = await import('./session');
      if (!alive) return;
      const db = sessionDb();
      db.auth.getSession().then(({ data }) => { if (alive) setState({ session: data.session, ready: true }); });
      const { data: sub } = db.auth.onAuthStateChange((_event, session) => {
        if (alive) setState({ session, ready: true });
      });
      unsubscribe = () => sub.subscription.unsubscribe();
    };
    if (clientStarted || storedSession()) void attach();
    else setState({ session: null, ready: true });
    // Signed in on this page (the form starts the client) or in another tab.
    const onStarted = () => void attach();
    const onStorage = (e: StorageEvent) => { if (e.key === SESSION_KEY && e.newValue) void attach(); };
    window.addEventListener(SESSION_CLIENT_EVENT, onStarted);
    window.addEventListener('storage', onStorage);
    return () => {
      alive = false;
      unsubscribe();
      window.removeEventListener(SESSION_CLIENT_EVENT, onStarted);
      window.removeEventListener('storage', onStorage);
    };
  }, []);
  return state;
}

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
      const { sessionDb } = await import('./session');
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
    window.addEventListener(UNREAD_EVENT, onChanged);
    return () => { alive = false; window.removeEventListener('focus', onFocus); window.removeEventListener(UNREAD_EVENT, onChanged); };
  }, [signedIn]);
  return n;
}
