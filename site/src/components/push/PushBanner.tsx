'use client';
import { useEffect, useState } from 'react';
import { CloseCircle, Notification } from 'iconsax-react';
import { PUSH_FOREGROUND, recordOpen, type ForegroundPush } from '@/lib/push';

/** The banner for a notification that arrives while the site is open in
 *  front (push_host.dart's in-app banner): its title and line for eight
 *  seconds; a click opens it, counted as opened. */
export function PushBanner({ lang }: { lang: 'he' | 'en' }) {
  const [msg, setMsg] = useState<ForegroundPush | null>(null);
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    const show = (e: Event) => {
      setMsg((e as CustomEvent<ForegroundPush>).detail);
      clearTimeout(timer);
      timer = setTimeout(() => setMsg(null), 8000);
    };
    window.addEventListener(PUSH_FOREGROUND, show);
    return () => { window.removeEventListener(PUSH_FOREGROUND, show); clearTimeout(timer); };
  }, []);
  if (!msg) return null;
  const open = () => {
    if (msg.campaignId) recordOpen(msg.campaignId);
    setMsg(null);
    const link = msg.link?.trim();
    if (!link) return;
    if (link.startsWith('/')) window.location.href = link;
    else window.open(link, '_blank', 'noopener');
  };
  return (
    <div role="status" className="fixed inset-x-3 top-3 z-[1300] mx-auto flex max-w-[460px] items-start gap-3 rounded-2xl border border-line bg-white p-4 shadow-[0_12px_32px_rgba(0,0,0,0.18)] desk:end-6 desk:start-auto desk:top-24 desk:mx-0">
      <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-turquoise/10"><Notification size={20} color="#17A9D0" /></span>
      <button type="button" onClick={open} className="min-w-0 flex-1 text-start">
        <span dir="auto" className="block text-[15px] font-semibold text-[#1C1C1E]">{msg.title}</span>
        {msg.body && <span dir="auto" className="mt-0.5 block text-sm text-gray-text">{msg.body}</span>}
      </button>
      <button type="button" onClick={() => setMsg(null)} aria-label={lang === 'he' ? 'סגירה' : 'Close'}><CloseCircle size={22} color="#6D6D6D" /></button>
    </div>
  );
}
