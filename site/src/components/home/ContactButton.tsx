'use client';
import { useEffect, useRef, useState } from 'react';
import { Call, Copy, Message, Sms } from 'iconsax-react';

/** Digits and a leading +, or null when there is no number. */
const telOf = (raw: string | null) => {
  const s = (raw ?? '').replace(/[^\d+]/g, '');
  return s.length >= 7 ? s : null;
};

/** A number as wa.me wants it: Israel's code for the leading nought. */
const waOf = (raw: string | null) => {
  let d = (raw ?? '').replace(/\D/g, '');
  if (d.startsWith('0')) d = '972' + d.slice(1);
  return d.length >= 9 ? d : null;
};

/** Contact / Call Now (web_contact_menu.dart): a small menu under the button
 *  with the number itself, copying it, WhatsApp and e-mail — whichever the
 *  place has. A bare `tel:` does nothing visible on most computers, and the
 *  visitor would never see the number. */
export function ContactButton({ phone, whatsapp, email, label, lang, wide = false }: {
  phone: string | null; whatsapp: string | null; email: string | null; label: string; lang: 'he' | 'en'; wide?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState<string | null>(null);
  const box = useRef<HTMLDivElement>(null);
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  useEffect(() => {
    if (!open) return;
    const away = (e: MouseEvent) => { if (!box.current?.contains(e.target as Node)) setOpen(false); };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', away);
    document.addEventListener('keydown', esc);
    return () => { document.removeEventListener('mousedown', away); document.removeEventListener('keydown', esc); };
  }, [open]);

  const tel = telOf(phone);
  const wa = waOf(whatsapp);
  const mail = (email ?? '').trim();
  if (!tel && !wa && !mail) return null;

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(phone!.trim());
      setCopied(t('המספר הועתק', 'Number copied'));
    } catch {
      // The clipboard exists only on a secure page; the number is on screen.
      setCopied(`${t('מספר', 'Number')}: ${phone!.trim()}`);
    }
    setTimeout(() => setCopied(null), 2500);
  };

  const row = 'flex h-12 w-full items-center gap-3 px-4 text-[15px] font-medium text-navy hover:bg-section';
  return (
    <div ref={box} className={`relative ${wide ? 'w-full' : 'w-fit'}`} onClick={(e) => e.stopPropagation()}>
      <button type="button" onClick={(e) => { e.preventDefault(); setOpen((o) => !o); }} aria-expanded={open}
        className={`group/contact flex items-center justify-center gap-2 rounded-[60px] border border-midblue py-2 text-sm font-medium leading-6 text-midblue hover:bg-midblue hover:text-white group-hover/card:bg-midblue group-hover/card:text-white ${wide ? 'w-full' : 'px-4'}`}>
        {/* Outlined, and filled under the pointer — over the card or the button. */}
        <img src="/web/home/card_phone.svg" alt="" width={16} height={16} className="size-4 group-hover/card:hidden group-hover/contact:hidden" />
        <img src="/web/home/card_phone_white.svg" alt="" width={16} height={16} className="hidden size-4 group-hover/card:block group-hover/contact:block" />
        {label}
      </button>
      {open && (
        <div role="menu" className="absolute start-0 top-full z-30 mt-2 w-[220px] overflow-hidden rounded-xl border border-line bg-white py-2 shadow-lg">
          {tel && <a role="menuitem" href={`tel:${tel}`} className={row}><Call size={20} color="#123A72" /><span dir="ltr">{phone!.trim()}</span></a>}
          {tel && <button role="menuitem" type="button" onClick={copy} className={row}><Copy size={20} color="#123A72" />{t('העתקת המספר', 'Copy number')}</button>}
          {wa && <a role="menuitem" href={`https://wa.me/${wa}`} target="_blank" rel="noopener" className={row}><Message size={20} color="#123A72" />WhatsApp</a>}
          {mail && <a role="menuitem" href={`mailto:${mail}`} className={row}><Sms size={20} color="#123A72" /><span dir="ltr" className="truncate">{mail}</span></a>}
        </div>
      )}
      {copied && <p role="status" className="absolute start-0 top-full z-30 mt-2 whitespace-nowrap rounded-lg bg-ink px-3 py-2 text-xs text-white">{copied}</p>}
    </div>
  );
}
