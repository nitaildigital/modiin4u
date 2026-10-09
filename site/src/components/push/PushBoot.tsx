'use client';
import { useEffect } from 'react';
import { recordOpen, refreshPush } from '@/lib/push';

/** On every page: a browser that allowed notifications refreshes its token
 *  and row (nothing is asked), and the address a notification opened —
 *  `?push=<campaign>` — counts as that notification opened. */
export function PushBoot({ lang }: { lang: 'he' | 'en' }) {
  useEffect(() => {
    void refreshPush(lang);
    const campaign = new URLSearchParams(window.location.search).get('push');
    if (campaign && /^[0-9a-f-]{36}$/i.test(campaign)) recordOpen(campaign);
  }, [lang]);
  return null;
}
