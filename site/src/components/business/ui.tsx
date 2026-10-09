'use client';
import { createContext, useCallback, useContext, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { ArrowLeft, Call, Copy, Gallery, Link2 } from 'iconsax-react';
import { track, type BusinessStat } from './stats';
import { FacebookMark, MailMark, WhatsAppMark, XMark } from './icons';
import { sized } from './format';
import { Floating, useFloating } from '@/components/ui/Floating';

type UI = {
  businessId: string;
  photos: string[];
  openPhotos: (index: number) => void;
  tab: number;
  setTab: (tab: number) => void;
  toast: (text: string) => void;
};

const Ctx = createContext<UI | null>(null);
const useUI = () => useContext(Ctx)!;

/** What the page's interactive parts share: the photo viewer, the phone
 *  layout's tab, a short message at the bottom. Records the view once
 *  (BusinessStats.record(view) in initState). */
export function BusinessUI({ businessId, photos, children }: { businessId: string; photos: string[]; children: React.ReactNode }) {
  const [viewer, setViewer] = useState<number | null>(null);
  const [tab, setTab] = useState(0);
  const [message, setMessage] = useState<string | null>(null);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => { track(businessId, 'view'); }, [businessId]);

  const toast = useCallback((text: string) => {
    setMessage(text);
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(() => setMessage(null), 3500);
  }, []);

  return (
    <Ctx.Provider value={{ businessId, photos, openPhotos: setViewer, tab, setTab, toast }}>
      {children}
      {viewer != null && photos.length > 0 && <PhotoViewer photos={photos} start={viewer} onClose={() => setViewer(null)} />}
      {message && (
        <div role="status" className="fixed inset-x-0 bottom-24 z-[60] flex justify-center px-4 desk:bottom-8">
          <p className="max-w-[90vw] break-all rounded-xl bg-[#323232] px-5 py-3.5 text-sm text-white shadow-lg">{message}</p>
        </div>
      )}
    </Ctx.Provider>
  );
}

/** A link that counts its click for the business's statistics. */
export function TrackedLink({ stat, href, className, children, label, newTab = true }: {
  stat: BusinessStat; href: string; className?: string; children: React.ReactNode; label?: string; newTab?: boolean;
}) {
  const { businessId } = useUI();
  return (
    <a href={href} className={className} aria-label={label} onClick={() => track(businessId, stat)}
      {...(newTab ? { target: '_blank', rel: 'noopener' } : {})}>
      {children}
    </a>
  );
}

/** Back, where the reader came from — the directory when they arrived here
 *  directly (AppNavigation.back with its fallback). */
export function BackButton({ fallback, label }: { fallback: string; label: string }) {
  return (
    <button type="button" aria-label={label}
      onClick={() => { if (window.history.length > 1 && document.referrer.startsWith(location.origin)) history.back(); else location.href = fallback; }}
      className="flex size-10 items-center justify-center rounded-full bg-white text-[#3D3D3D]">
      <ArrowLeft size={20} color="currentColor" className="rtl:-scale-x-100" />
    </button>
  );
}

/** "Show all photos" on the cover: the viewer on a desktop, the Photos tab
 *  on a phone (as each layout does). */
export function ShowAllPhotos({ label, phone = false }: { label: string; phone?: boolean }) {
  const { openPhotos, setTab } = useUI();
  if (phone) {
    return (
      <button type="button" onClick={() => setTab(2)}
        className="flex items-center gap-2 rounded-full bg-black/50 px-2 py-1.5 text-xs font-medium text-white">
        <Gallery size={14} color="currentColor" />{label}
      </button>
    );
  }
  return (
    <button type="button" onClick={() => openPhotos(0)}
      className="flex items-center gap-2 rounded-full bg-white/90 px-4 py-1.5 text-sm font-medium leading-6 text-navy">
      <img src="/web/business/gallery.svg" alt="" width={14} height={14} />{label}
    </button>
  );
}

/** A photograph that opens the viewer at itself. */
export function PhotoThumb({ index, width, className = '' }: { index: number; width: number; className?: string }) {
  const { photos, openPhotos } = useUI();
  return (
    <button type="button" onClick={() => openPhotos(index)} className={`block shrink-0 overflow-hidden bg-section ${className}`}>
      <img src={sized(photos[index], width)} alt="" loading="lazy" className="size-full object-cover" />
    </button>
  );
}

/** The desktop gallery: a row of photographs, with arrows only where there
 *  is further to go. */
export function GalleryStrip() {
  const { photos } = useUI();
  const row = useRef<HTMLDivElement>(null);
  const [overflow, setOverflow] = useState(false);
  useLayoutEffect(() => {
    const el = row.current;
    if (!el) return;
    const check = () => setOverflow(el.scrollWidth > el.clientWidth + 1);
    check();
    const ro = new ResizeObserver(check);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  const scroll = (forward: boolean) => {
    const el = row.current;
    if (!el) return;
    const rtl = getComputedStyle(el).direction === 'rtl';
    el.scrollBy({ left: (forward ? 1 : -1) * (rtl ? -1 : 1) * 222 * 3, behavior: 'smooth' });
  };
  const arrow = (forward: boolean) => (
    <button type="button" onClick={() => scroll(forward)} aria-label={forward ? 'next' : 'previous'}
      className={`absolute top-[81px] z-10 flex size-10 items-center justify-center rounded-full border border-[#F6F6F6] bg-white shadow-[0_1px_5px_rgba(0,0,0,0.1)] ${forward ? '-end-5' : '-start-5'}`}>
      <img src="/web/business/carousel_arrow.svg" alt="" width={20} height={20} className={forward ? 'rtl:-scale-x-100' : 'ltr:-scale-x-100'} />
    </button>
  );
  return (
    <div className="relative">
      <div ref={row} className="flex gap-[22px] overflow-x-auto [scrollbar-width:none]">
        {photos.map((_, i) => <PhotoThumb key={i} index={i} width={200} className="h-[202px] w-[200px] rounded-lg" />)}
      </div>
      {overflow && <>{arrow(false)}{arrow(true)}</>}
    </div>
  );
}

/** The photographs one at a time over the page, with arrows for a mouse and
 *  a swipe for a finger (the current site's PageView); pinching zooms the
 *  page as the browser does. */
function PhotoViewer({ photos, start, onClose }: { photos: string[]; start: number; onClose: () => void }) {
  const [at, setAt] = useState(start);
  const touch = useRef<{ x: number; y: number } | null>(null);
  const swipe = (e: React.TouchEvent) => {
    const from = touch.current;
    touch.current = null;
    const end = e.changedTouches[0];
    if (!from || !end) return;
    const dx = end.clientX - from.x;
    // A sideways stroke of 50 px or more, not a scroll or a tap.
    if (Math.abs(dx) < 50 || Math.abs(dx) < Math.abs(end.clientY - from.y)) return;
    // The viewer is laid out left to right: a stroke to the left shows the next.
    setAt((i) => (dx < 0 ? Math.min(photos.length - 1, i + 1) : Math.max(0, i - 1)));
  };
  useEffect(() => {
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowLeft') setAt((i) => Math.max(0, i - 1));
      if (e.key === 'ArrowRight') setAt((i) => Math.min(photos.length - 1, i + 1));
    };
    window.addEventListener('keydown', key);
    const overflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { window.removeEventListener('keydown', key); document.body.style.overflow = overflow; };
  }, [photos.length, onClose]);
  const nav = 'absolute top-1/2 -translate-y-1/2 flex size-14 items-center justify-center text-5xl leading-none text-white';
  return (
    <div dir="ltr" role="dialog" aria-modal className="fixed inset-0 z-[70] bg-black/90" onClick={onClose}
      onTouchStart={(e) => { const p = e.touches[0]; touch.current = e.touches.length === 1 && p ? { x: p.clientX, y: p.clientY } : null; }}
      onTouchEnd={swipe}>
      <div className="flex size-full items-center justify-center px-4 py-16 desk:px-24" onClick={(e) => e.stopPropagation()}>
        <img src={photos[at]} alt="" className="max-h-full max-w-full object-contain" />
      </div>
      <button type="button" aria-label="Close" onClick={onClose} className="absolute right-6 top-6 text-4xl leading-none text-white">×</button>
      {at > 0 && <button type="button" aria-label="Previous" onClick={(e) => { e.stopPropagation(); setAt(at - 1); }} className={`${nav} left-3 desk:left-6`}>‹</button>}
      {at < photos.length - 1 && <button type="button" aria-label="Next" onClick={(e) => { e.stopPropagation(); setAt(at + 1); }} className={`${nav} right-3 desk:right-6`}>›</button>}
      <p className="absolute inset-x-0 bottom-6 text-center text-sm text-white">{at + 1} / {photos.length}</p>
    </div>
  );
}

/** The phone layout's tabs: the panels are drawn on the server, all in the
 *  page; this only shows the chosen one. */
export function PhoneTabs({ tabs }: { tabs: { label: string; index: number; content: React.ReactNode }[] }) {
  const { tab, setTab } = useUI();
  return (
    <>
      <div role="tablist" className="flex h-12 border-b border-line">
        {tabs.map((t) => {
          const on = t.index === tab;
          return (
            <button key={t.index} type="button" role="tab" aria-selected={on} onClick={() => setTab(t.index)}
              className={`flex-1 border-b-2 px-1 text-[13px] leading-tight ${on ? 'border-midblue font-semibold text-midblue' : 'border-transparent text-[#454545]'}`}>
              {t.label}
            </button>
          );
        })}
      </div>
      {tabs.map((t) => <div key={t.index} role="tabpanel" hidden={t.index !== tab}>{t.content}</div>)}
    </>
  );
}

/** Text clamped to four lines, with "See more" only when something is
 *  hidden behind it. */
export function ExpandableText({ text, more, less, className = '' }: { text: string; more: string; less: string; className?: string }) {
  const ref = useRef<HTMLParagraphElement>(null);
  const [open, setOpen] = useState(false);
  const [clipped, setClipped] = useState(false);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el || open) return;
    const check = () => setClipped(el.scrollHeight > el.clientHeight + 1);
    check();
    const ro = new ResizeObserver(check);
    ro.observe(el);
    return () => ro.disconnect();
  }, [open]);
  return (
    <div>
      <p ref={ref} className={`whitespace-pre-line ${open ? '' : 'line-clamp-4'} ${className}`}>{text}</p>
      {(clipped || open) && (
        <button type="button" onClick={() => setOpen(!open)} className="pt-1.5 text-sm font-medium text-midblue">
          {open ? less : more}
        </button>
      )}
    </div>
  );
}

/** A small menu under its button, closed by a click elsewhere or Escape. */
function Popover({ button, children, className = '' }: { button: (toggle: () => void) => React.ReactNode; children: (close: () => void) => React.ReactNode; className?: string }) {
  // Over the page (Floating): above the row when there is no room below.
  const { open, setOpen, anchor, menu } = useFloating();
  return (
    <div ref={anchor} className={`relative ${className}`}>
      {button(() => setOpen((o) => !o))}
      <Floating open={open} anchor={anchor} menu={menu}>{children(() => setOpen(false))}</Floating>
    </div>
  );
}

const itemCls = 'flex h-11 w-full items-center gap-3 px-4 text-start text-sm font-medium text-navy hover:bg-section';

async function copy(text: string): Promise<boolean> {
  try { await navigator.clipboard.writeText(text); return true; } catch { return false; }
}

/** The More Info card's Call row: the number, and on a tap the choice to
 *  dial or copy it — `tel:` alone does nothing visible on most computers
 *  (showWebContactMenu). */
export function CallMenu({ phone, children, he }: { phone: string; children: React.ReactNode; he: boolean }) {
  const { businessId, toast } = useUI();
  const t = (h: string, e: string) => (he ? h : e);
  const tel = phone.replace(/[^\d+]/g, '');
  return (
    <Popover button={(toggle) => (
      <button type="button" className="block w-full text-start" onClick={() => { track(businessId, 'call'); toggle(); }}>{children}</button>
    )}>
      {(close) => (
        <>
          <a href={`tel:${tel}`} className={itemCls} onClick={close}>
            <Call size={20} color="#123A72" /><span dir="ltr">{phone}</span>
          </a>
          <button type="button" className={itemCls} onClick={async () => {
            close();
            toast((await copy(phone)) ? t('המספר הועתק', 'Number copied') : `${t('מספר', 'Number')}: ${phone}`);
          }}>
            <Copy size={20} color="#123A72" />{t('העתקת המספר', 'Copy number')}
          </button>
        </>
      )}
    </Popover>
  );
}

/** Share this page: WhatsApp, Facebook, X, e-mail, or copy the link
 *  (showWebShareMenu). A phone's own share sheet where the browser has one. */
export function ShareMenu({ title, he, children, nativeFirst = false, className }: {
  title: string; he: boolean; children: React.ReactNode; nativeFirst?: boolean; className?: string;
}) {
  const { businessId, toast } = useUI();
  const t = (h: string, e: string) => (he ? h : e);
  const link = () => window.location.href;
  const open = (url: string, self = false) => window.open(url, self ? '_self' : '_blank', 'noopener');
  return (
    <Popover className={className} button={(toggle) => (
      <button type="button" aria-label={t('שיתוף', 'Share')} className="block w-full text-start" onClick={async () => {
        track(businessId, 'share');
        if (nativeFirst && typeof navigator.share === 'function') {
          try { await navigator.share({ title, url: link() }); return; } catch { return; }
        }
        toggle();
      }}>{children}</button>
    )}>
      {(close) => {
        const text = () => encodeURIComponent(`${title}\n${link()}`);
        return (
          <>
            <button type="button" className={itemCls} onClick={() => { close(); open(`https://wa.me/?text=${text()}`); }}><span className="flex w-[22px] justify-center"><WhatsAppMark size={22} /></span>WhatsApp</button>
            <button type="button" className={itemCls} onClick={() => { close(); open(`https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(link())}`); }}><span className="flex w-[22px] justify-center"><FacebookMark size={20} /></span>Facebook</button>
            <button type="button" className={itemCls} onClick={() => { close(); open(`https://twitter.com/intent/tweet?text=${text()}`); }}><span className="flex w-[22px] justify-center"><XMark size={22} /></span>X</button>
            <button type="button" className={itemCls} onClick={() => { close(); open(`mailto:?subject=${encodeURIComponent(title)}&body=${text()}`, true); }}><span className="flex w-[22px] justify-center"><MailMark size={22} /></span>{t('דוא"ל', 'Email')}</button>
            <div className="my-1 border-t border-line" />
            <button type="button" className={itemCls} onClick={async () => {
              close();
              toast((await copy(link())) ? t('הקישור הועתק', 'Link copied') : link());
            }}><Link2 size={22} color="#123A72" />{t('העתקת קישור', 'Copy link')}</button>
          </>
        );
      }}
    </Popover>
  );
}
