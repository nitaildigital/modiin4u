'use client';

/** The visitor's position, for "near you" (the app's location switch): asked
 *  for only when they tap a location button, then kept for this browser so
 *  the lists stay sorted by distance on later pages. Browsers give it only
 *  to secure pages (https), so on plain http there is none. */
export type Position = { lat: number; lng: number };

const KEY = 'modiin4u.position';
const EVENT = 'modiin4u:position';

export function canLocate(): boolean {
  return typeof window !== 'undefined' && window.isSecureContext && 'geolocation' in navigator;
}

export function savedPosition(): Position | null {
  try {
    const v = JSON.parse(localStorage.getItem(KEY) ?? 'null');
    return v && typeof v.lat === 'number' && typeof v.lng === 'number' ? v : null;
  } catch { return null; }
}

function keep(p: Position) {
  try { localStorage.setItem(KEY, JSON.stringify(p)); } catch { /* private window: this page only */ }
  window.dispatchEvent(new CustomEvent<Position>(EVENT, { detail: p }));
}

/** Asks the browser (it shows its own prompt the first time). */
export function locate(): Promise<Position> {
  return new Promise((resolve, reject) => {
    if (!canLocate()) return reject(new Error('unavailable'));
    navigator.geolocation.getCurrentPosition(
      (g) => { const p = { lat: g.coords.latitude, lng: g.coords.longitude }; keep(p); resolve(p); },
      reject,
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 300000 },
    );
  });
}

/** The saved position, or a fresh one when the visitor already allowed it
 *  (no prompt); then every later change. Returns the unsubscribe. */
export function watchPosition(on: (p: Position) => void): () => void {
  const listener = (e: Event) => on((e as CustomEvent<Position>).detail);
  window.addEventListener(EVENT, listener);
  const saved = savedPosition();
  if (saved) on(saved);
  else if (canLocate() && navigator.permissions?.query) {
    navigator.permissions.query({ name: 'geolocation' as PermissionName })
      .then((s) => { if (s.state === 'granted') locate().catch(() => {}); })
      .catch(() => {});
  }
  return () => window.removeEventListener(EVENT, listener);
}

/** Metres between two points (haversine). */
export function distance(a: Position, b: Position): number {
  const r = (d: number) => (d * Math.PI) / 180;
  const h = Math.sin(r(b.lat - a.lat) / 2) ** 2 + Math.cos(r(a.lat)) * Math.cos(r(b.lat)) * Math.sin(r(b.lng - a.lng) / 2) ** 2;
  return 2 * 6371000 * Math.asin(Math.sqrt(h));
}
