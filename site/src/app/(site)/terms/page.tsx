import type { Metadata } from 'next';
import { InfoPage, infoMetadata } from '@/components/info/InfoPage';

export async function generateMetadata(): Promise<Metadata> {
  return infoMetadata('terms');
}

/** The client's own page from the panel's עמודי מידע (slug `terms`). */
export default function Page() {
  return <InfoPage slug="terms" />;
}
