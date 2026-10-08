import type { Metadata } from 'next';
import { OldAddressPage, oldMetadata, oldPath } from '@/components/realestate/OldAddress';
import type { SearchParams } from '@/components/realestate/search';

/** /real-estate-agents/<slug>/ — only the pages WordPress had here (the snapshot's
 *  addresses); any other slug is not found. */
type Props = { params: Promise<{ slug: string }>; searchParams: Promise<SearchParams> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  return oldMetadata(oldPath('/real-estate-agents/', (await params).slug));
}

export default async function Page({ params, searchParams }: Props) {
  return <OldAddressPage path={oldPath('/real-estate-agents/', (await params).slug)} searchParams={searchParams} />;
}
