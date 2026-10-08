import type { Metadata } from 'next';
import { OldAddressPage, oldMetadata, oldPath } from '@/components/realestate/OldAddress';
import type { SearchParams } from '@/components/realestate/search';

/** /my-avenue/ — WordPress's page, standing in with the real estate section. */
type Props = { searchParams: Promise<SearchParams> };

export function generateMetadata(): Metadata {
  return oldMetadata(oldPath('/my-avenue/'));
}

export default function Page({ searchParams }: Props) {
  return <OldAddressPage path={oldPath('/my-avenue/')} searchParams={searchParams} />;
}
