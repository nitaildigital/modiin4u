'use client';
import { useEffect, useRef, useState } from 'react';
import { HambergerMenu, CloseCircle } from 'iconsax-react';

/** The landing page's links on a phone, where the bar has no room for them:
 *  a button that opens them under the bar, and closes on a choice, a tap
 *  elsewhere or Escape. */
export function LandingMenu({ links, label }: { links: [string, string][]; label: string }) {
  const [open, setOpen] = useState(false);
  const box = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const away = (e: PointerEvent) => { if (!box.current?.contains(e.target as Node)) setOpen(false); };
    const key = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('pointerdown', away);
    document.addEventListener('keydown', key);
    return () => { document.removeEventListener('pointerdown', away); document.removeEventListener('keydown', key); };
  }, [open]);
  return (
    <div ref={box} className="desk:hidden">
      <button type="button" aria-label={label} aria-expanded={open} onClick={() => setOpen(!open)}
        className="flex size-10 items-center justify-center rounded-full text-midblue">
        {open ? <CloseCircle size={26} color="currentColor" /> : <HambergerMenu size={26} color="currentColor" />}
      </button>
      {open && (
        <nav aria-label={label} className="absolute inset-x-4 top-[72px] z-50 rounded-2xl border border-line bg-white p-2 shadow-[0_8px_24px_rgba(0,0,0,0.08)]">
          {links.map(([text, href]) => (
            <a key={href} href={href} onClick={() => setOpen(false)}
              className="block rounded-xl px-4 py-3 text-base font-medium text-[#3D3D3D] hover:bg-[#F6F6F6]">{text}</a>
          ))}
        </nav>
      )}
    </div>
  );
}
