'use client';
import { useEffect, useState } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';

/** A thin bar along the top from the moment a link to another page of the
 *  site is tapped until that page is on screen. Next.js keeps the old page
 *  up while it fetches the new one, which on a phone took two to ten
 *  seconds with nothing to show the tap had registered — the client read
 *  the bottom menu as broken (14 Oct). */
export function NavProgress() {
  const path = usePathname();
  const search = useSearchParams()?.toString();
  const [state, setState] = useState<'idle' | 'busy' | 'done'>('idle');

  // The page changed: the bar fills and fades.
  useEffect(() => { setState((s) => (s === 'busy' ? 'done' : s)); }, [path, search]);
  useEffect(() => {
    if (state === 'idle') return;
    // Done fades after a moment; busy gives up after 20 s (a failed load
    // must not leave the bar there for good).
    const t = setTimeout(() => setState('idle'), state === 'done' ? 300 : 20000);
    return () => clearTimeout(t);
  }, [state]);

  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      const a = (e.target as Element | null)?.closest?.('a');
      if (!a || !a.href || a.hasAttribute('download') || (a.target && a.target !== '_self')) return;
      const url = new URL(a.href, location.href);
      if (url.origin !== location.origin) return;
      if (url.pathname === location.pathname && url.search === location.search) return;
      setState('busy');
    };
    document.addEventListener('click', onClick, true);
    return () => document.removeEventListener('click', onClick, true);
  }, []);

  if (state === 'idle') return null;
  return (
    <div aria-hidden className="pointer-events-none fixed inset-x-0 top-0 z-[1000] h-[3px]">
      <div className="h-full bg-midblue transition-[width,opacity] duration-200"
        style={state === 'busy'
          ? { animation: 'nav-progress 8s cubic-bezier(.1,.7,.3,1) forwards' }
          : { width: '100%', opacity: 0 }} />
    </div>
  );
}
