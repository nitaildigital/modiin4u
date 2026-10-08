import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { ShabbatPage } from '@/components/municipal/ShabbatPage';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({ path: '/shabat-times-modiin/' });
}

/** WordPress's Shabbat-times page, at its old address: the Shabbat &
 *  Holidays page with WordPress's title, description and H1. */
export default function Page() {
  return <ShabbatPage path="/shabat-times-modiin/" />;
}
