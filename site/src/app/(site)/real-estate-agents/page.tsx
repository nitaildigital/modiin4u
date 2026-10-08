import type { Metadata } from 'next';
import { OldAddressPage, oldMetadata, oldPath } from '@/components/realestate/OldAddress';
import type { SearchParams } from '@/components/realestate/search';

/** /real-estate-agents/ — WordPress's page, standing in with the real estate section. */
type Props = { searchParams: Promise<SearchParams> };

export function generateMetadata(): Metadata {
  return oldMetadata(oldPath('/real-estate-agents/'));
}

export default function Page({ searchParams }: Props) {
  return <OldAddressPage path={oldPath('/real-estate-agents/')} searchParams={searchParams} />;
}
