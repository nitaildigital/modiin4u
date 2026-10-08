import type { Metadata } from 'next';
import { getLang } from '@/lib/i18n';
import { pageMetadata } from '@/lib/seo';
import { AuthLanding } from '@/components/auth/AuthLanding';

export async function generateMetadata(): Promise<Metadata> {
  // A link from an e-mail, carrying a one-time token: never for search
  // engines.
  return pageMetadata({ path: '/auth/callback/', noindex: true });
}

/** Where the app's e-mails land — the sign-up confirmation and the password
 *  reset (/auth/callback in the app's router). */
export default async function Page() {
  const lang = await getLang();
  return <div className="wrap"><AuthLanding lang={lang} /></div>;
}
