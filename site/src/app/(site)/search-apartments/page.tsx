import type { Metadata } from 'next';
import { OldAddressPage, oldMetadata, oldPath } from '@/components/realestate/OldAddress';
import type { SearchParams } from '@/components/realestate/search';

/** /search-apartments/ — WordPress's page, standing in with the real estate section. */
type Props = { searchParams: Promise<SearchParams> };

export function generateMetadata(): Metadata {
  return oldMetadata(oldPath('/search-apartments/'));
}

export default function Page({ searchParams }: Props) {
  return <OldAddressPage path={oldPath('/search-apartments/')} searchParams={searchParams} />;
}
