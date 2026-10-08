import type { Metadata } from 'next';
import { Header } from '@/components/chrome/Header';
import { JsonLd } from '@/components/JsonLd';
import { HomeContent } from '@/components/home/HomeContent';
import { SITE_URL } from '@/lib/config';
import { pageMetadata, h1For, organization, SITE_JSON, SITE_NAME } from '@/lib/seo';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({ path: '/', title: SITE_JSON.home.title, description: SITE_JSON.home.description });
}

/** The home page (web_home_screen.dart on a desktop, home_screen.dart on a
 *  phone), under the white pill that floats over the hero. */
export default function Home() {
  return (
    <>
      <JsonLd data={[
        { '@context': 'https://schema.org', '@type': 'WebSite', name: SITE_NAME, alternateName: 'Modiin4u', url: SITE_URL + '/' },
        { '@context': 'https://schema.org', ...organization() },
      ]} />
      <Header floating />
      <main>
        <HomeContent h1={h1For('/', SITE_JSON.home.title)} />
      </main>
    </>
  );
}
