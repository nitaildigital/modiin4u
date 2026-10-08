import type { Metadata } from 'next';
import { pageMetadata } from '@/lib/seo';
import { CommunityPage } from '@/components/community/CommunityPage';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({ path: '/facebookgruop/' });
}

/** WordPress's "join the group" page, at its old address (spelled as it
 *  was): the Community page, which carries the group's link, with
 *  WordPress's title. */
export default function Page() {
  return <CommunityPage path="/facebookgruop/" />;
}
