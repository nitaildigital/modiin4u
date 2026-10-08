import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { DirectoryPage } from '@/components/businesses/DirectoryPage';

/** WordPress's city-centre page: its own title, description and H1. */
export function generateMetadata(): Metadata {
  return pageMetadata({ path: '/maar/' });
}

/** The old site's /maar/ (מרכז העיר), served where it was with the directory
 *  that replaced it. */
export default function OldCityCentre() {
  return <DirectoryPage path="/maar/" />;
}
