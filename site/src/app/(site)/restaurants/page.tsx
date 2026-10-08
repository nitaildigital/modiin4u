import type { Metadata } from 'next';
import { pageMetadata, SITE_JSON } from '@/lib/seo';
import { RestaurantsPage } from '@/components/businesses/RestaurantsPage';

/** The section's title and description as site.json carries them (the
 *  WordPress restaurant map's, which this page took over). */
export function generateMetadata(): Metadata {
  const s = SITE_JSON.sections['/restaurants/'];
  return pageMetadata({ path: '/restaurants/', title: s?.title, description: s?.description });
}

/** Restaurants (web_restaurants_screen.dart, restaurants_screen.dart). */
export default function Restaurants() {
  return <RestaurantsPage path="/restaurants/" />;
}
