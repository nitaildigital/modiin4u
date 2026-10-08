'use client';
import dynamic from 'next/dynamic';

export type MapPin = {
  id: string; lat: number; lng: number;
  /** A marker image from public/ (e.g. /web/home/map_pin_businesses.svg). */
  icon?: string; size?: [number, number];
  /** Where a click goes, unless the page handles `onPick`. */
  href?: string; label?: string;
};

/** Google's map, drawn by Leaflet from Google's Map Tiles (as the current
 *  site does), with the page's pins. Leaflet needs the browser, so it loads
 *  there; the page's own content stays in the HTML around it. */
export const MapView = dynamic(() => import('./LeafletMap'), {
  ssr: false,
  loading: () => <div className="size-full animate-pulse bg-[#E8EAED]" />,
});
