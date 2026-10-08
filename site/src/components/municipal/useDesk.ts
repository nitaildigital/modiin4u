'use client';
import { useEffect, useState } from 'react';

/** Whether the window is the desktop layout's (1100 px and wider), once the
 *  page is in the browser; null before. A map is drawn once, in the layout
 *  on screen, rather than twice with one hidden. */
export function useDesk(): boolean | null {
  const [desk, setDesk] = useState<boolean | null>(null);
  useEffect(() => {
    const q = window.matchMedia('(min-width: 1100px)');
    const update = () => setDesk(q.matches);
    update();
    q.addEventListener('change', update);
    return () => q.removeEventListener('change', update);
  }, []);
  return desk;
}
