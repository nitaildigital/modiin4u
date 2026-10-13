'use client';
import { useEffect, useState } from 'react';
import { Gps } from 'iconsax-react';
import { canLocate, locate, savedPosition } from '@/lib/near';

/** "Near me" beside a "near you" heading: asks for the position once, after
 *  which the rows below sort by distance. Absent where the browser cannot
 *  give a position (plain http). */
export function NearButton({ label, done }: { label: string; done: string }) {
  const [state, setState] = useState<'hidden' | 'idle' | 'busy' | 'on' | 'refused'>('hidden');
  useEffect(() => { setState(!canLocate() ? 'hidden' : savedPosition() ? 'on' : 'idle'); }, []);
  if (state === 'hidden') return null;
  return (
    <button type="button" disabled={state === 'busy' || state === 'on'}
      onClick={() => { setState('busy'); locate().then(() => setState('on'), () => setState('refused')); }}
      className={`flex items-center gap-1 rounded-full border px-2.5 py-1 text-[11px] font-medium ${state === 'on' ? 'border-midblue/20 bg-midblue/[0.06] text-midblue' : 'border-line text-midblue'}`}>
      <Gps size={13} color="currentColor" />
      {state === 'on' ? done : label}
    </button>
  );
}
