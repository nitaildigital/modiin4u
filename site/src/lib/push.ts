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
/** When this browser's row was last filed, and the feed as last read. */
const FILED = 'modiin4u.push_filed_at';
const FEED = 'modiin4u.push_feed';
/** How long a page reuses the feed another page read: every page draws the
 *  bell, and the bell need not ask the database on each one. */
const FEED_FOR_MS = 5 * 60 * 1000;
const FILE_EVERY_MS = 24 * 60 * 60 * 1000;
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

/** A notification that came while a page of the site is open in front: the
 *  browser leaves it to the page (Firebase shows nothing then), and the
 *  page shows its own banner, as the current site does. */
export type ForegroundPush = { campaignId: string | null; link: string | null; title: string; body: string };

let listening = false;

async function listen(app: unknown) {
  if (listening) return;
  listening = true;
  const { getMessaging, onMessage } = await load(`${SDK}/firebase-messaging.js`);
  onMessage(getMessaging(app), (m: { notification?: { title?: string; body?: string }; data?: Record<string, string> }) => {
    const detail: ForegroundPush = {
      campaignId: m.data?.campaign_id ?? null, link: m.data?.link ?? null,
      title: m.notification?.title ?? '', body: m.notification?.body ?? '',
    };
    window.dispatchEvent(new CustomEvent<ForegroundPush>(PUSH_FOREGROUND, { detail }));
    // The bell's list and count read again.
    forgetFeed();
    changed();
  });
}

/** Fired on window with a [ForegroundPush] as its detail. */
export const PUSH_FOREGROUND = 'modiin4u-push-foreground';

async function firebaseToken(): Promise<string | null> {
  const reg = await navigator.serviceWorker.register('/firebase-messaging-sw.js', { scope: '/firebase-cloud-messaging-push-scope' });
  const { initializeApp, getApps } = await load(`${SDK}/firebase-app.js`);
  const { getMessaging, getToken } = await load(`${SDK}/firebase-messaging.js`);
  const app = getApps().length ? getApps()[0] : initializeApp(FIREBASE);
  const token = (await getToken(getMessaging(app), { vapidKey: VAPID, serviceWorkerRegistration: reg })) || null;
  if (token) void listen(app);
  return token;
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
    // The row is filed again when the token changed, and otherwise once a
    // day (to say the browser is still here) — not on every page.
    const filed = read<{ at: number; token: string; lang: string }>(FILED);
    if (had === token && filed && filed.token === token && filed.lang === lang && Date.now() - filed.at < FILE_EVERY_MS) return;
    await register(token, lang);
    write(FILED, { at: Date.now(), token, lang });
    if (had !== token) { forgetFeed(); changed(); }
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
  // A first "Turn on" files the row whatever was filed before.
  try { localStorage.removeItem(FILED); } catch { /* filed anyway */ }
  await refreshPush(lang);
  forgetFeed();
  changed();
  return true;
}

/** What the bell lists: sent to this browser, or to everyone before it has
 *  a token; the last 60 days. */
export async function pushFeed(): Promise<PushItem[]> {
  const token = savedToken();
  try {
    const kept = JSON.parse(sessionStorage.getItem(FEED) ?? 'null') as { at: number; token: string | null; items: PushItem[] } | null;
    if (kept && kept.token === token && Date.now() - kept.at < FEED_FOR_MS) return kept.items;
  } catch { /* read it */ }
  const { data, error } = await client().rpc('push_feed', { p_token: token, p_limit: 50 });
  if (error) throw error;
  const items = (data ?? []) as PushItem[];
  try { sessionStorage.setItem(FEED, JSON.stringify({ at: Date.now(), token, items })); } catch { /* not kept */ }
  return items;
}

/** A new notification, or a new token: the next look at the bell reads the
 *  feed again. */
function forgetFeed() {
  try { sessionStorage.removeItem(FEED); } catch { /* nothing kept */ }
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
