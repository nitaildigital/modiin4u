import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { storeLinks } from '@/lib/data/steps';
import { UrbanProfileView } from '@/components/messages/UrbanProfileView';

type Props = { params: Promise<{ username: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const t = tr(await getLang());
  const { username } = await params;
  // A resident's profile is not for search engines (docs/urban-profile/PLAN.md §4).
  return pageMetadata({ path: `/u/${username}/`, title: t('פרופיל עירוני', 'Urban Profile') + SUFFIX, noindex: true });
}

/** /u/<username> — a resident's Urban Profile, the link the app shares. Read
 *  in the browser with the reader's own session: `urban_profile()` shows a
 *  profile only to signed-in residents, and only when its owner allowed. */
export default async function UrbanProfilePage({ params }: Props) {
  const { username } = await params;
  return <UrbanProfileView lang={await getLang()} username={decodeURIComponent(username).toLowerCase()} stores={await storeLinks()} />;
}
