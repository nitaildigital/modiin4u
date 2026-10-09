'use client';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import type { Lang } from '@/lib/i18n';
import { sessionDb, useSession } from '@/lib/session';

/** Writes to a business (Messages, 00069): finds the conversation between
 *  this person and the business, or opens it, and shows it. Signed out, it
 *  goes to sign-in first and comes back here. Not drawn for the business's
 *  own owner. */
export function MessageBusiness({ lang, businessId, ownerId, className, children }: {
  lang: Lang; businessId: string; ownerId: string; className?: string; children: React.ReactNode;
}) {
  const router = useRouter();
  const { session } = useSession();
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState(false);
  if (session?.user.id === ownerId) return null;

  async function open() {
    if (!session) {
      router.push(`/signin/?next=${encodeURIComponent(window.location.pathname)}`);
      return;
    }
    setBusy(true);
    setFailed(false);
    const { data, error } = await sessionDb().rpc('start_conversation', { p_business: businessId });
    setBusy(false);
    if (error || typeof data !== 'string') return setFailed(true);
    router.push(`/messages/${data}/`);
  }

  return (
    <>
      <button type="button" onClick={open} disabled={busy} className={className}
        aria-label={lang === 'he' ? 'שליחת הודעה לעסק' : 'Message the business'}>
        {children}
      </button>
      {failed && (
        <span role="alert" className="text-xs text-[#C0392B]">
          {lang === 'he' ? 'לא ניתן היה לפתוח את השיחה.' : 'The conversation could not be opened.'}
        </span>
      )}
    </>
  );
}
