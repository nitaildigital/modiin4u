'use client';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';

/** A GET form that applies itself: a box ticked or a choice made searches at
 *  once, typing after a pause — as the search page filters as you go. The
 *  address carries every filter, so the results are the server's, in the
 *  page, and a filtered search can be linked to. Empty fields are left out
 *  of the address. */
export function FilterForm({ action, className, children }: { action: string; className?: string; children: React.ReactNode }) {
  const router = useRouter();
  const form = useRef<HTMLFormElement>(null);
  const timer = useRef<number | undefined>(undefined);

  const go = () => {
    const f = form.current;
    if (!f) return;
    const params = new URLSearchParams();
    for (const [k, v] of new FormData(f)) if (typeof v === 'string' && v.trim()) params.append(k, v.trim());
    const qs = params.toString();
    router.push(qs ? `${action}?${qs}` : action, { scroll: false });
  };

  return (
    <form ref={form} action={action} method="get" className={className}
      onSubmit={(e) => { e.preventDefault(); window.clearTimeout(timer.current); go(); }}
      onChange={(e) => {
        const t = e.target as unknown as HTMLInputElement;
        if (t.dataset.manual !== undefined) return;
        window.clearTimeout(timer.current);
        if (t.type === 'search' || t.type === 'text') timer.current = window.setTimeout(go, 600);
        else go();
      }}>
      {children}
    </form>
  );
}

/** The price slider (web_realestate_search_screen.dart, _buildPriceRange):
 *  two handles between the cheapest and the dearest price on file, the
 *  range written above it. Untouched, it sends nothing, so a listing with no
 *  price stays in the results; moved, it sends `min` and `max` when let go. */
export function PriceRange({ bounds, value }: { bounds: [number, number]; value: [number, number] | null }) {
  const [lo, setLo] = useState(value?.[0] ?? bounds[0]);
  const [hi, setHi] = useState(value?.[1] ?? bounds[1]);
  const [touched, setTouched] = useState(!!value);
  const wrap = useRef<HTMLDivElement>(null);
  const [v0, v1, b0, b1] = [value?.[0], value?.[1], bounds[0], bounds[1]];
  // A new search (the address changed) brings its own range.
  useEffect(() => { setLo(v0 ?? b0); setHi(v1 ?? b1); setTouched(v0 != null); }, [v0, v1, b0, b1]);

  const span = bounds[1] - bounds[0] || 1;
  const a = Math.max(bounds[0], Math.min(lo, hi));
  const b = Math.min(bounds[1], Math.max(lo, hi));
  const pct = (n: number) => ((n - bounds[0]) / span) * 100;
  const commit = () => {
    setTouched(true);
    // The hidden fields only enable on the next render; submit after it.
    window.setTimeout(() => wrap.current?.closest('form')?.requestSubmit(), 0);
  };
  const fmt = (n: number) => '₪' + String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  const step = Math.max(1, Math.round(span / 200));
  const thumb = '[&::-webkit-slider-thumb]:pointer-events-auto [&::-webkit-slider-thumb]:size-[19px] [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:border-2 [&::-webkit-slider-thumb]:border-white [&::-webkit-slider-thumb]:bg-midblue [&::-webkit-slider-thumb]:shadow [&::-moz-range-thumb]:pointer-events-auto [&::-moz-range-thumb]:size-[15px] [&::-moz-range-thumb]:rounded-full [&::-moz-range-thumb]:border-2 [&::-moz-range-thumb]:border-white [&::-moz-range-thumb]:bg-midblue';
  const input = `pointer-events-none absolute inset-0 h-[19px] w-full appearance-none bg-transparent ${thumb}`;

  return (
    <div ref={wrap}>
      <p className="text-[13px] font-medium leading-4 text-[#3D3D3D]" dir="ltr" style={{ textAlign: 'start' }}>
        <bdi>{fmt(a)}</bdi> – <bdi>{fmt(b)}</bdi>
      </p>
      <div className="relative mt-3.5 h-[19px]">
        <span className="absolute inset-x-0 top-2 h-[3px] rounded-full bg-line" />
        <span className="absolute top-2 h-[3px] rounded-full bg-midblue" style={{ insetInlineStart: `${pct(a)}%`, width: `${pct(b) - pct(a)}%` }} />
        <input type="range" data-manual aria-label="min" min={bounds[0]} max={bounds[1]} step={step} value={lo}
          onChange={(e) => setLo(Math.min(+e.target.value, hi))} onPointerUp={commit} onKeyUp={commit} className={input} />
        <input type="range" data-manual aria-label="max" min={bounds[0]} max={bounds[1]} step={step} value={hi}
          onChange={(e) => setHi(Math.max(+e.target.value, lo))} onPointerUp={commit} onKeyUp={commit} className={input} />
      </div>
      <input type="hidden" name="min" value={Math.round(a)} disabled={!touched} />
      <input type="hidden" name="max" value={Math.round(b)} disabled={!touched} />
    </div>
  );
}
