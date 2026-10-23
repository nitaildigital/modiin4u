'use client';
import { useSyncExternalStore } from 'react';

/**
 * The visitor's cookie choice (the client, 23 Oct): what may run beyond what
 * the site needs to work.
 *
 * Israel's Privacy Protection Authority, in its consent opinion of 25 Feb
 * 2026 under Amendment 13, prefers explicit, active consent and treats the
 * cookie banner as a real check rather than a formality; Google (Consent
 * Mode v2) and Microsoft Clarity (from 31 Oct 2025) expect consent signals
 * for visitors from Europe. So nothing optional runs until the visitor has
 * chosen: "Accept all" and "Essential only" side by side, the two optional
 * groups never ticked in advance, and the choice open again from the footer.
 *
 * - analytics: Google Analytics, Microsoft Clarity, Hotjar, and the browser's
 *   own random visitor id behind the panel's statistics (stats.ts).
 * - marketing: the Meta Pixel.
 *
 * Essential, never asked: the language, the sign-in session for Messages,
 * notifications the visitor turned on, the map and the place they chose, and
 * this choice itself.
 */
export type Consent = { analytics: boolean; marketing: boolean };

const COOKIE = 'm4u_consent';
/** Raised when what is asked changes, so everyone is asked again. */
const VERSION = 1;
const YEAR = 60 * 60 * 24 * 365;
const CHANGED = 'm4u-consent-changed';
const OPEN = 'm4u-consent-open';

function read(): Consent | null {
  if (typeof document === 'undefined') return null;
  const raw = document.cookie.split('; ').find((c) => c.startsWith(COOKIE + '='));
  if (!raw) return null;
  try {
    const v = JSON.parse(decodeURIComponent(raw.slice(COOKIE.length + 1))) as { v?: number; a?: boolean; m?: boolean };
    if (v.v !== VERSION) return null;
    return { analytics: v.a === true, marketing: v.m === true };
  } catch {
    return null;
  }
}

// The cookie read once per change, so every subscriber sees the same object.
let cached: Consent | null | undefined;
function snapshot(): Consent | null {
  if (cached === undefined) cached = read();
  return cached;
}

/** Records the choice for a year and tells the page. Taking back a consent
 *  given earlier reloads it: a script that has already run cannot be
 *  unloaded, and the tools' own cookies are cleared as far as the site can. */
export function saveConsent(next: Consent): void {
  const before = snapshot();
  const value = encodeURIComponent(JSON.stringify({ v: VERSION, a: next.analytics, m: next.marketing, t: Date.now() }));
  document.cookie = `${COOKIE}=${value}; path=/; max-age=${YEAR}; samesite=lax`;
  cached = next;
  window.dispatchEvent(new Event(CHANGED));
  const withdrawn = (before?.analytics && !next.analytics) || (before?.marketing && !next.marketing);
  if (withdrawn) {
    clearToolCookies(next);
    window.location.reload();
  }
}

/** The tools' cookies on this site's domains: Google Analytics (_ga…),
 *  Clarity (_clck, _clsk, CLID), Hotjar (_hj…), Meta (_fbp, _fbc). */
function clearToolCookies(keep: Consent): void {
  const names = document.cookie.split('; ').map((c) => c.split('=')[0]);
  const analytics = /^(_ga|_gid|_gat|_clck|_clsk|CLID|_hj)/;
  const marketing = /^(_fbp|_fbc)/;
  const host = window.location.hostname;
  const domains = ['', host, '.' + host.replace(/^www\./, '')];
  for (const n of names) {
    if ((!keep.analytics && analytics.test(n)) || (!keep.marketing && marketing.test(n))) {
      for (const d of domains) document.cookie = `${n}=; path=/; max-age=0${d ? `; domain=${d}` : ''}`;
    }
  }
  try {
    if (!keep.analytics) localStorage.removeItem('flutter.stats_visitor');
  } catch { /* storage refused */ }
}

function subscribe(onChange: () => void): () => void {
  window.addEventListener(CHANGED, onChange);
  return () => window.removeEventListener(CHANGED, onChange);
}

/** The choice, or null while none has been made. On the server, and in the
 *  first render in the browser, it is undefined: nothing optional is drawn
 *  until the page knows. */
export function useConsent(): Consent | null | undefined {
  return useSyncExternalStore(subscribe, snapshot, () => undefined);
}

/** The choice without a hook, for code outside React (stats.ts). */
export function currentConsent(): Consent | null {
  return snapshot();
}

/** Opens the settings again — the footer's "Cookie settings". */
export function openConsentSettings(): void {
  window.dispatchEvent(new Event(OPEN));
}

export function onOpenConsentSettings(handler: () => void): () => void {
  window.addEventListener(OPEN, handler);
  return () => window.removeEventListener(OPEN, handler);
}
