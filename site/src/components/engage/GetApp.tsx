'use client';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { Mobile } from 'iconsax-react';

/** Liking, replying and writing are the app's (accounts are the app's). On
 *  the website the same buttons are there, and each opens this: what it is,
 *  that it is done in the app, and the stores (the client, 25 Nov: show the
 *  comments and the way to answer, and send people to the app). */

type Ctx = { open: () => void };
const GetAppContext = createContext<Ctx>({ open: () => {} });

export function GetAppProvider({ he, ios, android, children }: {
  he: boolean; ios: string | null; android: string | null; children: ReactNode;
}) {
  const [shown, setShown] = useState(false);
  const t = (h: string, e: string) => (he ? h : e);
  useEffect(() => {
    if (!shown) return;
    const key = (e: KeyboardEvent) => { if (e.key === 'Escape') setShown(false); };
    document.addEventListener('keydown', key);
    return () => document.removeEventListener('keydown', key);
  }, [shown]);
  const badge = (link: string | null, src: string, alt: string) => {
    const img = <img src={`/web/app-landing/${src}`} alt={alt} width={179} height={56} className="block h-11 w-auto" />;
    return link ? <a href={link} target="_blank" rel="noopener">{img}</a> : <span>{img}</span>;
  };
  return (
    <GetAppContext.Provider value={{ open: () => setShown(true) }}>
      {children}
      {shown && (
        <div role="dialog" aria-modal="true" className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-5"
          onClick={() => setShown(false)}>
          <div dir={he ? 'rtl' : 'ltr'} onClick={(e) => e.stopPropagation()}
            className="relative w-full max-w-[420px] rounded-[20px] bg-white px-6 pb-8 pt-10 text-center shadow-xl">
            <button type="button" aria-label={t('סגירה', 'Close')} onClick={() => setShown(false)}
              className="absolute end-4 top-3 text-2xl leading-none text-[#6D6D6D]">×</button>
            <span className="mx-auto flex size-16 items-center justify-center rounded-full bg-midblue/[0.08]"><Mobile size={30} color="#123A72" /></span>
            <p className="mt-5 font-nunito text-xl font-semibold text-navy">{t('הצטרפו לשיחה באפליקציה', 'Join the conversation in the app')}</p>
            <p className="mt-2 text-sm leading-[1.6] text-gray-text">
              {t('לייקים, תגובות וביקורות נעשים באפליקציית מודיעין בשבילך. הורידו אותה בחינם:',
                'Likes, replies and reviews happen in the Modiin4U app. Get it free:')}
            </p>
            <div dir="ltr" className="mt-6 flex flex-wrap justify-center gap-3">
              {badge(ios, 'badge_app_store.svg', 'Download on the App Store')}
              {badge(android, 'badge_google_play.svg', 'Get it on Google Play')}
            </div>
          </div>
        </div>
      )}
    </GetAppContext.Provider>
  );
}

/** A button that, on the website, opens the app prompt. */
export function AppAction({ children, className, label }: { children: ReactNode; className?: string; label?: string }) {
  const { open } = useContext(GetAppContext);
  return <button type="button" aria-label={label} onClick={open} className={className}>{children}</button>;
}
