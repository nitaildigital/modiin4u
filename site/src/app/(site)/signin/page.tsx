import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { storeLinks } from '@/lib/data/steps';
import { SignIn } from '@/components/messages/SignIn';

export async function generateMetadata(): Promise<Metadata> {
  const t = tr(await getLang());
  // An account's door: nothing for a search engine.
  return pageMetadata({ path: '/signin/', title: t('התחברות', 'Sign in') + SUFFIX, noindex: true });
}

/** /signin/ — residents and business owners sign in here to reach their
 *  Messages; accounts are made in the app. */
export default async function SignInPage() {
  return <SignIn lang={await getLang()} stores={await storeLinks()} />;
}
