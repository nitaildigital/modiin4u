'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { Like1, MessageText1, TickCircle } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb, useSession } from '@/lib/session';
import { SignInFirst, SignOutLink } from '@/components/messages/parts';

/** One review or comment, as the app's My activity lists it
 *  (my_activity_provider.dart). */
type Item = {
  id: string; place: string; body: string; status: string; date: string;
  link: string | null; rating: number | null; answered: boolean; onReview: boolean;
  likes: number; helpful: number;
};

type Biz = { name: string; name_en: string | null; slug: string | null } | null;

/** The resident's reviews and comments, newest first, with their state and
 *  what others did with them; each opens where it was written. Read with the
 *  signed-in session: row security gives a person all of their own. */
export function MyActivityView({ lang }: { lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const { session, ready } = useSession();
  const [tab, setTab] = useState<'reviews' | 'comments'>('reviews');
  const [data, setData] = useState<{ reviews: Item[]; comments: Item[] } | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    if (!session) return;
    let alive = true;
    const db = sessionDb();
    const me = session.user.id;
    const day = new Intl.DateTimeFormat(lang === 'he' ? 'he-IL' : 'en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
    const when = (iso: string | null) => (iso ? day.format(new Date(iso)) : '');
    const bizName = (b: Biz) => (b ? (lang === 'en' && b.name_en?.trim() ? b.name_en : b.name) : '');
    const bizLink = (id: string, b: Biz) => `/business/${b?.slug || id}/`;

    (async () => {
      const [r, c] = await Promise.all([
        db.from('reviews')
          .select('id,business_id,rating,title,body,status,created_at,admin_response,businesses(name,name_en,slug)')
          .eq('author_id', me).is('withdrawn_at', null).order('created_at', { ascending: false }).limit(200),
        db.from('comments').select('id,entity_type,entity_id,body,status,created_at')
          .eq('author_id', me).order('created_at', { ascending: false }).limit(200),
      ]);
      if (r.error || c.error) throw r.error ?? c.error;
      type R = { id: string; business_id: string; rating: number; title: string | null; body: string | null; status: string; created_at: string | null; admin_response: string | null; businesses: Biz };
      type C = { id: string; entity_type: string; entity_id: string; body: string | null; status: string; created_at: string | null };
      const reviews = (r.data ?? []) as unknown as R[];
      const comments = (c.data ?? []) as C[];

      const articleIds = [...new Set(comments.filter((x) => x.entity_type === 'article').map((x) => x.entity_id))];
      const reviewIds = [...new Set(comments.filter((x) => x.entity_type === 'review').map((x) => x.entity_id))];
      const counts = async (type: string, ids: string[]) => {
        if (!ids.length) return {} as Record<string, { likes: number; helpful: number }>;
        const { data } = await db.rpc('reaction_counts', { p_entity_type: type, p_ids: ids });
        const out: Record<string, { likes: number; helpful: number }> = {};
        for (const x of (data ?? []) as { entity_id: string; likes: number; helpful: number }[]) out[x.entity_id] = { likes: Number(x.likes) || 0, helpful: Number(x.helpful) || 0 };
        return out;
      };
      const [articles, parents, rc, cc] = await Promise.all([
        articleIds.length ? db.from('articles').select('id,title,slug').in('id', articleIds).then((x) => x.data ?? []) : [],
        reviewIds.length ? db.from('reviews').select('id,business_id,businesses(name,name_en,slug)').in('id', reviewIds).then((x) => x.data ?? []) : [],
        counts('review', reviews.map((x) => x.id)),
        counts('comment', comments.map((x) => x.id)),
      ]);
      const art = new Map((articles as { id: string; title: string | null; slug: string | null }[]).map((a) => [a.id, a]));
      const par = new Map((parents as unknown as { id: string; business_id: string; businesses: Biz }[]).map((p) => [p.id, p]));

      const out = {
        reviews: reviews.map((x): Item => ({
          id: x.id, place: bizName(x.businesses), body: (x.body?.trim() || x.title || ''), status: x.status, date: when(x.created_at),
          link: bizLink(x.business_id, x.businesses), rating: x.rating, answered: !!x.admin_response?.trim(), onReview: false,
          likes: rc[x.id]?.likes ?? 0, helpful: rc[x.id]?.helpful ?? 0,
        })),
        comments: comments.flatMap((x): Item[] => {
          const onReview = x.entity_type === 'review';
          let place = ''; let link: string | null = null;
          if (onReview) {
            const p = par.get(x.entity_id);
            // The review it answered is no longer shown: nowhere to open it.
            if (!p) return [];
            place = bizName(p.businesses); link = bizLink(p.business_id, p.businesses);
          } else {
            const a = art.get(x.entity_id);
            place = a?.title ?? ''; link = a?.slug ? `/news/${a.slug}/` : null;
          }
          return [{ id: x.id, place, body: x.body ?? '', status: x.status, date: when(x.created_at), link, rating: null, answered: false, onReview, likes: cc[x.id]?.likes ?? 0, helpful: 0 }];
        }),
      };
      if (alive) setData(out);
    })().catch(() => { if (alive) setFailed(true); });
    return () => { alive = false; };
  }, [session, lang]);

  const list = data ? data[tab] : [];
  return (
    <div className="wrap pb-20 pt-8 desk:pt-12">
      <div className="mx-auto max-w-[720px]">
        <div className="flex items-center justify-between gap-4">
          <h1 className="font-nunito text-2xl font-semibold text-navy">{t('הפעילות שלי', 'My activity')}</h1>
          {session && <SignOutLink lang={lang} />}
        </div>
        {!ready ? (
          <p className="py-16 text-center text-sm text-[#6D6D6D]">…</p>
        ) : !session ? (
          <SignInFirst lang={lang} next="/my-activity/" icon={<MessageText1 size={32} color="#123A72" />}
            title={t('התחברו כדי לראות את הפעילות שלכם', 'Sign in to see your activity')}
            text={t('הביקורות והתגובות שכתבתם באפליקציה, ומה קרה איתן.', 'The reviews and comments you wrote in the app, and what came of them.')} />
        ) : (
          <>
            <div className="mt-5 flex gap-2">
              {(['reviews', 'comments'] as const).map((k) => (
                <button key={k} type="button" onClick={() => setTab(k)}
                  className={`flex h-11 items-center gap-1.5 rounded-full border px-4 text-sm text-navy ${tab === k ? 'border-[#E3EDFB] bg-[#E3EDFB]' : 'border-line bg-white'}`}>
                  {tab === k && <span aria-hidden>✓</span>}
                  {k === 'reviews' ? t('ביקורות', 'Reviews') : t('תגובות', 'Comments')}{data && ` (${data[k].length})`}
                </button>
              ))}
            </div>
            {failed ? (
              <p className="py-12 text-center text-sm text-[#6D6D6D]">{t('לא הצלחנו לטעון את הפעילות שלכם. רעננו את הדף כדי לנסות שוב.', 'Could not load your activity. Reload the page to try again.')}</p>
            ) : !data ? (
              <p className="py-16 text-center text-sm text-[#6D6D6D]">…</p>
            ) : list.length === 0 ? (
              <p className="py-12 text-center text-sm text-[#6D6D6D]">
                {tab === 'reviews'
                  ? t('עדיין לא כתבתם ביקורת. ביקורות שתכתבו באפליקציה יופיעו כאן.', 'You have not reviewed a place yet. Reviews you write in the app appear here.')
                  : t('עדיין לא הגבתם. תגובות שתכתבו באפליקציה יופיעו כאן.', 'You have not commented yet. Comments you write in the app appear here.')}
              </p>
            ) : (
              <ul className="mt-2">
                {list.map((x) => <Row key={x.id} x={x} lang={lang} />)}
              </ul>
            )}
          </>
        )}
      </div>
    </div>
  );
}

function Row({ x, lang }: { x: Item; lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const status = x.status === 'approved' ? null
    : x.status === 'pending' ? <span className="font-semibold text-[#D98A00]">{t('ממתין לאישור', 'Pending approval')}</span>
      : <span className="font-semibold text-[#E74C3C]">{t('לא פורסם', 'Not published')}</span>;
  const body = (
    <div className="py-4">
      <p className="flex items-center gap-3">
        <span dir="auto" className="min-w-0 flex-1 truncate text-[15px] font-semibold text-navy">{x.place || t('מודיעין בשבילך', 'Modiin4u')}</span>
        <span className="shrink-0 text-xs text-[#6D6D6D]">{x.date}</span>
      </p>
      <p className="mt-1 flex flex-wrap items-center gap-2 text-xs text-[#6D6D6D]">
        {x.rating != null && (
          <span dir="ltr" className="flex gap-0.5">{[1, 2, 3, 4, 5].map((i) => <span key={i} className={i <= x.rating! ? 'text-[#FFC107]' : 'text-[#CFCFCF]'}>★</span>)}</span>
        )}
        {x.rating == null && (x.onReview ? t('תגובה לביקורת', 'Reply to a review') : t('תגובה לכתבה', 'Comment on an article'))}
        {status}
      </p>
      {x.body.trim() && <p dir="auto" className="mt-1.5 line-clamp-3 whitespace-pre-line text-sm leading-[1.4] text-[#3D3D3D]">{x.body}</p>}
      {(x.likes > 0 || x.helpful > 0 || x.answered) && (
        <p className="mt-2 flex flex-wrap items-center gap-4 text-[13px] font-semibold text-midblue">
          {x.likes > 0 && <span className="flex items-center gap-1"><Like1 size={16} color="#123A72" variant="Bold" />{x.likes}</span>}
          {x.helpful > 0 && <span className="flex items-center gap-1"><TickCircle size={16} color="#123A72" variant="Bold" />{t('מועיל', 'Helpful')} · {x.helpful}</span>}
          {x.answered && <span className="flex items-center gap-1"><MessageText1 size={16} color="#123A72" variant="Bold" />{t('התקבלה תשובה', 'Answered')}</span>}
        </p>
      )}
    </div>
  );
  return (
    <li className="border-b border-line last:border-b-0">
      {x.link ? <Link href={x.link} className="block hover:bg-section/60">{body}</Link> : body}
    </li>
  );
}
