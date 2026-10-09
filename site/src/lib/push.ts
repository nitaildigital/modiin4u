'use client';
import { browserDb } from './supabase';

// Web push, as the Flutter site does it (lib/core/push/): Firebase gives the
// browser a token, `register_push_device` files it with the default
// switches, and `push_feed` lists what was sent to it — or, before it has
// a token, what went to everyone. Unread is kept in the browser: when the
// bell was last opened, and which notifications were opened. The storage
// keys are the Flutter site's (shared_preferences keeps `flutter.<key>`,
// JSON-encoded), so a browser the old site knew carries on as it was.

const FIREBASE = {
  apiKey: 'AIzaSyAwPCi3eFuoponvqvf4cGlCu7nTuwHkOow',
  authDomain: 'modiin4u-a895f.firebaseapp.com',
  projectId: 'modiin4u-a895f',
  messagingSenderId: '643935084045',
  appId: '1:643935084045:web:bdf1bba4316f3759017f44',
};
/** The project's public web push key (lib/core/push/push_config.dart). */
const VAPID = 'BGpBJqyhxlvkhpxOy6zQf6ZkW7pJRDWWQZAoMzBICt4LjU-WXnuxcpImChlzGs7YzhfeZYxBmLyepjUisTgPuhA';
const SDK = 'https://www.gstatic.com/firebasejs/12.19.0';

const TOKEN = 'flutter.push_token';
const SEEN = 'flutter.push_seen_at';
const OPENED = 'flutter.push_opened_ids';
/** Fired on window whenever the feed, the seen time or the opened set changes. */
export const PUSH_EVENT = 'modiin4u-push';

export type PushItem = {
  id: string; title: string; body: string; title_en: string | null; body_en: string | null;
  image_url: string | null; deep_link: string | null; sent_at: string;
};

function read<T>(key: string): T | null {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : null;
  } catch { return null; }
}
function write(key: string, value: unknown) {
  try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* storage refused */ }
}
const changed = () => window.dispatchEvent(new Event(PUSH_EVENT));

let db: ReturnType<typeof browserDb> | null = null;
const client = () => (db ??= browserDb());

/** Whether this browser can take web push at all (a secure page with a
 *  service worker and the Push API — not iOS Safari outside a home-screen
 *  app). */
export function pushSupported(): boolean {
  return typeof window !== 'undefined' && window.isSecureContext && 'serviceWorker' in navigator
    && 'PushManager' in window && 'Notification' in window;
}

export function permission(): NotificationPermission | 'unsupported' {
  return pushSupported() ? Notification.permission : 'unsupported';
}

export function savedToken(): string | null {
  return read<string>(TOKEN);
}

/** Google's Firebase modules, straight from Google as the Flutter site's
 *  worker takes them: the browser imports them itself, out of the bundler's
 *  reach (which rewrites any `import()` it can see). */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const load = new Function('u', 'return import(u)') as (u: string) => Promise<any>;

async function firebaseToken(): Promise<string | null> {
  const reg = await navigator.serviceWorker.register('/firebase-messaging-sw.js', { scope: '/firebase-cloud-messaging-push-scope' });
  const { initializeApp, getApps } = await load(`${SDK}/firebase-app.js`);
  const { getMessaging, getToken } = await load(`${SDK}/firebase-messaging.js`);
  const app = getApps().length ? getApps()[0] : initializeApp(FIREBASE);
  return (await getToken(getMessaging(app), { vapidKey: VAPID, serviceWorkerRegistration: reg })) || null;
}

/** Files the token with the app's default switches (PushSettings): all on
 *  but real estate, as a new phone starts. */
async function register(token: string, lang: 'he' | 'en') {
  await client().rpc('register_push_device', {
    p_token: token, p_platform: 'web', p_locale: lang, p_enabled: true,
    p_news: true, p_events: true, p_businesses: true, p_deals: true, p_realestate: false,
    p_neighborhood: true, p_neighborhood_id: null, p_app_version: null, p_replies: true, p_jobs: true,
  });
}

/** Refreshes the token and its row for a browser that already allowed
 *  notifications, without asking anything (each visit, as the old site). */
export async function refreshPush(lang: 'he' | 'en'): Promise<void> {
  if (permission() !== 'granted') return;
  try {
    const token = await firebaseToken();
    if (!token) return;
    const had = savedToken();
    write(TOKEN, token);
    await register(token, lang);
    if (had !== token) changed();
  } catch (e) {
    // The next visit tries again; said in the console, as the app's debug log does.
    console.warn('Push registration:', e);
  }
}

/** "Turn on": the browser's question — only ever from a tap — then the
 *  token and its row. Returns whether notifications are on afterwards. */
export async function turnOnPush(lang: 'he' | 'en'): Promise<boolean> {
  if (!pushSupported()) return false;
  const answer = await Notification.requestPermission();
  if (answer !== 'granted') { changed(); return false; }
  await refreshPush(lang);
  changed();
  return true;
}

/** What the bell lists: sent to this browser, or to everyone before it has
 *  a token; the last 60 days. */
export async function pushFeed(): Promise<PushItem[]> {
  const { data } = await client().rpc('push_feed', { p_token: savedToken(), p_limit: 50 });
  return (data ?? []) as PushItem[];
}

/** When the bell was last opened. The first visit sets it to now, so a new
 *  browser does not open on weeks of "unread". */
export function seenAt(): number {
  const saved = read<string>(SEEN);
  const at = saved ? Date.parse(saved) : NaN;
  if (!Number.isNaN(at)) return at;
  const now = new Date();
  write(SEEN, now.toISOString());
  return now.getTime();
}

export function markSeen() {
  write(SEEN, new Date().toISOString());
  changed();
}

export function openedIds(): Set<string> {
  return new Set(read<string[]>(OPENED) ?? []);
}

export function isUnread(item: PushItem, seen: number, opened: Set<string>): boolean {
  return Date.parse(item.sent_at) > seen && !opened.has(item.id);
}

/** A notification was opened (from the list, or by the address a
 *  notification opened): counted in the panel and no longer unread. */
export function recordOpen(campaignId: string) {
  const ids = [...openedIds()];
  if (!ids.includes(campaignId)) {
    ids.push(campaignId);
    write(OPENED, ids.slice(-200));
    changed();
  }
  const token = savedToken();
  if (!token) return;
  void client().rpc('record_push_event', { p_campaign: campaignId, p_token: token, p_kind: 'open' })
    .then(() => undefined, () => undefined);
}
