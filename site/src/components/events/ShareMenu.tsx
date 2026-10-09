'use client';
import { useState, type ReactNode } from 'react';
import { Floating, useFloating } from '@/components/ui/Floating';

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
  const { open, setOpen, anchor, menu } = useFloating();
  const [copied, setCopied] = useState(false);

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
    <div ref={anchor} className="relative">
      <button type="button" onClick={() => setOpen((o) => !o)} aria-expanded={open} aria-haspopup="menu" className={className}>
        {children}
      </button>
      <Floating open={open} anchor={anchor} menu={menu} align={align} width={190} className="!py-1.5 text-start">
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
      </Floating>
    </div>
  );
}
