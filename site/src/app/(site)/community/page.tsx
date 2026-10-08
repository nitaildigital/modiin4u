import type { Metadata } from 'next';
import { pageMetadata, SITE_JSON } from '@/lib/seo';
import { CommunityPage } from '@/components/community/CommunityPage';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({
    path: '/community/',
    title: SITE_JSON.sections['/community/']?.title,
    description: SITE_JSON.sections['/community/']?.description,
  });
}

/** Community: the client's Facebook group, his "share with us" form and his
 *  community news. */
export default function Page() {
  return <CommunityPage path="/community/" />;
}
