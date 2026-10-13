import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { AppOnly } from '@/components/jobs/AppOnly';

const TITLE: [string, string] = ['המשרות של העסק', "My business's jobs"];

export async function generateMetadata(): Promise<Metadata> {
  // A page of the app's, for the notifications that lead here.
  return pageMetadata({ path: '/business-jobs/', title: TITLE[0] + SUFFIX, noindex: true });
}

/** /business-jobs/… — a business's jobs and who applied are kept in the
 *  app; a "new applicant" notification opened in a browser lands here
 *  rather than on "not found". */
export default async function Page() {
  return <AppOnly lang={await getLang()} title={TITLE} body={['המשרות שהעסק שלכם פרסם, והמועמדים להן, נמצאים באפליקציה.', 'The jobs your business posted, and who applied, are in the app.']} />;
}
