import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { businessCategoryBySlug } from '@/lib/data/businesses';
import { CategoryPage } from '@/components/businesses/CategoryPage';

/** WordPress's professionals archive: its own title, description and H1. */
export function generateMetadata(): Metadata {
  return pageMetadata({ path: '/professionals/' });
}

/** The old site's /professionals/, served where it was: the site's
 *  professionals are the businesses in the Services category. */
export default async function OldProfessionals() {
  return <CategoryPage path="/professionals/" category={await businessCategoryBySlug('services')} />;
}
