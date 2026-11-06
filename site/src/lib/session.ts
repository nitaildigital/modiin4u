'use client';
import { useEffect, useState } from 'react';
import { createClient, type Session, type SupabaseClient } from '@supabase/supabase-js';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from './config';
import { SESSION_KEY, sessionClientStarted, UNREAD_EVENT, UNREAD_KEY } from './header-session';

// Signing in on the website, for Messages only (9 Oct — the client agreed to
// this exception to "accounts are the app's"). Accounts are still made in
// the app; here a resident or a business owner signs in to read and answer
// their conversations. The session lives in this browser under its own key —
// not the one the e-mail links' page uses (AuthLanding), which ends its
// session as soon as the link is spent.

let client: SupabaseClient | null = null;

/** The signed-in browser's client: one per page, shared. */
export function sessionDb(): SupabaseClient {
  if (!client) {
    client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: false, storageKey: SESSION_KEY },
    });
    // The header waits for this before it loads this module itself
    // (./header-session).
    sessionClientStarted();
  }
  return client;
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

// The header's unread count is ./header-session's useUnreadMessages.

/** Tells the header a conversation was read, so its count is asked again. */
export function unreadChanged() {
  try { sessionStorage.removeItem(UNREAD_KEY); } catch {}
  window.dispatchEvent(new Event(UNREAD_EVENT));
}
