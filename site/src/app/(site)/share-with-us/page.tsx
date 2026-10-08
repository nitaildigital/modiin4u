import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { CommunityPage } from '@/components/community/CommunityPage';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({ path: '/share-with-us/' });
}

/** WordPress's "share with us" page, at its old address: the Community page,
 *  which carries the form's link, with WordPress's title and H1. */
export default function Page() {
  return <CommunityPage path="/share-with-us/" />;
}
