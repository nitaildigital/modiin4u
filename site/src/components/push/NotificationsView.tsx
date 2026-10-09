'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, ArrowRight, Notification } from 'iconsax-react';
import { isUnread, markSeen, recordOpen, turnOnPush, type PushItem } from '@/lib/push';
import { usePush } from './usePush';

/** The notifications page (web_notifications_screen.dart): "Turn on" while
 *  this browser has not allowed them, then what was sent — to this browser,
 *  or to everyone before it has a token — the unread ones tinted. Opening
 *  the page marks everything seen, as opening the bell does. */
export function NotificationsView({ lang }: { lang: 'he' | 'en' }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const { items, opened, allowed, failed, reload } = usePush();
  // What was unread when the page opened stays tinted while it is read.
  const [seenBefore, setSeenBefore] = useState<number | null>(null);
  const [asking, setAsking] = useState(false);
  const marked = useRef(false);
  useEffect(() => {
    if (marked.current) return;
    marked.current = true;
    try {
      const raw = localStorage.getItem('flutter.push_seen_at');
      setSeenBefore(raw ? Date.parse(JSON.parse(raw)) : Date.now());
    } catch { setSeenBefore(Date.now()); }
    markSeen();
  }, []);

  const Back = lang === 'he' ? ArrowRight : ArrowLeft;
  const text = (i: PushItem) => ({
    title: lang === 'en' && i.title_en?.trim() ? i.title_en : i.title,
    body: lang === 'en' && i.body_en?.trim() ? i.body_en : i.body,
  });
  const when = (iso: string) => {
    const d = new Date(iso);
    const today = d.toDateString() === new Date().toDateString();
    return d.toLocaleString(lang === 'he' ? 'he-IL' : 'en-GB', today
      ? { hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Jerusalem' }
      : { day: 'numeric', month: 'numeric', year: 'numeric', timeZone: 'Asia/Jerusalem' });
  };

  const turnOn = async () => {
    setAsking(true);
    await turnOnPush(lang);
    setAsking(false);
    void reload();
  };

  return (
    <div className="wrap">
      <div className="mx-auto max-w-[720px] pb-20 pt-6 desk:pt-14">
        <Link href="/" className="hidden items-center gap-2 text-sm font-medium text-midblue desk:inline-flex">
          <Back size={20} color="currentColor" />{t('חזרה', 'Back')}
        </Link>
        <h1 className="font-nunito text-2xl font-semibold text-[#1C1C1E] desk:mt-6 desk:text-[32px]">{t('התראות', 'Notifications')}</h1>

        {allowed !== null && allowed !== 'granted' && (
          <div className="mt-4 flex items-center gap-3 rounded-xl bg-turquoise/10 py-3 pe-2 ps-4">
            <Notification size={24} color="#17A9D0" />
            <p className="min-w-0 flex-1 text-sm">
              {allowed === 'unsupported'
                ? t('הדפדפן הזה לא מקבל התראות. באייפון: הוסיפו את האתר למסך הבית, או הורידו את האפליקציה.', 'This browser cannot receive notifications. On an iPhone, add the site to your home screen, or get the app.')
                : allowed === 'denied'
                  ? t('ההתראות חסומות בדפדפן הזה. אפשר להתיר אותן בהגדרות האתר שליד שורת הכתובת.', 'Notifications are blocked in this browser. You can allow them in the site settings beside the address bar.')
                  : t('קבלו התראה בדפדפן הזה כשמתפרסם משהו חדש.', 'Get a notification in this browser when something new is published.')}
            </p>
            {allowed === 'default' && (
              <button type="button" onClick={turnOn} disabled={asking}
                className="shrink-0 rounded-full px-4 py-2 text-sm font-medium text-turquoise hover:bg-turquoise/10 disabled:opacity-60">
                {t('הפעלה', 'Turn on')}
              </button>
            )}
          </div>
        )}

        <div className="mt-4">
          {items === null ? (
            failed ? (
              <div className="flex flex-col items-center py-16 text-center">
                <p className="text-sm text-gray-text">{t('לא ניתן לטעון את ההתראות.', 'The notifications could not be loaded.')}</p>
                <button type="button" onClick={() => void reload()} className="mt-3 rounded-full border border-midblue px-5 py-2 text-sm font-medium text-midblue">{t('נסו שוב', 'Try again')}</button>
              </div>
            ) : <div className="h-40 animate-pulse rounded-xl bg-surface" />
          ) : items.length === 0 ? (
            <div className="flex flex-col items-center py-16 text-center">
              <span className="flex size-16 items-center justify-center rounded-full bg-surface"><Notification size={28} color="#6D6D6D" /></span>
              <p className="mt-4 font-nunito text-lg font-semibold text-[#1C1C1E]">{t('אין התראות', 'No notifications')}</p>
              <p className="mt-2 text-sm text-gray-text">{t('כשיהיו עדכונים עבורכם, הם יופיעו כאן.', 'When there are updates for you, they will appear here.')}</p>
            </div>
          ) : (
            <ul className="overflow-hidden rounded-xl border border-line">
              {items.map((i) => {
                const { title, body } = text(i);
                const unread = seenBefore != null && isUnread(i, seenBefore, opened);
                const inner = (
                  <span className="flex gap-3 p-4">
                    {i.image_url
                      ? <img src={i.image_url} alt="" loading="lazy" className="size-14 shrink-0 rounded-lg object-cover" />
                      : <span className="flex size-14 shrink-0 items-center justify-center rounded-lg bg-surface"><Notification size={22} color="#123A72" /></span>}
                    <span className="min-w-0 flex-1">
                      <span className="flex items-start justify-between gap-3">
                        <span dir="auto" className={`text-[15px] text-[#1C1C1E] ${unread ? 'font-semibold' : 'font-medium'}`}>{title}</span>
                        <span className="shrink-0 text-xs text-gray-meta">{when(i.sent_at)}</span>
                      </span>
                      {body && <span dir="auto" className="mt-1 block whitespace-pre-line text-sm text-gray-text">{body}</span>}
                    </span>
                  </span>
                );
                const cls = `block border-b border-line last:border-b-0 ${unread ? 'bg-turquoise/5' : 'bg-white'} hover:bg-surface`;
                const link = i.deep_link?.trim();
                return (
                  <li key={i.id}>
                    {link
                      ? <a href={link} target={link.startsWith('/') ? undefined : '_blank'} rel="noopener" onClick={() => recordOpen(i.id)} className={cls}>{inner}</a>
                      : <div className={cls}>{inner}</div>}
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
