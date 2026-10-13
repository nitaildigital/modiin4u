import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { storeLinks } from '@/lib/data/steps';
import { AppLanding } from '@/components/landing/AppLanding';

export async function generateMetadata(): Promise<Metadata> {
  // Reached only from ads (the client, 13 Oct): no link to it on the site,
  // and out of Google's results.
  return pageMetadata({ path: '/landing-page/', title: 'האפליקציה' + SUFFIX, noindex: true });
}

/** /landing-page/ — the app's landing page (Figma "App Landing Page"). Outside
 *  the (site) group: it has its own bar instead of the site's header. */
export default async function LandingPage() {
  const [lang, stores] = await Promise.all([getLang(), storeLinks()]);
  return <AppLanding lang={lang} ios={stores.ios} android={stores.android} />;
}
