'use client';
import { useEffect, useState } from 'react';
import { MapContainer, Marker, TileLayer, Tooltip, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { MapPin } from './MapView';

const KEY = process.env.NEXT_PUBLIC_MAPS_WEB_KEY ?? '';

type Session = { token: string; copyright: string };
const sessions: Partial<Record<'he' | 'en', Promise<Session | null>>> = {};

/** A Google Map Tiles session for the page's language (as web_map_tiles.dart):
 *  a Hebrew map for the Hebrew site, an English one for the English. The key
 *  is restricted to the site's addresses, so elsewhere — a local build — the
 *  session is refused and the map shows its pins on a plain background. */
function session(lang: 'he' | 'en'): Promise<Session | null> {
  if (!KEY) return Promise.resolve(null);
  sessions[lang] ??= (async () => {
    try {
      const r = await fetch(`https://tile.googleapis.com/v1/createSession?key=${KEY}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mapType: 'roadmap', language: lang === 'he' ? 'he-IL' : 'en-US', region: 'IL' }),
      });
      if (!r.ok) return null;
      const token = (await r.json()).session as string;
      let copyright = `Map data ©${new Date().getFullYear()} Google`;
      try {
        const v = await fetch(`https://tile.googleapis.com/tile/v1/viewport?session=${token}&key=${KEY}&zoom=13&north=31.93&south=31.86&east=35.06&west=34.96`);
        if (v.ok) copyright = (await v.json()).copyright || copyright;
      } catch { /* the default credit */ }
      return { token, copyright };
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

export default function LeafletMap({ pins, center, zoom = 14, interactive = true, fit = true, lang, onPick }: {
  pins: MapPin[]; center?: [number, number]; zoom?: number; interactive?: boolean; fit?: boolean;
  lang: 'he' | 'en'; onPick?: (pin: MapPin) => void;
}) {
  const [s, setS] = useState<Session | null | undefined>(undefined);
  useEffect(() => { session(lang).then(setS); }, [lang]);
  const c = center ?? (pins[0] ? [pins[0].lat, pins[0].lng] as [number, number] : [31.8969, 35.0095] as [number, number]);
  return (
    <MapContainer center={c} zoom={zoom} zoomControl={interactive} dragging={interactive} scrollWheelZoom={interactive}
      doubleClickZoom={interactive} touchZoom={interactive} attributionControl={!!s}
      className="isolate z-0 size-full bg-[#E8EAED]" style={{ direction: 'ltr' }}>
      {s && (
        <TileLayer url={`https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session=${s.token}&key=${KEY}`}
          attribution={`<img src="/web/common/google_logo.png" alt="Google" style="height:14px;display:inline;vertical-align:middle"> ${s.copyright}`}
          maxZoom={20} tileSize={256} />
      )}
      {pins.map((p) => (
        <Marker key={p.id} position={[p.lat, p.lng]}
          icon={L.icon({ iconUrl: p.icon ?? '/web/business/map_marker.svg', iconSize: p.size ?? [40, 44], iconAnchor: [(p.size?.[0] ?? 40) / 2, p.size?.[1] ?? 44] })}
          eventHandlers={{ click: () => { if (onPick) onPick(p); else if (p.href) window.location.href = p.href; } }}>
          {p.label && <Tooltip direction="top" offset={[0, -(p.size?.[1] ?? 44)]}>{p.label}</Tooltip>}
        </Marker>
      ))}
      <FitPins pins={pins} fit={fit} />
    </MapContainer>
  );
}
