import type { Metadata } from 'next';
import { JsonLd } from '@/components/JsonLd';
import { HomeContent } from '@/components/home/HomeContent';
import { breadcrumb, h1For, pageMetadata, SITE_JSON, SITE_NAME, wpPage } from '@/lib/seo';

const PATH = '/personal-area/';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({ path: PATH });
}

/** WordPress's "personal area". Accounts are the app's, so the address shows
 *  what the home page shows, under its own title and heading. */
export default function PersonalArea() {
  const name = (wpPage(PATH)?.title ?? '').split(' - ')[0] || SITE_NAME;
  return (
    <>
      <JsonLd data={breadcrumb([[SITE_NAME, '/'], [name, PATH]])} />
      <HomeContent h1={h1For(PATH, h1For('/', SITE_JSON.home.title))} underBar />
    </>
  );
}
