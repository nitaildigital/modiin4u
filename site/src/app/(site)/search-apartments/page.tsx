import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { h1For, pageMetadata } from '@/lib/seo';
import { RealEstateView } from '@/components/realestate/RealEstateView';
import type { SearchParams } from '@/components/realestate/search';

type Props = { searchParams: Promise<SearchParams> };

/** WordPress's apartment search: its title and description. */
export function generateMetadata(): Metadata {
  return pageMetadata({ path: '/search-apartments/' });
}

/** /search-apartments/ — the real estate section, at WordPress's address
 *  (web_realestate_screen.dart / realestate_screen.dart); with `?kind=` the
 *  search (web_realestate_search_screen.dart). /realestate/ comes here. */
export default async function RealEstatePage({ searchParams }: Props) {
  const t = tr(await getLang());
  const path = '/search-apartments/';
  return <RealEstateView path={path} h1={h1For(path, t('נדל״ן במודיעין', 'Real Estate in Modiin'))} sp={await searchParams} />;
}
