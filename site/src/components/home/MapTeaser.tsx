'use client';
import { useState } from 'react';
import { MapView, type MapPin } from '@/components/map/MapView';

export type Layer = { id: 'businesses' | 'events' | 'realestate'; label: string; pins: MapPin[] };

/** The map card (web_home_screen.dart, _buildMapSection): "Explore Modiin",
 *  a switch per layer that filters the pins, Open Map, and the map itself —
 *  a preview, not the map: it does not pan or zoom, a pin opens its place
 *  and anywhere else opens the map page. */
export function MapTeaser({ title, subtitle, layers, openLabel, lang }: {
  title: string; subtitle: string; layers: Layer[]; openLabel: string; lang: 'he' | 'en';
}) {
  const [on, setOn] = useState<Set<string>>(() => new Set(layers.map((l) => l.id)));
  const toggle = (id: string) => setOn((s) => {
    const n = new Set(s);
    if (!n.delete(id)) n.add(id);
    return n;
  });
  const pins = layers.filter((l) => on.has(l.id)).flatMap((l) => l.pins);

  return (
    <div className="flex h-[518px] gap-[68px] rounded-xl border border-line bg-white p-[25px]">
      <div className="w-[311px] shrink-0">
        <h2 className="font-nunito text-[28px] font-semibold leading-[1.22] text-midblue">{title}</h2>
        <p className="mt-2.5 text-sm leading-[1.21] text-gray-text">{subtitle}</p>
        <ul className="mt-8">
          {layers.map((l, i) => {
            const active = on.has(l.id);
            return (
              <li key={l.id}>
                <button type="button" role="switch" aria-checked={active} onClick={() => toggle(l.id)}
                  className={`flex w-full items-center gap-4 py-4 text-start ${i < layers.length - 1 ? 'border-b border-line' : ''}`}>
                  <img src={`/web/home/layer_${l.id}.svg`} alt="" width={24} height={24} className={`size-6 ${active ? '' : 'opacity-40'}`} />
                  <span className="flex-1 text-base font-medium leading-[1.21] text-black">{l.label}</span>
                  {/* The design's switch: 44 × 24, a 20 knob two in from the edge. */}
                  <span className={`flex h-6 w-11 shrink-0 items-center rounded-xl px-0.5 transition-colors ${active ? 'justify-end bg-midblue' : 'justify-start bg-[#D5D7DB]'}`}>
                    <span className="size-5 rounded-full bg-white" />
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
        <a href="/map/" className="mt-8 inline-flex items-center gap-2 rounded-[60px] bg-midblue px-6 py-2 text-sm font-medium leading-6 text-white hover:bg-midblue/90">
          {openLabel}
          <img src="/web/home/arrow_open_map.svg" alt="" width={20} height={20} className={`size-5 ${lang === 'he' ? '-scale-x-100' : ''}`} />
        </a>
      </div>
      <div className="relative min-w-0 flex-1 cursor-pointer overflow-hidden rounded-2xl"
        onClick={(e) => { if (!(e.target as HTMLElement).closest('.leaflet-marker-icon, .leaflet-control-attribution')) window.location.href = '/map/'; }}>
        <MapView pins={pins} center={[31.8928, 35.0104]} zoom={13} interactive={false} fit={false} lang={lang} />
      </div>
    </div>
  );
}
