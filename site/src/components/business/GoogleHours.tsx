'use client';
import { useEffect, useState } from 'react';

/** The website's Places key, restricted to the site's addresses. Without it
 *  (a local build) nothing is asked and nothing drawn. */
const KEY = process.env.NEXT_PUBLIC_PLACES_WEB_KEY ?? '';

type Hours = { lines: string[]; mapsUri: string | null };
const asked: Record<string, Promise<Hours | null>> = {};

/** A business's hours from Google, for a business with none of its own and
 *  a place ID (00073; fetchGoogleHours). Google's terms let us keep the ID,
 *  not the hours, so they are asked for each time the page opens, and only
 *  these two fields, so the request is billed for nothing else. */
function googleHours(placeId: string, language: 'he' | 'en'): Promise<Hours | null> {
  const k = `${placeId}:${language}`;
  asked[k] ??= (async () => {
    try {
      const r = await fetch(`https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}?languageCode=${language}`, {
        headers: { 'X-Goog-Api-Key': KEY, 'X-Goog-FieldMask': 'regularOpeningHours.weekdayDescriptions,googleMapsUri' },
      });
      if (!r.ok) return null;
      const j = await r.json();
      const lines: string[] = j?.regularOpeningHours?.weekdayDescriptions ?? [];
      return lines.length ? { lines, mapsUri: j.googleMapsUri ?? null } : null;
    } catch {
      return null;
    }
  })();
  return asked[k];
}

/** Google's "יום ראשון: 7:00–0:00" set right to left would read the range
 *  back to front; the part after the day's name is isolated left to right
 *  (googleHoursLine). */
function line(s: string): string {
  const i = s.indexOf(': ');
  return i < 0 ? s : `${s.slice(0, i + 2)}⁦${s.slice(i + 2)}⁩`;
}

/** Nothing while they load or if Google has none — an empty "Opening hours"
 *  would say the business keeps none. With Google's mark and a link to the
 *  place, as Google's terms ask. */
export function GoogleHours({ placeId, lang, phone = false }: { placeId: string; lang: 'he' | 'en'; phone?: boolean }) {
  const [g, setG] = useState<Hours | null>(null);
  useEffect(() => {
    if (!KEY) return;
    let live = true;
    googleHours(placeId, lang).then((h) => { if (live) setG(h); });
    return () => { live = false; };
  }, [placeId, lang]);
  if (!g) return null;
  const he = lang === 'he';
  return (
    <div className={phone ? 'mt-6' : 'px-5 pt-4'}>
      <p className={phone ? 'text-base font-semibold text-[#1F1F1F]' : 'text-sm font-semibold text-[#3D3D3D]'}>{he ? 'שעות פתיחה' : 'Opening hours'}</p>
      <div className={phone ? 'mt-3' : 'mt-2'}>
        {g.lines.map((l, i) => <p key={i} className="text-sm font-medium leading-[1.6] text-[#3D3D3D]">{line(l)}</p>)}
      </div>
      <div className="mt-2.5 flex flex-wrap items-center gap-x-2.5 gap-y-1.5">
        <img src="/web/common/google_logo.png" alt="Google" className="h-4 w-auto" />
        <span className="text-xs text-[#5F5E5A]">{he ? 'מידע מתוך Google Maps' : 'Information from Google Maps'}</span>
        {g.mapsUri && (
          <a href={g.mapsUri} target="_blank" rel="noopener" className="text-xs font-semibold text-midblue">
            {he ? 'צפייה ב-Google Maps' : 'View on Google Maps'}
          </a>
        )}
      </div>
    </div>
  );
}
