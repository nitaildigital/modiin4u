import type { Metadata } from 'next';
import { getLang, tr } from '@/lib/i18n';
import { pageMetadata, SUFFIX } from '@/lib/seo';
import { ChatView } from '@/components/messages/ChatView';

type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const t = tr(await getLang());
  const { id } = await params;
  return pageMetadata({ path: `/messages/${id}/`, title: t('הודעות', 'Messages') + SUFFIX, noindex: true });
}

/** /messages/<id>/ — one conversation, live (the app's chat screen). */
export default async function ConversationPage({ params }: Props) {
  const { id } = await params;
  return <ChatView lang={await getLang()} id={decodeURIComponent(id)} />;
}
