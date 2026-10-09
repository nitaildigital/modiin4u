'use client';
import dynamic from 'next/dynamic';
import { useEffect, useRef, useState, type ComponentProps } from 'react';

export type MapPin = {
  id: string; lat: number; lng: number;
  /** A marker image from public/ (e.g. /web/home/map_pin_businesses.svg). */
  icon?: string; size?: [number, number];
  /** Where a click goes, unless the page handles `onPick`. */
  href?: string; label?: string;
};

const LeafletMap = dynamic(() => import('./LeafletMap'), {
  ssr: false,
  loading: () => <div className="size-full animate-pulse bg-[#E8EAED]" />,
});

/** Google's map, drawn by Leaflet from Google's Map Tiles (as the current
 *  site does), with the page's pins. Leaflet needs the browser, so it loads
 *  there; the page's own content stays in the HTML around it.
 *
 *  It is drawn only once it is about to come into view: every tile is a
 *  billed request, and the maps at the foot of a business, listing or event
 *  page were loading theirs for every visit, read to the end or not (9 Oct).
 *  Once drawn it stays. */
export function MapView(props: ComponentProps<typeof LeafletMap>) {
  const box = useRef<HTMLDivElement>(null);
  const [near, setNear] = useState(false);
  useEffect(() => {
    if (near) return;
    const el = box.current;
    if (!el || typeof IntersectionObserver === 'undefined') { setNear(true); return; }
    const watch = new IntersectionObserver((seen) => {
      if (seen.some((e) => e.isIntersecting)) { setNear(true); watch.disconnect(); }
    }, { rootMargin: '300px' });
    watch.observe(el);
    return () => watch.disconnect();
  }, [near]);
  return (
    <div ref={box} className="size-full">
      {near ? <LeafletMap {...props} /> : <div className="size-full bg-[#E8EAED]" />}
    </div>
  );
}
