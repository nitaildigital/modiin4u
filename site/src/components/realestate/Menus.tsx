'use client';
import { useEffect, useRef, useState } from 'react';
import { Call, Copy, Message, Sms, TickCircle } from 'iconsax-react';

/** A menu that opens under its button and closes on a click elsewhere or
 *  Escape — the website's contact and share menus (web_contact_menu.dart,
 *  web_share_menu.dart). */
function usePopover() {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const away = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) setOpen(false); };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', away);
    document.addEventListener('keydown', esc);
    return () => { document.removeEventListener('mousedown', away); document.removeEventListener('keydown', esc); };
  }, [open]);
  return { open, setOpen, ref };
}

export type ContactOption = { kind: 'phone' | 'copy' | 'whatsapp' | 'email'; label: string; href: string; done?: string };

const ICONS = { phone: Call, copy: Copy, whatsapp: Message, email: Sms };

/** "Contact": the number itself (to read off, or call from a device that
 *  can), copy the number, WhatsApp, and e-mail — whichever there is. With a
 *  single way to reach them, [direct] opens it straight away, as the phone
 *  layout does. */
export function ContactMenu({ options, label, className, icon, direct = false, menuClass = '' }: {
  options: ContactOption[]; label: string; className: string; icon?: React.ReactNode; direct?: boolean; menuClass?: string;
}) {
  const { open, setOpen, ref } = usePopover();
  const [copied, setCopied] = useState(false);
  if (!options.length) return null;
  if (direct && options.length === 1) {
    return <a href={options[0].href} target={options[0].kind === 'whatsapp' ? '_blank' : undefined} rel="noopener" className={className}>{icon}{label}</a>;
  }
  const row = 'flex h-12 w-full items-center gap-3 whitespace-nowrap px-4 text-start text-[15px] font-medium text-navy hover:bg-section';
  return (
    <div ref={ref} className="relative">
      <button type="button" aria-expanded={open} onClick={() => setOpen(!open)} className={className}>{icon}{label}</button>
      {open && (
        <div role="menu" className={`absolute end-0 z-30 mt-2 min-w-[220px] overflow-hidden rounded-xl border border-line bg-white py-2 shadow-[0_6px_24px_rgba(0,0,0,0.16)] ${menuClass}`}>
          {options.map((o) => {
            const Icon = o.kind === 'copy' && copied ? TickCircle : ICONS[o.kind];
            const body = (
              <>
                <Icon size={20} color={o.kind === 'copy' && copied ? '#2ECC71' : '#123A72'} />
                <span dir={o.kind === 'phone' || o.kind === 'email' ? 'ltr' : undefined}>{o.kind === 'copy' && copied ? o.done : o.label}</span>
              </>
            );
            return o.kind === 'copy' ? (
              <button key="copy" type="button" role="menuitem" className={row}
                onClick={async () => { try { await navigator.clipboard.writeText(o.href); setCopied(true); setTimeout(() => setCopied(false), 1800); } catch { /* the number is on screen above */ } }}>
                {body}
              </button>
            ) : (
              <a key={o.href} role="menuitem" href={o.href} target={o.kind === 'whatsapp' ? '_blank' : undefined} rel="noopener" className={row}>{body}</a>
            );
          })}
        </div>
      )}
    </div>
  );
}

/** Share this page: Facebook, WhatsApp, X, e-mail, or copy the address. A
 *  phone's own share sheet where the browser has one. */
export function ShareMenu({ url, title, label, className, icon, lang, menuClass = '' }: {
  url: string; title: string; label?: string; className: string; icon?: React.ReactNode; lang: 'he' | 'en'; menuClass?: string;
}) {
  const { open, setOpen, ref } = usePopover();
  const [copied, setCopied] = useState(false);
  const u = encodeURIComponent(url);
  const t = encodeURIComponent(title);
  const links: [string, string, string][] = [
    ['WhatsApp', `https://wa.me/?text=${t}%20${u}`, '/web/news/share_whatsapp.svg'],
    ['Facebook', `https://www.facebook.com/sharer/sharer.php?u=${u}`, '/web/news/share_facebook.svg'],
    ['X', `https://twitter.com/intent/tweet?url=${u}&text=${t}`, '/web/news/share_x.svg'],
    [lang === 'he' ? 'דוא״ל' : 'Email', `mailto:?subject=${t}&body=${u}`, '/web/news/share_mail.svg'],
  ];
  const click = async () => {
    const nav = navigator as Navigator & { share?: (d: ShareData) => Promise<void> };
    if (nav.share && window.matchMedia('(max-width: 1099px)').matches) {
      try { await nav.share({ title, url }); return; } catch { /* closed, or refused: the menu instead */ }
    }
    setOpen(!open);
  };
  return (
    <div ref={ref} className="relative">
      <button type="button" aria-expanded={open} aria-label={label ? undefined : (lang === 'he' ? 'שיתוף' : 'Share')} onClick={click} className={className}>
        {icon}{label}
      </button>
      {open && (
        <div role="menu" className={`absolute z-30 mt-2 min-w-[220px] overflow-hidden rounded-xl bg-white py-2 shadow-[0_6px_24px_rgba(0,0,0,0.16)] ${menuClass}`}>
          {links.map(([name, href, icon]) => (
            <a key={name} role="menuitem" href={href} target="_blank" rel="noopener"
              className="flex h-12 items-center gap-3 px-4 text-[15px] font-medium text-navy hover:bg-section">
              <img src={icon} alt="" width={22} height={22} className="size-[22px] object-contain" />{name}
            </a>
          ))}
          <button type="button" role="menuitem"
            onClick={async () => { try { await navigator.clipboard.writeText(url); setCopied(true); setTimeout(() => setCopied(false), 1800); } catch { /* no clipboard */ } }}
            className="flex h-12 w-full items-center gap-3 px-4 text-start text-[15px] font-medium text-navy hover:bg-section">
            {copied ? <TickCircle size={22} color="#2ECC71" /> : <Copy size={22} color="#123A72" />}
            {copied ? (lang === 'he' ? 'הקישור הועתק' : 'Link copied') : (lang === 'he' ? 'העתקת קישור' : 'Copy link')}
          </button>
        </div>
      )}
    </div>
  );
}
