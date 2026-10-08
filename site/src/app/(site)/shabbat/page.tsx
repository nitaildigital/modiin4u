import type { Metadata } from 'next';
import { pageMetadata, SITE_JSON } from '@/lib/seo';
import { ShabbatPage } from '@/components/municipal/ShabbatPage';

export async function generateMetadata(): Promise<Metadata> {
  return pageMetadata({
    path: '/shabbat/',
    title: SITE_JSON.sections['/shabbat/']?.title,
    description: SITE_JSON.sections['/shabbat/']?.description,
  });
}

/** Shabbat & Holidays, where the Municipal page's tile leads. */
export default function Page() {
  return <ShabbatPage path="/shabbat/" />;
}
