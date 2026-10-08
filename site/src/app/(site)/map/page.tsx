import type { Metadata } from 'next';
import { getLang, tr, type Lang } from '@/lib/i18n';
import { pageMetadata, h1For, breadcrumb, href, SITE_NAME, SUFFIX } from '@/lib/seo';
import { SITE_URL } from '@/lib/config';
import { cityPins } from '@/lib/data/map';
import { JsonLd } from '@/components/JsonLd';
import { CityMap } from '@/components/citymap/CityMap';

const PATH = '/map/';
const heading = (lang: Lang) => tr(lang)('גלו את מודיעין', 'Explore Modiin');
const intro = (lang: Lang) => tr(lang)('גלו עסקים, אירועים ומקומות ברחבי העיר.', 'Discover businesses, events and place around the city.');

export async function generateMetadata(): Promise<Metadata> {
  const lang = await getLang();
  return pageMetadata({ path: PATH, title: heading(lang) + SUFFIX, description: intro(lang) });
}

/** The city map: every pin read here, on the server, and handed to the map
 *  in the browser — which draws them, switches the layers and opens the
 *  chosen pin's card. */
export default async function MapPage() {
  const lang = await getLang();
  const pins = await cityPins(lang);
  return (
    <>
      <JsonLd data={[
        { '@context': 'https://schema.org', '@type': 'WebPage', name: heading(lang), description: intro(lang), url: SITE_URL + href(PATH), inLanguage: lang },
        breadcrumb([[SITE_NAME, '/'], [heading(lang), PATH]]),
      ]} />
      <CityMap pins={pins} lang={lang} title={h1For(PATH, heading(lang))} intro={intro(lang)} />
    </>
  );
}
