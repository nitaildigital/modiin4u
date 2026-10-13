import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { storeLinks } from '@/lib/data/steps';
import { AppLanding } from '@/components/landing/AppLanding';
import { LandingPixel } from '@/components/landing/LandingPixel';

export async function generateMetadata(): Promise<Metadata> {
  // Reached only from ads (the client, 13 Oct): no link to it on the site,
  // and out of Google's results.
  // What a shared link shows (Instagram, WhatsApp, the ads): the hero's
  // headline and phones, 1200 × 630, made from the page's own images.
  return pageMetadata({
    path: '/landing-page/',
    title: 'האפליקציה' + SUFFIX,
    description: 'עסקים מקומיים, מסעדות, אירועים, חדשות, דירות, משרות, מבצעים ושירותי העירייה — הכול באפליקציה אחת, שנבנתה בשביל מודיעין.',
    ogTitle: 'כל מודיעין, במקום אחד — האפליקציה של מודיעין בשבילך',
    image: '/web/app-landing/og_landing.jpg',
    noindex: true,
  });
}

/** /landing-page/ — the app's landing page (Figma "App Landing Page"). Outside
 *  the (site) group: it has its own bar instead of the site's header. */
export default async function LandingPage() {
  const [lang, stores] = await Promise.all([getLang(), storeLinks()]);
  return (
    <>
      <AppLanding lang={lang} ios={stores.ios} android={stores.android} />
      <LandingPixel />
    </>
  );
}
