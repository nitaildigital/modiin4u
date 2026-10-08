import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { h1For, pageMetadata, SUFFIX } from '@/lib/seo';
import { RealEstateView } from '@/components/realestate/RealEstateView';
import type { SearchParams } from '@/components/realestate/search';

type Props = { searchParams: Promise<SearchParams> };

// WordPress had no page here; the section's own name. No description of
// our making: Google writes its own snippet.
export function generateMetadata(): Metadata {
  return pageMetadata({ path: '/realestate/', title: 'נדל״ן במודיעין' + SUFFIX });
}

/** Real estate (web_realestate_screen.dart / realestate_screen.dart); with
 *  `?kind=` the search (web_realestate_search_screen.dart). */
export default async function RealEstatePage({ searchParams }: Props) {
  const t = tr(await getLang());
  return <RealEstateView path="/realestate/" h1={h1For('/realestate/', t('נדל״ן במודיעין', 'Real Estate in Modiin'))} sp={await searchParams} />;
}
