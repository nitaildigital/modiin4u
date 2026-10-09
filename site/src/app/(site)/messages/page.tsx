import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { ConversationList } from '@/components/messages/ConversationList';

export async function generateMetadata(): Promise<Metadata> {
  const t = tr(await getLang());
  // Someone's own conversations: never for a search engine.
  return pageMetadata({ path: '/messages/', title: t('הודעות', 'Messages') + SUFFIX, noindex: true });
}

/** /messages/ — the conversations between businesses and residents, as the
 *  app's Messages lists them, with the same search. */
export default async function MessagesPage() {
  return <ConversationList lang={await getLang()} />;
}
