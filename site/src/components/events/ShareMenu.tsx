'use client';
import { useEffect, useRef, useState, type ReactNode } from 'react';

/** The website's Share (web_share_menu.dart): a small menu under the button —
 *  WhatsApp, Facebook, X, e-mail and Copy link. Each is an ordinary link, so
 *  all of them work on any page; the browser's own share sheet exists only
 *  on some. [message] is what goes before the link: the title, a date, a
 *  place. Events and deals both use it. */
export function ShareMenu({ url, title, message, lang, className, children, align = 'start' }: {
  url: string; title: string; message?: string; lang: 'he' | 'en';
  className: string; children: ReactNode; align?: 'start' | 'end';
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const close = (ev: MouseEvent) => { if (!box.current?.contains(ev.target as Node)) setOpen(false); };
    const esc = (ev: KeyboardEvent) => { if (ev.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', close);
    document.addEventListener('keydown', esc);
    return () => { document.removeEventListener('mousedown', close); document.removeEventListener('keydown', esc); };
  }, [open]);

  const text = encodeURIComponent([message || title, url].join('\n'));
  const items: [string, string, string][] = [
    ['WhatsApp', `https://wa.me/?text=${text}`, '/web/news/share_whatsapp.svg'],
    ['Facebook', `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`, '/web/news/share_facebook.svg'],
    ['X', `https://twitter.com/intent/tweet?text=${text}`, '/web/news/share_x.svg'],
    [t('דוא"ל', 'Email'), `mailto:?subject=${encodeURIComponent(title)}&body=${text}`, '/web/news/share_mail.svg'],
  ];

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => { setCopied(false); setOpen(false); }, 1200);
    } catch {
      // The clipboard exists only on a secure page; the address bar still has it.
      setOpen(false);
    }
  };

  return (
    <div ref={box} className="relative">
      <button type="button" onClick={() => setOpen((o) => !o)} aria-expanded={open} aria-haspopup="menu" className={className}>
        {children}
      </button>
      {open && (
        <div role="menu" className={`absolute top-[calc(100%+8px)] z-[1100] min-w-[190px] rounded-xl border border-line bg-white py-1.5 text-start shadow-[0_8px_24px_rgba(0,0,0,0.12)] ${align === 'end' ? 'end-0' : 'start-0'}`}>
          {items.map(([name, link, icon]) => (
            <a key={name} role="menuitem" href={link} target={link.startsWith('mailto:') ? '_self' : '_blank'} rel="noopener"
              onClick={() => setOpen(false)} className="flex items-center gap-3 px-4 py-2.5 text-sm text-ink hover:bg-surface">
              <img src={icon} alt="" className="size-5 object-contain" />{name}
            </a>
          ))}
          <div className="my-1 border-t border-line" />
          <button type="button" role="menuitem" onClick={copy} className="flex w-full items-center gap-3 px-4 py-2.5 text-start text-sm text-ink hover:bg-surface">
            {copied ? t('הקישור הועתק', 'Link copied') : t('העתקת קישור', 'Copy link')}
          </button>
        </div>
      )}
    </div>
  );
}
