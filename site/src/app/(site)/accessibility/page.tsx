import type { Metadata } from 'next';
import { InfoPage, infoMetadata } from '@/components/info/InfoPage';

export async function generateMetadata(): Promise<Metadata> {
  return infoMetadata('accessibility');
}

/** The client's own page from the panel's עמודי מידע (slug `accessibility`). */
export default function Page() {
  return <InfoPage slug="accessibility" />;
}
