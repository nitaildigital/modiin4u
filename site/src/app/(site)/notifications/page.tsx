import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { NotificationsView } from '@/components/push/NotificationsView';

export async function generateMetadata(): Promise<Metadata> {
  // Each browser's own list: nothing here for a search engine.
  return pageMetadata({ path: '/notifications/', title: 'התראות' + SUFFIX, noindex: true });
}

/** /notifications/ — where a visitor turns web push on and reads what was
 *  sent (the header's bell, the footer's "Get notifications"). */
export default async function NotificationsPage() {
  return <NotificationsView lang={await getLang()} />;
}
