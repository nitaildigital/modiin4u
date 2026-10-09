'use client';
import { useState } from 'react';
import { Floating, useFloating } from '@/components/ui/Floating';

/** Where a menu sits against its button: under its start or end edge, or
 *  its full width. */
type Place = 'start' | 'end' | 'match';
import { Call, Copy, Message, Sms, TickCircle } from 'iconsax-react';

export type ContactOption = { kind: 'phone' | 'copy' | 'whatsapp' | 'email'; label: string; href: string; done?: string };

const ICONS = { phone: Call, copy: Copy, whatsapp: Message, email: Sms };

/** "Contact": the number itself (to read off, or call from a device that
 *  can), copy the number, WhatsApp, and e-mail — whichever there is. With a
 *  single way to reach them, [direct] opens it straight away, as the phone
 *  layout does. */
export function ContactMenu({ options, label, className, icon, direct = false, place = 'end' }: {
  options: ContactOption[]; label: string; className: string; icon?: React.ReactNode; direct?: boolean; place?: Place;
}) {
  const { open, setOpen, anchor, menu } = useFloating();
  const [copied, setCopied] = useState(false);
  if (!options.length) return null;
  if (direct && options.length === 1) {
    return <a href={options[0].href} target={options[0].kind === 'whatsapp' ? '_blank' : undefined} rel="noopener" className={className}>{icon}{label}</a>;
  }
  const row = 'flex h-12 w-full items-center gap-3 whitespace-nowrap px-4 text-start text-[15px] font-medium text-navy hover:bg-section';
  return (
    <div ref={anchor} className="relative">
      <button type="button" aria-expanded={open} aria-haspopup="menu" onClick={() => setOpen(!open)} className={className}>{icon}{label}</button>
      <Floating open={open} anchor={anchor} menu={menu} align={place === 'start' ? 'start' : 'end'} match={place === 'match'}>
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
      </Floating>
    </div>
  );
}

/** Share this page: Facebook, WhatsApp, X, e-mail, or copy the address. A
 *  phone's own share sheet where the browser has one. */
export function ShareMenu({ url, title, label, className, icon, lang, place = 'start' }: {
  url: string; title: string; label?: string; className: string; icon?: React.ReactNode; lang: 'he' | 'en'; place?: Place;
}) {
  const { open, setOpen, anchor, menu } = useFloating();
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
    <div ref={anchor} className="relative">
      <button type="button" aria-expanded={open} aria-haspopup="menu" aria-label={label ? undefined : (lang === 'he' ? 'שיתוף' : 'Share')} onClick={click} className={className}>
        {icon}{label}
      </button>
      <Floating open={open} anchor={anchor} menu={menu} align={place === 'end' ? 'end' : 'start'} match={place === 'match'}>
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
      </Floating>
    </div>
  );
}
