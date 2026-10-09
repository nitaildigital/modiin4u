'use client';
import { useMemo, useState } from 'react';
import Link from 'next/link';
import { CloseCircle, Location, SearchNormal1 } from 'iconsax-react';
import { MapView, type MapPin } from '@/components/map/MapView';
import { useDesk } from '@/components/municipal/useDesk';
import type { Lang } from '@/lib/i18n';
import { LAYER_LOOK, type CityPin, type MapLayer, type MapSlide } from '@/lib/data/map-shared';

const CENTER: [number, number] = [31.8928, 35.0104];

/** The desktop card's order (web_map_screen.dart), and the phone's chips'
 *  (map_screen.dart). */
const DESK_LAYERS: MapLayer[] = ['Businesses', 'Events', 'Real Estate', 'Parkings'];
const PHONE_LAYERS: MapLayer[] = ['Businesses', 'Events', 'Parkings', 'Real Estate'];

function layerLabel(layer: MapLayer, lang: Lang, desk: boolean): string {
  const he = lang === 'he';
  switch (layer) {
    case 'Businesses': return he ? 'עסקים' : 'Businesses';
    case 'Events': return he ? 'אירועים' : 'Events';
    case 'Parkings': return he ? 'חניונים' : desk ? 'Car parks' : 'Parkings';
    default: return he ? (desk ? 'נדל״ן' : 'נדל"ן') : 'Real Estate';
  }
}

/** The design's "Apartment Slide", 356 wide: photographs, the badge, the
 *  headline, the facts and the address, the row's own description, more
 *  details, and the way to its page. */
function Slide({ s, lang, onClose }: { s: MapSlide; lang: Lang; onClose: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [index, setIndex] = useState(0);
  const count = s.photos.length;
  const thumbs = s.photos.slice(1, 5);
  const hidden = count - 1 - thumbs.length;
  const placeholder = 'bg-[linear-gradient(135deg,#0058B5,#010A36)]';
  return (
    <div className="relative max-h-full w-[356px] overflow-y-auto rounded-2xl bg-white p-4 shadow-[0_0_4px_rgba(0,0,0,0.2)]">
      <div className="relative h-[190px] w-[324px] overflow-hidden rounded-xl">
        {count ? <img src={s.photos[index % count]} alt="" className="size-full object-cover" /> : <div className={`size-full ${placeholder}`} />}
        {count > 1 && (
          <>
            <span dir="ltr" className="absolute bottom-3 end-3 rounded-full bg-black/70 px-3 py-1.5 text-xs font-medium text-white">{`${index % count + 1} / ${count}`}</span>
            <button type="button" aria-label={t('הקודמת', 'Previous')} onClick={() => setIndex((index + count - 1) % count)} className="absolute start-2.5 top-[79px] flex size-8 items-center justify-center rounded-2xl bg-white">
              <img src="/web/map/slide_arrow.svg" alt="" width={16} height={16} className="ltr:-scale-x-100" />
            </button>
            <button type="button" aria-label={t('הבאה', 'Next')} onClick={() => setIndex((index + 1) % count)} className="absolute end-3 top-[79px] flex size-8 items-center justify-center rounded-2xl bg-white">
              <img src="/web/map/slide_arrow.svg" alt="" width={16} height={16} className="rtl:-scale-x-100" />
            </button>
          </>
        )}
      </div>
      <span className="mt-3 inline-flex max-w-full items-center gap-1 rounded-full px-2 py-1.5 text-xs font-medium" style={{ color: s.badgeColor, background: s.badgeColor + '26' }}>
        {s.badgeIcon && <span className="size-3.5 shrink-0" style={{ background: s.badgeColor, mask: `url(${s.badgeIcon}) center / contain no-repeat`, WebkitMask: `url(${s.badgeIcon}) center / contain no-repeat` }} />}
        <span className="truncate">{s.badge}</span>
      </span>
      <div className="mt-4 flex items-center gap-2">
        <span className="line-clamp-2 font-nunito text-xl font-semibold leading-[25px] text-navy">{s.headline}</span>
        {s.perMonth && <span className="shrink-0 text-sm text-gray-text">{s.perMonth}</span>}
        {s.tag && <span className="ms-auto shrink-0 ps-3 text-xs font-medium text-turquoise">{s.tag}</span>}
      </div>
      {s.facts.length > 0 && <p className="mt-4 flex flex-wrap gap-x-[30px] gap-y-1.5 text-xs text-[#3D3D3D]">{s.facts.map((f) => <span key={f}>{f}</span>)}</p>}
      {s.address && (
        <p className="mt-4 flex items-start gap-1.5 text-xs text-[#3D3D3D]"><img src="/web/map/slide_pin.svg" alt="" width={14} height={14} />{s.address}</p>
      )}
      {(s.about || count > 1) && (
        <div className="mt-6">
          {s.about && (
            <>
              <p className="text-sm font-medium text-black">{s.aboutTitle}</p>
              <p className="mt-3 text-xs leading-[1.6] text-[#3D3D3D]">{s.about}</p>
            </>
          )}
          {thumbs.length > 0 && (
            <div className="mt-3 flex gap-2">
              {thumbs.map((p, i) => (
                <button key={p + i} type="button" onClick={() => setIndex(i + 1)} className="relative size-[75px] overflow-hidden rounded-[7px]">
                  <img src={p} alt="" className="size-full object-cover" />
                  {i === thumbs.length - 1 && hidden > 0 && <span className="absolute inset-0 flex items-center justify-center bg-black/50 text-base font-semibold text-white">+{hidden + 1}</span>}
                </button>
              ))}
            </div>
          )}
        </div>
      )}
      {s.details.length > 0 && (
        <div className="mt-6">
          <p className="text-sm font-medium text-black">{t('פרטים נוספים', 'More Details')}</p>
          <dl className="mt-3 flex flex-col gap-4 text-xs text-[#3D3D3D]">
            {s.details.map(([k, v]) => <div key={k} className="flex"><dt className="w-[120px] shrink-0">{k}</dt><dd>{v}</dd></div>)}
          </dl>
        </div>
      )}
      {s.route && (
        <Link href={s.route} className="mt-6 flex items-center justify-center gap-2 rounded-full bg-midblue px-6 py-3 text-base font-medium text-white">
          {t('לפרטים המלאים', 'View Full Details')}
          <img src="/web/map/slide_cta.svg" alt="" width={20} height={20} className="rtl:-scale-x-100" />
        </Link>
      )}
      <button type="button" onClick={onClose} aria-label={t('סגירה', 'Close')} className="absolute end-6 top-6 flex size-8 items-center justify-center rounded-full bg-white/90 text-lg leading-none text-black/85 shadow-[0_0_4px_rgba(0,0,0,0.2)]">×</button>
    </div>
  );
}

/** The phone's card for the chosen pin, at the foot of the map. */
function PhoneCard({ s, layer, lang, onClose }: { s: MapSlide; layer: MapLayer; lang: Lang; onClose: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const color = LAYER_LOOK[layer].color;
  const action = layer === 'Parkings' && s.waze ? { href: s.waze, label: t('ניווט', 'Get Directions'), external: true }
    : s.route ? { href: s.route, label: t('לפרטים מלאים', 'View Full Details'), external: false } : null;
  return (
    <div className="rounded-xl bg-white p-3 shadow-[0_2px_8px_rgba(0,0,0,0.1)]">
      <div className="flex gap-3">
        <div className="relative h-[140px] w-[120px] shrink-0 overflow-hidden rounded-lg" style={{ background: `linear-gradient(135deg, ${color}29, ${color}14)` }}>
          {s.photos[0] && <img src={s.photos[0]} alt="" className="size-full object-cover" />}
          <button type="button" onClick={onClose} aria-label={t('סגירה', 'Close')} className="absolute end-1 top-1 flex size-6 items-center justify-center rounded-full bg-white text-sm leading-none text-[#3D3D3D]">×</button>
        </div>
        <div className="flex min-w-0 flex-1 flex-col">
          {layer === 'Real Estate' && s.tag && <p className="mb-2 text-xs font-medium text-turquoise">{s.tag}</p>}
          <p className="truncate font-nunito text-xl font-semibold leading-[25px] text-navy">{s.headline}</p>
          {layer !== 'Real Estate' && layer !== 'Parkings' && <p className="mt-2 truncate text-sm text-gray-text">{s.badge}</p>}
          {s.address && <p className="mt-[11px] flex items-center gap-2 text-xs text-gray-text"><Location size={14} color="#17A9D0" variant="Bold" className="shrink-0" /><span className="truncate">{s.address}</span></p>}
          {s.facts.length > 0 && <p className="mt-auto flex flex-wrap gap-x-4 gap-y-1 pt-2 text-xs text-[#3D3D3D]">{s.facts.filter((f) => f !== s.badge).map((f) => <span key={f}>{f}</span>)}</p>}
          {layer !== 'Real Estate' && s.tag && <p className="pt-1 font-nunito text-base font-semibold text-navy">{s.tag}</p>}
        </div>
      </div>
      {action && (
        <a href={action.href} {...(action.external ? { target: '_blank', rel: 'noopener' } : {})}
          className="mt-3 flex h-11 items-center justify-center gap-2 rounded-full bg-midblue text-sm font-medium text-white">
          {action.label}
        </a>
      )}
    </div>
  );
}

/** The city map (web_map_screen.dart; map_screen.dart on the phone): every
 *  business, event, property and car park on Google's map, the layers to
 *  switch, a search over names and addresses, and the chosen pin's card. */
export function CityMap({ pins, lang, title, intro }: { pins: CityPin[]; lang: Lang; title: string; intro: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const desk = useDesk();
  const [layers, setLayers] = useState<Set<MapLayer>>(() => new Set(DESK_LAYERS));
  const [q, setQ] = useState('');
  const [selected, setSelected] = useState<CityPin | null>(null);

  const needle = q.trim().toLowerCase();
  const visible = useMemo(() => pins.filter((p) => layers.has(p.layer) && (!needle || p.search.includes(needle))), [pins, layers, needle]);
  const mapPins = useMemo<MapPin[]>(() => visible.map((p) => ({ id: p.id, lat: p.lat, lng: p.lng, icon: LAYER_LOOK[p.layer].pin, size: [40, 43] })), [visible]);
  const byId = useMemo(() => new Map(pins.map((p) => [p.id, p])), [pins]);

  function toggle(layer: MapLayer) {
    const next = new Set(layers);
    if (next.has(layer)) next.delete(layer); else next.add(layer);
    setLayers(next);
    if (selected?.layer === layer) setSelected(null);
  }
  function search(v: string) {
    setQ(v);
    setSelected(null);
  }

  const map = <MapView pins={mapPins} lang={lang} center={CENTER} zoom={15} fit={false} recenter={!!desk}
    selectedId={selected?.id} onMapClick={() => setSelected(null)} onPick={(p) => setSelected(byId.get(p.id) ?? null)} />;

  return (
    <div className="citymap relative h-[calc(100dvh-56px-76px)] min-h-[480px] desk:h-[calc(100vh-81px)] desk:min-h-[640px]">
      {/* The zoom buttons at the map's foot on the far side, where the
          design has its controls, clear of the layer card; the phone's frame
          has none — pinching zooms. */}
      <style>{`.citymap .leaflet-top.leaflet-left{top:auto;bottom:24px;${lang === 'he' ? 'left:16px' : 'left:auto;right:16px'}}@media (max-width:1099.98px){.citymap .leaflet-control-zoom{display:none}}`}</style>
      <div className="absolute inset-0 bg-[#E8EAED]">{desk != null && map}</div>
      <h1 className="max-desk:sr-only desk:absolute desk:start-9 desk:top-9 desk:z-[501] desk:font-nunito desk:text-2xl desk:font-semibold desk:leading-[30px] desk:text-midblue">{title}</h1>

      {/* ── Desktop: the layer card, the search pill, the slide ── */}
      <div className="absolute start-4 top-4 z-[500] hidden w-[275px] rounded-xl bg-white p-5 shadow-[0_0_4px_rgba(0,0,0,0.2)] desk:block">
        <p className="mt-10 text-sm leading-[17px] text-gray-text">{intro}</p>
        <ul className="mt-5">
          {DESK_LAYERS.map((layer, i) => {
            const on = layers.has(layer);
            return (
              <li key={layer} className={i < DESK_LAYERS.length - 1 ? 'border-b border-line pb-4' : ''}>
                <button type="button" role="switch" aria-checked={on} onClick={() => toggle(layer)} className="flex w-full items-center gap-3 pt-4">
                  <img src={LAYER_LOOK[layer].icon} alt="" width={20} height={20} />
                  <span className="flex-1 truncate text-start text-sm font-medium text-black">{layerLabel(layer, lang, true)}</span>
                  <span className={`flex h-6 w-11 items-center rounded-full p-0.5 transition-colors ${on ? 'justify-end bg-midblue' : 'justify-start bg-[#D9D9D9]'}`}>
                    <span className="size-5 rounded-full bg-white" />
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      </div>
      <div className="pointer-events-none absolute inset-x-0 top-4 z-[500] hidden justify-center desk:flex">
        <label className="pointer-events-auto flex h-[52px] w-[573px] items-center gap-3 rounded-full bg-white px-4 shadow-[0_0_4px_rgba(0,0,0,0.2)]">
          <img src="/web/map/search20.svg" alt="" width={20} height={20} />
          <input value={q} onChange={(e) => search(e.target.value)} placeholder={t('חיפוש מקומות, עסקים או אירועים', 'Search for places, businesses, or events')}
            className="min-w-0 flex-1 bg-transparent text-base text-black outline-none placeholder:text-[#4F4F4F]" />
          {q && <button type="button" onClick={() => search('')} aria-label={t('ניקוי', 'Clear')}><CloseCircle size={20} color="#6D6D6D" /></button>}
        </label>
      </div>
      {selected && desk && (
        <div className="absolute bottom-4 end-4 top-4 z-[600] flex max-h-[832px] items-start">
          <Slide key={selected.id} s={selected.slide} lang={lang} onClose={() => setSelected(null)} />
        </div>
      )}

      {/* ── Phone: the search bar and the layer chips, the card at the foot ── */}
      <div className="pointer-events-none absolute inset-x-0 top-3.5 z-[500] desk:hidden">
        <label className="pointer-events-auto mx-4 flex h-12 items-center gap-2 rounded-full border border-line bg-white px-4 shadow-[0_2px_8px_rgba(0,0,0,0.1)]">
          <SearchNormal1 size={18} color="#6D6D6D" />
          <input type="search" value={q} onChange={(e) => search(e.target.value)} placeholder={t('חיפוש מקומות, עסקים ואירועים', 'Search for places, businesses, or events')}
            className="min-w-0 flex-1 bg-transparent text-sm text-navy outline-none placeholder:text-[#6D6D6D]" />
        </label>
        <div className="pointer-events-auto mt-3 flex gap-2 overflow-x-auto px-4 pb-3">
          {PHONE_LAYERS.map((layer) => {
            const on = layers.has(layer);
            return (
              <button key={layer} type="button" role="checkbox" aria-checked={on} onClick={() => toggle(layer)}
                className="flex h-10 shrink-0 items-center gap-2 rounded-lg border border-line bg-white px-3 shadow-[0_2px_8px_rgba(0,0,0,0.1)]">
                {on ? <img src="/icons/m_map_checkbox_on.svg" alt="" width={18} height={18} /> : <span className="size-[18px] rounded border-[1.5px] border-[#BDBDBD]" />}
                <span className="text-sm font-medium text-navy">{layerLabel(layer, lang, false)}</span>
              </button>
            );
          })}
        </div>
      </div>
      {selected && desk === false && (
        <div className="absolute inset-x-3 bottom-4 z-[600] mx-auto max-w-[369px]">
          <PhoneCard key={selected.id} s={selected.slide} layer={selected.layer} lang={lang} onClose={() => setSelected(null)} />
        </div>
      )}
    </div>
  );
}
