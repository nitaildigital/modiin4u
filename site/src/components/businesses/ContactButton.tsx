'use client';
import { useState } from 'react';
import { Floating, useFloating } from '@/components/ui/Floating';
import { Call, Copy, Message, Sms } from 'iconsax-react';

/** Digits and a leading +, or null when there is no number. */
function telOf(raw: string | null | undefined): string | null {
  const s = (raw ?? '').replace(/[^\d+]/g, '');
  return s.length >= 7 ? s : null;
}

/** A number as wa.me wants it, Israel's code in place of the leading 0. */
function waOf(raw: string | null | undefined): string | null {
  let d = (raw ?? '').replace(/\D/g, '');
  if (d.startsWith('0')) d = '972' + d.slice(1);
  return d.length >= 9 ? d : null;
}

/** The website's Contact (web_contact_menu.dart): a small menu under the
 *  button with the number itself, copy, WhatsApp and e-mail — whichever the
 *  place has. Straight to `tel:` does nothing visible on most computers, and
 *  the visitor never sees the number. The menu is
 *  drawn over the page (Floating), so the card does not hide it. */
export function ContactButton({ phone, whatsapp, email, lang, className = '', children }: {
  phone: string | null; whatsapp?: string | null; email?: string | null; lang: 'he' | 'en';
  className?: string; children: React.ReactNode;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const { open, setOpen, anchor, menu } = useFloating();
  const [note, setNote] = useState<string | null>(null);

  const tel = telOf(phone);
  const wa = waOf(whatsapp);
  const mail = (email ?? '').trim();
  if (!tel && !wa && !mail) return null;
  const row = 'flex h-12 w-full items-center gap-3 px-4 text-[15px] font-medium text-navy hover:bg-section';

  const copy = async () => {
    setOpen(false);
    try {
      await navigator.clipboard.writeText(phone!.trim());
      setNote(t('המספר הועתק', 'Number copied'));
    } catch {
      // The clipboard exists only on a secure page; the number is shown.
      setNote(`${t('מספר', 'Number')}: ${phone!.trim()}`);
    }
    setTimeout(() => setNote(null), 2500);
  };

  return (
    <div ref={anchor} className="relative z-10 w-fit">
      <button type="button" className={className} aria-haspopup="menu" aria-expanded={open}
        onClick={(e) => { e.preventDefault(); e.stopPropagation(); setOpen((o) => !o); }}>
        {children}
      </button>
      <Floating open={open} anchor={anchor} menu={menu}>
        {tel && <a role="menuitem" href={`tel:${tel}`} className={row}><Call size={20} color="#123A72" /><span dir="ltr">{phone!.trim()}</span></a>}
        {tel && <button role="menuitem" type="button" onClick={copy} className={row}><Copy size={20} color="#123A72" />{t('העתקת המספר', 'Copy number')}</button>}
        {wa && <a role="menuitem" href={`https://wa.me/${wa}`} target="_blank" rel="noopener" className={row}><Message size={20} color="#123A72" />WhatsApp</a>}
        {mail && <a role="menuitem" href={`mailto:${mail}`} className={row}><Sms size={20} color="#123A72" /><span dir="ltr" className="truncate">{mail}</span></a>}
      </Floating>
      {note && <div role="status" className="fixed bottom-24 left-1/2 z-50 -translate-x-1/2 rounded-xl bg-ink px-5 py-3 text-sm text-white shadow-lg">{note}</div>}
    </div>
  );
}
