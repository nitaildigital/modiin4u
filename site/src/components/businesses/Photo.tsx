'use client';
import { useEffect, useRef, useState } from 'react';
import { Image as ImageIcon } from 'iconsax-react';

export const BRAND_BG = 'bg-[linear-gradient(to_bottom_right,#0058B5,#010A36)]';

/** Iconsax's shop mark (Linear), as a mask: a list draws it on every card
 *  without a photograph, and one rule in the page costs less than a copy of
 *  the drawing in each. */
const SHOP_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M3.01 11.22v4.49C3.01 20.2 4.81 22 9.3 22h5.39c4.49 0 6.29-1.8 6.29-6.29v-4.49"/><path d="M12 12c1.83 0 3.18-1.49 3-3.32L14.34 2H9.67L9 8.68C8.82 10.51 10.17 12 12 12Z"/><path d="M18.31 12c2.02 0 3.5-1.64 3.3-3.65l-.28-2.75C20.97 3 19.97 2 17.35 2H14.3l.7 7.01c.17 1.65 1.66 2.99 3.31 2.99ZM5.64 12c1.65 0 3.14-1.34 3.3-2.99l.22-2.21.48-4.8H6.59C3.97 2 2.97 3 2.61 5.6l-.27 2.75C2.14 10.36 3.62 12 5.64 12ZM12 17c-1.67 0-2.5.83-2.5 2.5V22h5v-2.5c0-1.67-.83-2.5-2.5-2.5Z"/></svg>`;
const SHOP_CSS = `.biz-shop{background:currentColor;-webkit-mask:url("data:image/svg+xml,${encodeURIComponent(SHOP_SVG)}") center/contain no-repeat;mask:url("data:image/svg+xml,${encodeURIComponent(SHOP_SVG)}") center/contain no-repeat}`;

/** The rule behind `.biz-shop`; React keeps one copy in the page's head. */
export function ShopMarkStyle() {
  return <style href="biz-shop" precedence="default">{SHOP_CSS}</style>;
}

/** A listing's photograph over the brand gradient (NetworkPhoto): the
 *  gradient, with the shop mark, is what shows while the photo loads, where
 *  there is none — 90 of the businesses have no cover — and where it fails.
 *  [bg] (classes) or [style] replace the gradient, [glyph] the mark. */
export function Photo({ src, alt, className = '', bg = BRAND_BG, style, icon = 40, glyph = 'shop', iconClass = 'text-white/30' }: {
  src: string | null; alt: string; className?: string; bg?: string; style?: React.CSSProperties;
  icon?: number; glyph?: 'shop' | 'image' | null; iconClass?: string;
}) {
  // Once the photo is in, the stand-in goes: a logo with a transparent
  // ground sits on white, as the app draws it, not on the gradient.
  const img = useRef<HTMLImageElement>(null);
  const [loaded, setLoaded] = useState(false);
  useEffect(() => { if (img.current?.complete && img.current.naturalWidth > 0) setLoaded(true); }, [src]);
  return (
    <div className={`relative overflow-hidden ${loaded ? 'bg-white' : style ? '' : bg} ${className}`} style={loaded ? undefined : style}>
      {!loaded && glyph === 'shop' && <><ShopMarkStyle /><span className={`biz-shop absolute inset-0 m-auto ${iconClass}`} style={{ width: icon, height: icon }} /></>}
      {!loaded && glyph === 'image' && <ImageIcon size={icon} color="currentColor" className={`absolute inset-0 m-auto ${iconClass}`} />}
      {src && (
        <img ref={img} src={src} alt={alt} loading="lazy" decoding="async"
          className="absolute inset-0 size-full object-cover"
          onLoad={() => setLoaded(true)}
          onError={(e) => { (e.currentTarget as HTMLImageElement).style.display = 'none'; }} />
      )}
    </div>
  );
}
