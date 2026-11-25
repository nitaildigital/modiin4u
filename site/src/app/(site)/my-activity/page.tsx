import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { MyActivityView } from '@/components/activity/MyActivityView';

export async function generateMetadata(): Promise<Metadata> {
  const t = tr(await getLang());
  // Someone's own writing: never for a search engine.
  return pageMetadata({ path: '/my-activity/', title: t('הפעילות שלי', 'My activity') + SUFFIX, noindex: true });
}

/** /my-activity/ — the app's My activity: the signed-in resident's reviews
 *  and comments and what came of them (25 Nov). */
export default async function MyActivityPage() {
  return <MyActivityView lang={await getLang()} />;
}
