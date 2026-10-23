'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import type { Lang } from '@/lib/i18n';
import { onOpenConsentSettings, openConsentSettings, saveConsent, useConsent, type Consent } from '@/lib/consent';

/** The cookie notice (lib/consent.ts): on a first visit, and again from the
 *  footer's "Cookie settings". "Accept all" and "Essential only" are offered
 *  side by side, and the settings name each group and the tools in it, none
 *  ticked in advance. On a phone it sits above the bottom menu. */
export function CookieConsent({ lang }: { lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const consent = useConsent();
  const [open, setOpen] = useState(false);
  const [details, setDetails] = useState(false);
  const [choice, setChoice] = useState<Consent>({ analytics: false, marketing: false });

  useEffect(() => onOpenConsentSettings(() => {
    setChoice(consent ?? { analytics: false, marketing: false });
    setDetails(true);
    setOpen(true);
  }), [consent]);

  // Not before the page knows the choice; asked when there is none.
  const showing = consent !== undefined && (consent === null || open);
  if (!showing) return null;

  const done = (next: Consent) => {
    saveConsent(next);
    setOpen(false);
    setDetails(false);
  };

  const groups: { key: keyof Consent | 'essential'; title: string; text: string }[] = [
    {
      key: 'essential',
      title: t('הכרחיות', 'Essential'),
      text: t('נדרשות כדי שהאתר יעבוד: שפה, התחברות להודעות, התראות שהפעלתם, המפה וזכירת הבחירה הזו.',
        'Needed for the site to work: language, sign-in for Messages, notifications you turned on, the map, and remembering this choice.'),
    },
    {
      key: 'analytics',
      title: t('ניתוח וסטטיסטיקה', 'Analytics'),
      text: t('עוזרות לנו להבין איך משתמשים באתר ולשפר אותו: Google Analytics, Microsoft Clarity ו-Hotjar, וסטטיסטיקת צפיות לעסקים.',
        'Help us understand how the site is used and improve it: Google Analytics, Microsoft Clarity and Hotjar, and view statistics for businesses.'),
    },
    {
      key: 'marketing',
      title: t('שיווק', 'Marketing'),
      text: t('מאפשרות למדוד את הפרסום שלנו ברשתות החברתיות: Meta Pixel (פייסבוק ואינסטגרם).',
        'Let us measure our advertising on social networks: the Meta Pixel (Facebook and Instagram).'),
    },
  ];

  return (
    <div role="dialog" aria-modal="false" aria-labelledby="cookie-title" dir={lang === 'he' ? 'rtl' : 'ltr'}
      className="fixed inset-x-3 bottom-[88px] z-50 mx-auto max-w-[560px] rounded-2xl border border-line bg-white p-5 text-ink shadow-[0_8px_30px_rgba(0,0,0,0.18)] desk:inset-x-auto desk:bottom-6 desk:end-6 desk:mx-0">
      <h2 id="cookie-title" className="text-lg font-semibold">{t('עוגיות באתר', 'Cookies on this site')}</h2>
      <p className="mt-2 text-sm leading-relaxed text-gray-text">
        {t('אנחנו משתמשים בעוגיות הכרחיות כדי שהאתר יעבוד. בהסכמתכם נשתמש גם בעוגיות לניתוח השימוש באתר ולשיווק. אפשר לשנות את הבחירה בכל עת ב„הגדרות עוגיות” בתחתית האתר. ',
          'We use essential cookies to make the site work. With your consent we also use cookies for analytics and marketing. You can change your choice at any time under “Cookie settings” at the foot of the site. ')}
        <Link href="/privacy/" className="font-medium text-midblue underline">{t('מדיניות הפרטיות', 'Privacy Policy')}</Link>
      </p>

      {details && (
        <ul className="mt-4 flex flex-col gap-3">
          {groups.map((g) => {
            const fixed = g.key === 'essential';
            const on = fixed ? true : choice[g.key as keyof Consent];
            return (
              <li key={g.key} className="rounded-xl bg-section p-3">
                <label className={`flex items-start gap-3 ${fixed ? '' : 'cursor-pointer'}`}>
                  <input type="checkbox" checked={on} disabled={fixed}
                    onChange={(e) => !fixed && setChoice({ ...choice, [g.key]: e.target.checked })}
                    className="mt-1 size-4 shrink-0 accent-midblue" />
                  <span>
                    <span className="block text-sm font-semibold">{g.title}{fixed && <span className="font-normal text-gray-meta"> · {t('תמיד פעילות', 'Always on')}</span>}</span>
                    <span className="mt-0.5 block text-xs leading-relaxed text-gray-text">{g.text}</span>
                  </span>
                </label>
              </li>
            );
          })}
        </ul>
      )}

      <div className="mt-4 flex flex-wrap gap-2">
        {/* The two choices weigh the same: refusing is as easy as agreeing. */}
        <button type="button" onClick={() => done({ analytics: true, marketing: true })}
          className="h-11 flex-1 rounded-full bg-midblue px-5 text-sm font-medium text-white hover:bg-midblue/90">
          {t('אישור הכל', 'Accept all')}
        </button>
        <button type="button" onClick={() => done({ analytics: false, marketing: false })}
          className="h-11 flex-1 rounded-full border border-midblue px-5 text-sm font-medium text-midblue hover:bg-midblue/5">
          {t('הכרחיות בלבד', 'Essential only')}
        </button>
        {details ? (
          <button type="button" onClick={() => done(choice)}
            className="h-11 w-full rounded-full border border-line px-5 text-sm font-medium text-ink hover:bg-section">
            {t('שמירת הבחירה', 'Save my choice')}
          </button>
        ) : (
          <button type="button" onClick={() => { setChoice(consent ?? { analytics: false, marketing: false }); setDetails(true); }}
            className="h-11 w-full text-sm font-medium text-midblue underline">
            {t('הגדרות', 'Settings')}
          </button>
        )}
      </div>
    </div>
  );
}

/** "Cookie settings" in the footer. */
export function CookieSettingsLink({ label, className = '' }: { label: string; className?: string }) {
  return (
    <button type="button" className={className} onClick={openConsentSettings}>
      {label}
    </button>
  );
}
