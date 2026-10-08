import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { DirectoryPage } from '@/components/businesses/DirectoryPage';

export async function generateMetadata(): Promise<Metadata> {
  const t = tr(await getLang());
  // No WordPress page had this address; the section's name with the old
  // site's suffix, as the static build titled it, and the page's own line.
  return pageMetadata({
    path: '/businesses/',
    title: 'עסקים' + SUFFIX,
    description: t('מצאו עסקים מקומיים, נותני שירות ובעלי מקצוע מומלצים – הכל במקום אחד.',
      'Find trusted local businesses, service providers and professionals — all in one place.'),
  });
}

/** The business directory (web_businesses_screen.dart, businesses_screen.dart). */
export default function BusinessesPage() {
  return <DirectoryPage path="/businesses/" />;
}
