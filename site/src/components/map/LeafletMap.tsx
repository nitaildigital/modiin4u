'use client';
import { useEffect, useState } from 'react';
import { MapContainer, Marker, TileLayer, Tooltip, useMap, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { MapPin } from './MapView';

const KEY = process.env.NEXT_PUBLIC_MAPS_WEB_KEY ?? '';

type Session = { token: string; copyright: string; expires: number };
const sessions: Partial<Record<'he' | 'en', Promise<Session | null>>> = {};
const STORED = 'modiin4u.map_session.';

/** A session kept in the browser for its life (Google gives about two
 *  weeks): a page that started a new one each time gave every tile a new
 *  address, so the browser could never reuse one it already had, and every
 *  map on every page was drawn — and billed — afresh (9 Oct). The credit
 *  is kept with it, so the viewport call is made once too. */
function stored(lang: 'he' | 'en'): Session | null {
  try {
    const s = JSON.parse(localStorage.getItem(STORED + lang) ?? 'null') as Session | null;
    // An hour's margin, so a session never runs out in the middle of a visit.
    return s && s.expires - 3600_000 > Date.now() ? s : null;
  } catch {
    return null;
  }
}

/** A Google Map Tiles session for the page's language (as web_map_tiles.dart):
 *  a Hebrew map for the Hebrew site, an English one for the English. The key
 *  is restricted to the site's addresses, so elsewhere — a local build — the
 *  session is refused and the map shows its pins on a plain background. */
function session(lang: 'he' | 'en'): Promise<Session | null> {
  if (!KEY) return Promise.resolve(null);
  sessions[lang] ??= (async () => {
    const kept = stored(lang);
    if (kept) return kept;
    try {
      const r = await fetch(`https://tile.googleapis.com/v1/createSession?key=${KEY}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mapType: 'roadmap', language: lang === 'he' ? 'he-IL' : 'en-US', region: 'IL' }),
      });
      if (!r.ok) return null;
      const made = await r.json() as { session: string; expiry?: string };
      const token = made.session;
      // Google gives the expiry in seconds; a week if it says nothing.
      const expires = made.expiry ? Number(made.expiry) * 1000 : Date.now() + 7 * 86_400_000;
      let copyright = `Map data ©${new Date().getFullYear()} Google`;
      try {
        const v = await fetch(`https://tile.googleapis.com/tile/v1/viewport?session=${token}&key=${KEY}&zoom=13&north=31.93&south=31.86&east=35.06&west=34.96`);
        if (v.ok) copyright = (await v.json()).copyright || copyright;
      } catch { /* the default credit */ }
      const fresh = { token, copyright, expires };
      try { localStorage.setItem(STORED + lang, JSON.stringify(fresh)); } catch { /* this visit only */ }
      return fresh;
    } catch {
      return null;
    }
  })();
  return sessions[lang]!;
}

function FitPins({ pins, fit }: { pins: MapPin[]; fit: boolean }) {
  const map = useMap();
  useEffect(() => {
    if (!fit || pins.length < 2) return;
    map.fitBounds(L.latLngBounds(pins.map((p) => [p.lat, p.lng] as [number, number])), { padding: [40, 40], maxZoom: 16 });
  }, [map, pins, fit]);
  return null;
}

/** The chosen pin is brought into view, as the current site centres on it. */
function FollowPick({ pin }: { pin: MapPin | undefined }) {
  const map = useMap();
  const at = pin ? `${pin.lat},${pin.lng}` : null;
  // By place, not by object: a page that draws its pins afresh on every
  // hover must not pull the map back each time.
  useEffect(() => { if (at) map.panTo(at.split(',').map(Number) as [number, number], { animate: true }); }, [map, at]);
  return null;
}

/** A click on the map itself, not on a pin: closes the open card. */
function MapClick({ onClick }: { onClick: () => void }) {
  useMapEvents({ click: onClick });
  return null;
}

/** The current site's round "my area" button: back to the city. */
function Recenter({ center, zoom, label }: { center: [number, number]; zoom: number; label: string }) {
  const map = useMap();
  return (
    <div className="leaflet-bottom leaflet-right" style={{ marginBottom: 84 }}>
      <button type="button" aria-label={label} title={label}
        onClick={(e) => { e.stopPropagation(); map.setView(center, zoom); }}
        className="leaflet-control flex size-[34px] items-center justify-center rounded-[4px] border-2 border-black/20 bg-white bg-clip-padding text-[#333] hover:bg-[#f4f4f4]"
        style={{ pointerEvents: 'auto' }}>
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden><circle cx="12" cy="12" r="4" /><circle cx="12" cy="12" r="8" /><path d="M12 2v2M12 20v2M2 12h2M20 12h2" strokeLinecap="round" /></svg>
      </button>
    </div>
  );
}

const MODIIN: [number, number] = [31.8969, 35.0095];
/** Modi'in-Maccabim-Re'ut with a margin: the map stays around the city, so
 *  nobody pans or zooms out across the country loading tiles no page needs. */
const AREA = L.latLngBounds([31.80, 34.88], [32.00, 35.16]);

/** [selectedId] and [hoverId] draw that pin larger and on top (the chosen
 *  pin is also brought into view); [onMapClick] hears a click beside the
 *  pins; [wheel] false leaves the mouse wheel to scroll the page, as the
 *  current site's in-page maps do; [recenter] adds its "back to the city"
 *  button. */
export default function LeafletMap({ pins, center, zoom = 14, interactive = true, fit = true, lang, onPick, selectedId, hoverId, onMapClick, wheel, recenter = false, zoomButtons }: {
  pins: MapPin[]; center?: [number, number]; zoom?: number; interactive?: boolean; fit?: boolean;
  lang: 'he' | 'en'; onPick?: (pin: MapPin) => void;
  selectedId?: string | null; hoverId?: string | null; onMapClick?: () => void; wheel?: boolean; recenter?: boolean;
  /** Leaflet's + and −; off where controls of the page's own sit over the map. */
  zoomButtons?: boolean;
}) {
  const [s, setS] = useState<Session | null | undefined>(undefined);
  useEffect(() => { session(lang).then(setS); }, [lang]);
  const c = center ?? (pins[0] ? [pins[0].lat, pins[0].lng] as [number, number] : MODIIN);
  return (
    <MapContainer center={c} zoom={zoom} zoomControl={zoomButtons ?? interactive} dragging={interactive} scrollWheelZoom={wheel ?? interactive}
      doubleClickZoom={interactive} touchZoom={interactive} attributionControl={!!s}
      minZoom={11} maxZoom={18} maxBounds={AREA} maxBoundsViscosity={1}
      className="isolate z-0 size-full bg-[#E8EAED]" style={{ direction: 'ltr' }}>
      {s && (
        <TileLayer url={`https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session=${s.token}&key=${KEY}`}
          attribution={`<img src="/web/common/google_logo.png" alt="Google" style="height:14px;display:inline;vertical-align:middle"> ${s.copyright}`}
          maxZoom={18} tileSize={256}
          // Tiles are asked for once the map stops, not for every frame of a
          // pan or a zoom — each tile is a billed request.
          updateWhenIdle updateWhenZooming={false} keepBuffer={1} />
      )}
      {pins.map((p) => {
        const big = p.id === selectedId || p.id === hoverId;
        const [w, h] = (p.size ?? [40, 44]).map((n) => (big ? Math.round(n * 1.25) : n));
        return (
          <Marker key={p.id} position={[p.lat, p.lng]} zIndexOffset={big ? 1000 : 0}
            icon={L.icon({ iconUrl: p.icon ?? '/web/business/map_marker.svg', iconSize: [w, h], iconAnchor: [w / 2, h] })}
            eventHandlers={{ click: () => { if (onPick) onPick(p); else if (p.href) window.location.href = p.href; } }}>
            {p.label && <Tooltip direction="top" offset={[0, -h]}>{p.label}</Tooltip>}
          </Marker>
        );
      })}
      <FitPins pins={pins} fit={fit} />
      <FollowPick pin={selectedId ? pins.find((p) => p.id === selectedId) : undefined} />
      {onMapClick && <MapClick onClick={onMapClick} />}
      {recenter && interactive && <Recenter center={center ?? MODIIN} zoom={zoom} label={lang === 'he' ? 'חזרה למודיעין' : 'Back to Modiin'} />}
    </MapContainer>
  );
}
