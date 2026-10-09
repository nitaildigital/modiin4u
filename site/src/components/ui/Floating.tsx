'use client';
import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

/** A menu's open state, its button's box and the menu's own: closes on a
 *  click outside both, on Escape, and when the page scrolls or resizes (the
 *  menu stays where it opened). The website's contact and share menus
 *  (web_contact_menu.dart, web_share_menu.dart). */
export function useFloating() {
  const [open, setOpen] = useState(false);
  const anchor = useRef<HTMLDivElement>(null);
  const menu = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const outside = (e: MouseEvent) => {
      const n = e.target as Node;
      if (!anchor.current?.contains(n) && !menu.current?.contains(n)) setOpen(false);
    };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    const away = (e: Event) => { if (!menu.current?.contains(e.target as Node)) setOpen(false); };
    const resize = () => setOpen(false);
    document.addEventListener('mousedown', outside);
    document.addEventListener('keydown', esc);
    window.addEventListener('scroll', away, true);
    window.addEventListener('resize', resize);
    return () => {
      document.removeEventListener('mousedown', outside);
      document.removeEventListener('keydown', esc);
      window.removeEventListener('scroll', away, true);
      window.removeEventListener('resize', resize);
    };
  }, [open]);
  return { open, setOpen, anchor, menu };
}

/** The menu itself, drawn over the page at its button rather than inside
 *  it: cards and rows clip what overflows them and the next one covers the
 *  rest, so a menu opened inside one was not seen (9 Oct). Under the button,
 *  or over it when there is no room below, as the current site does.
 *  [align] is which edge it lines up with — the button's start or end — and
 *  [match] makes it the button's width. */
export function Floating({ open, anchor, menu, align = 'start', match = false, width = 220, className = '', children }: {
  open: boolean; anchor: React.RefObject<HTMLDivElement | null>; menu: React.RefObject<HTMLDivElement | null>;
  align?: 'start' | 'end'; match?: boolean; width?: number; className?: string; children: React.ReactNode;
}) {
  const [at, setAt] = useState<React.CSSProperties | null>(null);
  const [dir, setDir] = useState<'rtl' | 'ltr'>('rtl');
  useLayoutEffect(() => {
    if (!open) { setAt(null); return; }
    const a = anchor.current;
    if (!a) return;
    const b = a.getBoundingClientRect();
    const rtl = getComputedStyle(a).direction === 'rtl';
    setDir(rtl ? 'rtl' : 'ltr');
    const w = match ? b.width : Math.max(width, menu.current?.offsetWidth ?? 0);
    const h = menu.current?.offsetHeight ?? 0;
    // The start edge is the right one in Hebrew.
    const fromRight = (align === 'start') === rtl;
    const left = fromRight ? b.right - w : b.left;
    const below = b.bottom + 8 + h <= window.innerHeight || b.top - 8 - h < 0;
    setAt({
      left: Math.max(8, Math.min(left, window.innerWidth - w - 8)),
      top: below ? b.bottom + 8 : b.top - 8 - h,
      width: match ? w : undefined,
      minWidth: match ? undefined : width,
    });
  }, [open, anchor, menu, align, match, width]);
  if (!open) return null;
  return createPortal(
    <div ref={menu} role="menu" dir={dir} style={at ?? { left: -9999, top: 0, minWidth: width }}
      className={`fixed z-[1200] overflow-hidden rounded-xl border border-line bg-white py-2 shadow-[0_6px_24px_rgba(0,0,0,0.16)] ${className}`}>
      {children}
    </div>,
    document.body,
  );
}
