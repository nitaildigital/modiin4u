import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { RestaurantsPage } from '@/components/businesses/RestaurantsPage';

/** WordPress's restaurant map: its own title, description and H1. */
export function generateMetadata(): Metadata {
  return pageMetadata({ path: '/search-rest-modiin/' });
}

/** The old site's /search-rest-modiin/, served where it was with Restaurants. */
export default function OldRestaurantSearch() {
  return <RestaurantsPage path="/search-rest-modiin/" />;
}
