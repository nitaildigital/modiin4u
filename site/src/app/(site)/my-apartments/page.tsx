import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { AppOnly } from '@/components/jobs/AppOnly';

const TITLE: [string, string] = ['הדירות שלי', 'My apartments'];

export async function generateMetadata(): Promise<Metadata> {
  // A page of the app's, for the notifications that lead here.
  return pageMetadata({ path: '/my-apartments/', title: TITLE[0] + SUFFIX, noindex: true });
}

/** /my-apartments/ — A resident's own listings is kept in the app; a notification about it opened in a
 *  browser lands here rather than on "not found". */
export default async function Page() {
  return <AppOnly lang={await getLang()} title={TITLE} body={['המודעות שפרסמתם, ומה שקרה איתן, נמצאות באפליקציה.', 'The listings you posted, and what happened to them, are in the app.']} />;
}
