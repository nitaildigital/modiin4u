'use client';
import { useCallback, useEffect, useState } from 'react';
import { isUnread, openedIds, permission, pushFeed, PUSH_EVENT, seenAt, type PushItem } from '@/lib/push';

/** The bell's state: the feed, what is unread in it, and this browser's
 *  answer to "allow notifications?". Follows every change made elsewhere on
 *  the page (a "Turn on", an opened notification). */
export function usePush() {
  const [items, setItems] = useState<PushItem[] | null>(null);
  const [seen, setSeen] = useState<number | null>(null);
  const [opened, setOpened] = useState<Set<string>>(new Set());
  const [allowed, setAllowed] = useState<ReturnType<typeof permission> | null>(null);
  const [failed, setFailed] = useState(false);

  const load = useCallback(async () => {
    setSeen(seenAt());
    setOpened(openedIds());
    setAllowed(permission());
    try {
      setItems(await pushFeed());
      setFailed(false);
    } catch {
      setFailed(true);
    }
  }, []);

  useEffect(() => {
    void load();
    const again = () => void load();
    window.addEventListener(PUSH_EVENT, again);
    return () => window.removeEventListener(PUSH_EVENT, again);
  }, [load]);

  const unread = items && seen != null ? items.filter((i) => isUnread(i, seen, opened)).length : 0;
  return { items, seen, opened, allowed, unread, failed, reload: load };
}
