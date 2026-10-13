import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { AppOnly } from '@/components/jobs/AppOnly';

const TITLE: [string, string] = ['האירועים של העסק', "My business's events"];

export async function generateMetadata(): Promise<Metadata> {
  // A page of the app's, for the notifications that lead here.
  return pageMetadata({ path: '/business-events/', title: TITLE[0] + SUFFIX, noindex: true });
}

/** /business-events/ — A business's own events is kept in the app; a notification about it opened in a
 *  browser lands here rather than on "not found". */
export default async function Page() {
  return <AppOnly lang={await getLang()} title={TITLE} body={['האירועים שהעסק שלכם פרסם, ומה שקרה איתם, נמצאים באפליקציה.', 'The events your business posted, and what happened to them, are in the app.']} />;
}
