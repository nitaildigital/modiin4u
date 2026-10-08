import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { DirectoryPage } from '@/components/businesses/DirectoryPage';

/** WordPress's business archive: its own title, description and H1. */
export function generateMetadata(): Metadata {
  return pageMetadata({ path: '/business/' });
}

/** The old site's /business/, served where it was with the directory. */
export default function OldBusinessArchive() {
  return <DirectoryPage path="/business/" />;
}
