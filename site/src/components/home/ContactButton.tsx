'use client';
import { useState } from 'react';
import { Floating, useFloating } from '@/components/ui/Floating';
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

/** Contact / Call Now (web_contact_menu.dart): a small menu by the button,
 *  over the page (Floating), with the number itself, copying it, WhatsApp
 *  and e-mail — whichever the place has. A bare `tel:` does nothing visible on most computers, and the
 *  visitor would never see the number. */
export function ContactButton({ phone, whatsapp, email, label, lang, wide = false }: {
  phone: string | null; whatsapp: string | null; email: string | null; label: string; lang: 'he' | 'en'; wide?: boolean;
}) {
  const { open, setOpen, anchor, menu } = useFloating();
  const [copied, setCopied] = useState<string | null>(null);
  const t = (he: string, en: string) => (lang === 'he' ? he : en);

  const tel = telOf(phone);
  const wa = waOf(whatsapp);
  const mail = (email ?? '').trim();
  if (!tel && !wa && !mail) return null;

  const copy = async () => {
    setOpen(false);
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
    <div ref={anchor} className={`relative ${wide ? 'w-full' : 'w-fit'}`} onClick={(e) => e.stopPropagation()}>
      <button type="button" onClick={(e) => { e.preventDefault(); setOpen((o) => !o); }} aria-expanded={open}
        className={`group/contact flex items-center justify-center gap-2 rounded-[60px] border border-midblue py-2 text-sm font-medium leading-6 text-midblue hover:bg-midblue hover:text-white group-hover/card:bg-midblue group-hover/card:text-white ${wide ? 'w-full' : 'px-4'}`}>
        {/* Outlined, and filled under the pointer — over the card or the button. */}
        <img src="/web/home/card_phone.svg" alt="" width={16} height={16} className="size-4 group-hover/card:hidden group-hover/contact:hidden" />
        <img src="/web/home/card_phone_white.svg" alt="" width={16} height={16} className="hidden size-4 group-hover/card:block group-hover/contact:block" />
        {label}
      </button>
      <Floating open={open} anchor={anchor} menu={menu}>
          {tel && <a role="menuitem" href={`tel:${tel}`} className={row}><Call size={20} color="#123A72" /><span dir="ltr">{phone!.trim()}</span></a>}
          {tel && <button role="menuitem" type="button" onClick={copy} className={row}><Copy size={20} color="#123A72" />{t('העתקת המספר', 'Copy number')}</button>}
          {wa && <a role="menuitem" href={`https://wa.me/${wa}`} target="_blank" rel="noopener" className={row}><Message size={20} color="#123A72" />WhatsApp</a>}
          {mail && <a role="menuitem" href={`mailto:${mail}`} className={row}><Sms size={20} color="#123A72" /><span dir="ltr" className="truncate">{mail}</span></a>}
      </Floating>
      {copied && <p role="status" className="fixed bottom-24 left-1/2 z-50 -translate-x-1/2 whitespace-nowrap rounded-xl bg-ink px-5 py-3 text-sm text-white shadow-lg">{copied}</p>}
    </div>
  );
}
