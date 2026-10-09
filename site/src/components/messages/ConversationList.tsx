'use client';
import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { Briefcase, Messages2, SearchNormal1 } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb, useSession } from '@/lib/session';
import { Avatar, listTime, SignInFirst, SignOutLink } from './parts';

/** A conversation as `my_conversations` gives it (00069): the other side's
 *  name and photo — a resident's are private otherwise. */
export type Conversation = {
  id: string; business_id: string; profile_id: string; as_business: boolean;
  other_name: string | null; other_avatar: string | null; job_title: string | null;
  last_message: string | null; last_message_at: string; unread: number;
};

/** Messages (the onboarding designs' Messages frame, 9 Oct): the search over
 *  employers and job titles, then one row per conversation, newest first. */
export function ConversationList({ lang }: { lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const { session, ready } = useSession();
  const [rows, setRows] = useState<Conversation[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [query, setQuery] = useState('');

  useEffect(() => {
    if (!session) return;
    let alive = true;
    sessionDb().rpc('my_conversations').then(({ data, error }) => {
      if (!alive) return;
      if (error) return setFailed(true);
      setRows((data ?? []) as Conversation[]);
    });
    return () => { alive = false; };
  }, [session]);

  // The person's own conversations, already here: the search filters them
  // in the browser rather than asking the database again.
  const shown = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!rows || !q) return rows ?? [];
    return rows.filter((c) => [c.other_name, c.job_title, c.last_message].some((s) => (s ?? '').toLowerCase().includes(q)));
  }, [rows, query]);

  return (
    <div className="wrap">
      <div className="mx-auto max-w-[720px] py-6 desk:py-10">
        <div className="flex items-center justify-between gap-4">
          <h1 className="font-rubik text-2xl font-semibold text-ink desk:text-[28px]">{t('הודעות', 'Messages')}</h1>
          {session && <SignOutLink lang={lang} />}
        </div>
        {!ready ? (
          <Spinner />
        ) : !session ? (
          <SignInFirst lang={lang} next="/messages/" />
        ) : (
          <>
            <label className="mt-5 flex h-12 items-center gap-2 rounded-full border border-line bg-white px-4 focus-within:border-midblue">
              <SearchNormal1 size={19} color="#3D3D3D" />
              <input value={query} onChange={(e) => setQuery(e.target.value)} type="search"
                placeholder={t('חיפוש לפי עסק או משרה', 'Search employers or job titles')}
                className="h-full min-w-0 flex-1 bg-transparent text-[15px] text-ink outline-none placeholder:text-[#8A8A8A]" />
            </label>
            {failed ? (
              <Empty title={t('לא הצלחנו לטעון את ההודעות', "Couldn't load your messages")} text={t('רעננו את הדף כדי לנסות שוב.', 'Reload the page to try again.')} />
            ) : rows === null ? (
              <Spinner />
            ) : rows.length === 0 ? (
              <Empty title={t('אין הודעות עדיין', 'No messages yet')}
                text={t('אפשר לכתוב לעסק מהעמוד שלו או ממשרה שהגשתם אליה מועמדות. השיחות יופיעו כאן.',
                  'Write to a business from its page or from a job you applied to. Conversations appear here.')} />
            ) : shown.length === 0 ? (
              <Empty title={t('אין שיחה שמתאימה לחיפוש', 'No conversation matches')} text={t('נסו שם אחר או תפקיד אחר.', 'Try another name or job title.')} />
            ) : (
              <ul className="mt-3 divide-y divide-line">
                {shown.map((c) => <Row key={c.id} c={c} lang={lang} />)}
              </ul>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function Row({ c, lang }: { c: Conversation; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const unread = c.unread > 0;
  const name = c.other_name?.trim() || t('ללא שם', 'No name');
  const job = c.job_title?.trim();
  const last = c.last_message?.trim();
  return (
    <li>
      <Link href={`/messages/${c.id}/`} className="flex items-center gap-3 py-3.5 hover:bg-surface desk:px-2">
        <Avatar url={c.other_avatar} name={name} size={52} />
        <span className="min-w-0 flex-1">
          <span className="flex items-center gap-2">
            <span className="min-w-0 flex-1 truncate text-[15px] font-semibold text-black">{name}</span>
            <span className={`shrink-0 text-xs ${unread ? 'font-semibold text-midblue' : 'text-[#6D6D6D]'}`}>{listTime(c.last_message_at, lang)}</span>
          </span>
          {job && (
            <span className="mt-0.5 flex items-center gap-1.5 text-xs text-[#6D6D6D]">
              <Briefcase size={13} color="#6D6D6D" /><span className="truncate">{job}</span>
            </span>
          )}
          <span className="mt-1 flex items-center gap-2">
            <span className={`min-w-0 flex-1 truncate text-[13px] ${unread ? 'font-semibold text-ink' : 'text-[#6D6D6D]'}`}>
              {last || t('אין הודעות עדיין', 'No messages yet')}
            </span>
            {unread && (
              <span className="flex h-5 min-w-5 items-center justify-center rounded-full bg-midblue px-1.5 text-[11px] font-semibold text-white">
                {c.unread > 99 ? '99+' : c.unread}
              </span>
            )}
          </span>
        </span>
      </Link>
    </li>
  );
}

function Spinner() {
  return (
    <div className="flex justify-center py-16">
      <span className="size-9 animate-spin rounded-full border-[3px] border-midblue border-t-transparent" aria-hidden />
    </div>
  );
}

function Empty({ title, text }: { title: string; text: string }) {
  return (
    <div className="flex flex-col items-center py-16 text-center">
      <span className="flex size-[72px] items-center justify-center rounded-full bg-midblue/[0.08]"><Messages2 size={32} color="#123A72" /></span>
      <p className="mt-5 text-lg font-semibold text-ink">{title}</p>
      <p className="mt-2 max-w-sm text-sm text-[#6D6D6D]">{text}</p>
    </div>
  );
}
