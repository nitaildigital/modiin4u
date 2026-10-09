'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { ArrowRight2, ArrowLeft2, Briefcase, Send2 } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb, unreadChanged, useSession } from '@/lib/session';
import { Avatar, SignInFirst, SignOutLink } from './parts';
import type { Conversation } from './ConversationList';

type Message = { id: string; conversation_id: string; sender_id: string | null; body: string; created_at: string };

const MAX = 4000;

/** One conversation, live (chat_screen.dart, `business_side/Message.png`):
 *  the other side at the top, the messages oldest first with the newest at
 *  the foot, and a field to write in. New messages arrive as they are sent
 *  (realtime, 00069); reading marks the conversation read. Text only, as in
 *  the app — no "Online", attachments or emoji, which nothing backs. */
export function ChatView({ lang, id }: { lang: Lang; id: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const { session, ready } = useSession();
  const me = session?.user.id;
  const [conversation, setConversation] = useState<Conversation | null | undefined>(undefined);
  const [messages, setMessages] = useState<Message[] | null>(null);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const bottom = useRef<HTMLDivElement>(null);
  const readTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // A burst of replies is one "read", not several.
  const markRead = useCallback(() => {
    if (readTimer.current) clearTimeout(readTimer.current);
    readTimer.current = setTimeout(async () => {
      await sessionDb().rpc('mark_conversation_read', { p_conversation: id });
      unreadChanged();
    }, 600);
  }, [id]);

  useEffect(() => {
    if (!session) return;
    const db = sessionDb();
    let alive = true;
    (async () => {
      const [list, rows] = await Promise.all([
        db.rpc('my_conversations'),
        db.from('messages').select('id,conversation_id,sender_id,body,created_at')
          .eq('conversation_id', id).order('created_at', { ascending: true }).limit(1000),
      ]);
      if (!alive) return;
      const c = ((list.data ?? []) as Conversation[]).find((x) => x.id === id) ?? null;
      setConversation(c);
      if (!c) return;
      setMessages((rows.data ?? []) as Message[]);
      markRead();
    })();

    // Each new line in this conversation, from either side. One sent from
    // here is already on the screen; the id keeps it from showing twice.
    const channel = db.channel(`conversation-${id}`)
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${id}` }, (payload) => {
        const m = payload.new as Message;
        setMessages((prev) => (prev && !prev.some((x) => x.id === m.id) ? [...prev, m] : prev));
        if (m.sender_id !== session.user.id) markRead();
      })
      .subscribe();
    return () => {
      alive = false;
      db.removeChannel(channel);
      if (readTimer.current) clearTimeout(readTimer.current);
    };
  }, [session, id, markRead]);

  useEffect(() => {
    bottom.current?.scrollIntoView({ block: 'end' });
  }, [messages?.length]);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    const body = text.trim();
    if (!body || !me || sending) return;
    setSending(true);
    setError(null);
    const { data, error: failed } = await sessionDb().from('messages')
      .insert({ conversation_id: id, sender_id: me, body })
      .select('id,conversation_id,sender_id,body,created_at').single();
    setSending(false);
    if (failed) return setError(t('ההודעה לא נשלחה. נסו שוב.', 'The message was not sent. Try again.'));
    setText('');
    const m = data as Message;
    setMessages((prev) => (prev && !prev.some((x) => x.id === m.id) ? [...prev, m] : prev));
  }

  const Back = lang === 'he' ? ArrowRight2 : ArrowLeft2;
  const name = conversation?.other_name?.trim() || t('ללא שם', 'No name');

  return (
    <div className="wrap">
      <div className="mx-auto flex max-w-[720px] flex-col py-4 desk:py-8" style={{ minHeight: 'calc(100dvh - 160px)' }}>
        <div className="flex items-center gap-3 border-b border-line pb-3">
          <Link href="/messages/" aria-label={t('חזרה להודעות', 'Back to messages')} className="p-1 text-[#3D3D3D]"><Back size={22} color="currentColor" /></Link>
          {conversation && (
            <>
              <Avatar url={conversation.other_avatar} name={name} size={40} />
              <span className="min-w-0 flex-1">
                <h1 className="truncate text-base font-semibold text-black">{name}</h1>
                {conversation.job_title && (
                  <span className="flex items-center gap-1.5 text-xs text-[#6D6D6D]">
                    <Briefcase size={13} color="#6D6D6D" /><span className="truncate">{conversation.job_title}</span>
                  </span>
                )}
              </span>
            </>
          )}
          {!conversation && <h1 className="flex-1 text-base font-semibold text-black">{t('הודעות', 'Messages')}</h1>}
          {session && <SignOutLink lang={lang} />}
        </div>

        {!ready ? null : !session ? (
          <SignInFirst lang={lang} next={`/messages/${id}/`} />
        ) : conversation === null ? (
          <p className="py-16 text-center text-[#6D6D6D]">{t('השיחה לא נמצאה.', 'This conversation was not found.')}</p>
        ) : (
          <>
            <div className="flex-1 py-4">
              {messages === null ? (
                <div className="flex justify-center py-16"><span className="size-9 animate-spin rounded-full border-[3px] border-midblue border-t-transparent" aria-hidden /></div>
              ) : messages.length === 0 ? (
                <p className="py-16 text-center text-sm text-[#6D6D6D]">{t('כתבו את ההודעה הראשונה.', 'Write the first message.')}</p>
              ) : (
                <ol className="flex flex-col gap-2">
                  {messages.map((m, i) => {
                    const mine = m.sender_id === me;
                    const day = dayLabel(m.created_at, lang);
                    const newDay = i === 0 || dayLabel(messages[i - 1].created_at, lang) !== day;
                    return (
                      <li key={m.id} className="flex flex-col">
                        {newDay && <span className="mx-auto my-2 rounded-full bg-[#ECEFF3] px-3 py-1 text-xs text-[#6D6D6D]">{day}</span>}
                        <span className={`max-w-[78%] whitespace-pre-wrap break-words rounded-2xl px-4 py-2.5 text-[15px] leading-[1.45] ${mine ? 'self-end bg-midblue text-white' : 'self-start bg-[#F4F4F4] text-ink'}`}>
                          {m.body}
                          <span className={`mt-1 block text-[11px] ${mine ? 'text-white/70' : 'text-[#8A8A8A]'}`}>{clock(m.created_at)}</span>
                        </span>
                      </li>
                    );
                  })}
                </ol>
              )}
              <div ref={bottom} />
            </div>
            <form onSubmit={send} className="sticky bottom-[76px] flex items-end gap-2 border-t border-line bg-white py-3 desk:bottom-0">
              <textarea value={text} onChange={(e) => setText(e.target.value.slice(0, MAX))} rows={1}
                onKeyDown={(e) => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); e.currentTarget.form?.requestSubmit(); } }}
                placeholder={t('כתבו הודעה…', 'Write a message…')} aria-label={t('הודעה', 'Message')}
                className="max-h-40 min-h-12 flex-1 resize-none rounded-3xl border border-line bg-white px-4 py-3 text-[15px] text-ink outline-none focus:border-midblue" />
              <button type="submit" disabled={!text.trim() || sending} aria-label={t('שליחה', 'Send')}
                className="flex size-12 shrink-0 items-center justify-center rounded-full bg-midblue text-white disabled:bg-midblue/40">
                <Send2 size={20} color="currentColor" className={lang === 'he' ? '-scale-x-100' : ''} />
              </button>
            </form>
            {error && <p role="alert" className="pb-3 text-sm text-[#C0392B]">{error}</p>}
          </>
        )}
      </div>
    </div>
  );
}

function clock(iso: string): string {
  const d = new Date(iso);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

/** "Today", "Yesterday", or the date — the pill over each day's messages. */
function dayLabel(iso: string, lang: Lang): string {
  const d = new Date(iso);
  const now = new Date();
  const day = (x: Date) => new Date(x.getFullYear(), x.getMonth(), x.getDate()).getTime();
  const days = Math.round((day(now) - day(d)) / 86_400_000);
  if (days <= 0) return lang === 'he' ? 'היום' : 'Today';
  if (days === 1) return lang === 'he' ? 'אתמול' : 'Yesterday';
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
}
