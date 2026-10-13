import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { storeLinks } from '@/lib/data/steps';
import { AppLanding } from '@/components/landing/AppLanding';

export async function generateMetadata(): Promise<Metadata> {
  // Out of Google until the client says where the page lives and whether
  // search should show it; the address may change with his answer.
  return pageMetadata({ path: '/app/', title: 'האפליקציה' + SUFFIX, noindex: true });
}

/** /app/ — the app's landing page (Figma "App Landing Page"). Outside the
 *  (site) group: it has its own bar instead of the site's header. */
export default async function AppPage() {
  const [lang, stores] = await Promise.all([getLang(), storeLinks()]);
  return <AppLanding lang={lang} ios={stores.ios} android={stores.android} />;
}
