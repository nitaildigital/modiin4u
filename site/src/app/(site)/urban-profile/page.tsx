import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { UrbanSteps } from '@/components/urban/UrbanSteps';

export async function generateMetadata(): Promise<Metadata> {
  // A resident's own page, behind sign-in: never in search.
  return pageMetadata({ path: '/urban-profile/', title: 'הפרופיל העירוני שלי' + SUFFIX, noindex: true });
}

/** /urban-profile/ — "Complete your Urban Profile": on to the first step
 *  still missing something, or the finished profile. */
export default async function UrbanProfileStart() {
  return <UrbanSteps lang={await getLang()} step="start" />;
}
