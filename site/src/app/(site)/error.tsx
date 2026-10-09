'use client';
import { useEffect, useState } from 'react';

/** A page under the header bar whose data could not be read (the database
 *  slow or down): said in the reader's language, with "Try again", instead
 *  of Next's English "Application error". The status is 500, so a search
 *  engine keeps the page it knew and comes back. */
export default function SiteError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  const [he, setHe] = useState(true);
  useEffect(() => { setHe(document.documentElement.lang !== 'en'); }, []);
  const t = (a: string, b: string) => (he ? a : b);
  return (
    <div className="wrap flex flex-col items-center py-24 text-center desk:py-36">
      <p className="font-nunito text-[22px] font-semibold text-navy desk:text-[28px]">{t('הדף לא זמין כרגע', 'This page is not available right now')}</p>
      <p className="mt-3 max-w-[460px] text-sm leading-[1.5] text-gray-text desk:text-base">{t('לא הצלחנו לטעון את המידע. נסו שוב בעוד רגע.', 'We could not load its information. Please try again in a moment.')}</p>
      <button type="button" onClick={reset} className="mt-7 flex h-12 items-center rounded-full bg-midblue px-7 text-base font-medium text-white hover:bg-midblue/90">
        {t('נסו שוב', 'Try again')}
      </button>
    </div>
  );
}
