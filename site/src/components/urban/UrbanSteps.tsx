'use client';
import { useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Camera, Copy, SearchNormal1, TickCircle, User } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { useSession } from '@/lib/session';
import { ownPhoto } from '@/lib/photos';
import {
  BIO_MAX, INTERESTS, MAX_INTERESTS, MAX_PLACES, MIN_INTERESTS, firstIncomplete, markCompleted, mine, saveAvatar, saveBio,
  saveInterests, savePlaces, searchPlaces, setUsername, setVisible, suggestUsernames, uploadPhoto, usernameAvailable, usernameSeed,
  type Mine, type Place,
} from '@/lib/urban';
import { SignInFirst } from '@/components/messages/parts';

export type Step = 'start' | 1 | 2 | 3 | 'done';

const PROFILE_BASE = 'https://www.modiin4u.co.il/u/';

/** The Urban Profile's three steps and its "ready" page on the website (the
 *  app's urban_profile_steps.dart and urban_profile_done_screen.dart, from
 *  the onboarding frames of 9 Oct): a photo and a few words, interests,
 *  favourite places — each skippable — then the profile link and who may see
 *  it. Signed-in residents only; a business account has no profile. */
export function UrbanSteps({ lang, step }: { lang: Lang; step: Step }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const router = useRouter();
  const { session, ready } = useSession();
  const [me, setMe] = useState<Mine | null | undefined>(undefined);
  const [failed, setFailed] = useState(false);
  const next = useRef('/messages/');

  useEffect(() => {
    const n = new URLSearchParams(window.location.search).get('next');
    if (n && n.startsWith('/') && !n.startsWith('//')) next.current = n;
  }, []);
  useEffect(() => {
    if (!ready || !session) return;
    mine().then(setMe, () => setFailed(true));
  }, [ready, session]);
  // "/urban-profile/": on to the first step still missing something.
  useEffect(() => {
    if (step !== 'start' || !me || me.isBusiness) return;
    const s = firstIncomplete(me);
    router.replace(`/urban-profile/${s ?? 'done'}/${q()}`);
  }, [step, me]); // eslint-disable-line react-hooks/exhaustive-deps

  const q = () => (next.current !== '/messages/' ? `?next=${encodeURIComponent(next.current)}` : '');
  const go = (s: Step) => router.push(`/urban-profile/${s}/${q()}`);

  if (!ready || (session && me === undefined && !failed)) return <Card><p className="py-16 text-center text-sm text-[#6D6D6D]">{t('טוען…', 'Loading…')}</p></Card>;
  if (!session) return <div className="wrap"><SignInFirst lang={lang} next={`/urban-profile/${step === 'start' ? '' : step + '/'}`} /></div>;
  if (failed || !me) return <Card><p className="py-16 text-center text-sm text-[#6D6D6D]">{t('לא ניתן היה לטעון את הפרופיל.', 'Could not load your profile.')}</p></Card>;
  if (me.isBusiness) {
    return (
      <Card>
        <p className="py-12 text-center text-base text-[#3D3D3D]">{t('לחשבון עסקי אין פרופיל עירוני — הפרופיל העירוני הוא של תושבים.', 'A business account has no Urban Profile — it is for residents.')}</p>
      </Card>
    );
  }
  if (step === 'start') return <Card><p className="py-16 text-center text-sm text-[#6D6D6D]">{t('טוען…', 'Loading…')}</p></Card>;
  if (step === 1) return <PhotoBio lang={lang} me={me} onDone={() => go(2)} onSkip={() => go(2)} onBack={() => router.push(next.current)} />;
  if (step === 2) return <Interests lang={lang} me={me} onDone={() => go(3)} onSkip={() => go(3)} onBack={() => go(1)} />;
  if (step === 3) return <Places lang={lang} me={me} onDone={() => go('done')} onSkip={() => go('done')} onBack={() => go(2)} />;
  return <Done lang={lang} me={me} reload={() => mine().then(setMe)} enter={next.current} />;
}

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="wrap pb-16 pt-6 desk:pt-12">
      <div className="mx-auto max-w-[560px] rounded-[20px] border border-line bg-white p-5 shadow-[0_6px_24px_rgba(0,0,0,0.06)] desk:p-8">{children}</div>
    </div>
  );
}

/** The frame the three steps share: back, the three-part progress bar, the
 *  title and the line under it, the step itself, Skip for Now and the main button. */
function Frame({ lang, step, title, subtitle, primary, busy, onPrimary, onSkip, onBack, error, children }: {
  lang: Lang; step: 1 | 2 | 3; title: string; subtitle: string; primary: string; busy: boolean;
  onPrimary: () => void; onSkip: () => void; onBack: () => void; error: string | null; children: React.ReactNode;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  return (
    <Card>
      <div className="flex items-center gap-3">
        <button type="button" onClick={onBack} className="text-sm font-medium text-midblue">{t('חזרה', 'Back')}</button>
        <div className="flex flex-1 gap-1.5" aria-label={t(`שלב ${step} מתוך 3`, `Step ${step} of 3`)}>
          {[1, 2, 3].map((i) => <span key={i} className={`h-1.5 flex-1 rounded-full ${i <= step ? 'bg-midblue' : 'bg-[#DADADA]'}`} />)}
        </div>
      </div>
      <h1 className="mt-6 font-nunito text-2xl font-semibold text-[#1C1C1E]">{title}</h1>
      <p className="mt-2 text-[13.5px] leading-[1.4] text-[#6D6D6D]">{subtitle}</p>
      <div className="mt-6">{children}</div>
      {error && <p className="mt-4 text-sm text-error">{error}</p>}
      <div className="mt-8 flex items-center justify-between gap-3">
        <button type="button" onClick={onSkip} className="px-2 py-3 text-sm font-medium text-[#6D6D6D]">{t('דלג בינתיים', 'Skip for Now')}</button>
        <button type="button" disabled={busy} onClick={onPrimary}
          className="flex h-12 min-w-[150px] items-center justify-center rounded-full bg-midblue px-8 text-base font-medium text-white hover:bg-midblue/90 disabled:opacity-60">
          {busy ? t('שומר…', 'Saving…') : primary}
        </button>
      </div>
    </Card>
  );
}

// ─── Step 1: a photo and a few words ───

function PhotoBio({ lang, me, onDone, onSkip, onBack }: { lang: Lang; me: Mine; onDone: () => void; onSkip: () => void; onBack: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [bio, setBio] = useState(me.bio ?? '');
  const [file, setFile] = useState<File | null>(null);
  const preview = useMemo(() => (file ? URL.createObjectURL(file) : null), [file]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const pick = useRef<HTMLInputElement>(null);
  const shown = preview ?? (me.avatar_url ? ownPhoto(me.avatar_url, 240) ?? me.avatar_url : null);
  async function save() {
    setBusy(true); setError(null);
    try {
      if (file) await saveAvatar(await uploadPhoto(file));
      await saveBio(bio);
      onDone();
    } catch { setError(t('לא ניתן היה לשמור. נסו שוב.', 'Could not save. Please try again.')); setBusy(false); }
  }
  return (
    <Frame lang={lang} step={1} busy={busy} error={error} onPrimary={save} onSkip={onSkip} onBack={onBack}
      title={t('הפרופיל שלכם, בסגנון שלכם', 'Make Your Profile Yours')}
      subtitle={t('הוסיפו תמונה וכמה מילים על עצמכם כדי להתאים את הפרופיל שלכם במודיעין בשבילך.', 'Add a photo and a little about yourself to personalize your M4U profile.')}
      primary={t('המשך', 'Continue')}>
      <div className="flex flex-col items-center">
        <button type="button" onClick={() => pick.current?.click()} className="relative size-28 overflow-hidden rounded-full bg-[#E7ECF7]" aria-label={t('בחירת תמונה', 'Choose a photo')}>
          {shown ? <img src={shown} alt="" className="size-full object-cover" /> : <span className="flex size-full items-center justify-center"><User size={44} color="#123A72" /></span>}
          <span className="absolute bottom-1 end-1 flex size-9 items-center justify-center rounded-full bg-midblue text-white"><Camera size={18} color="#fff" /></span>
        </button>
        <input ref={pick} type="file" accept="image/*" hidden onChange={(e) => { const f = e.target.files?.[0]; if (f) setFile(f); }} />
      </div>
      <label className="mt-6 block text-[13px] font-medium text-[#1C1C1E]" htmlFor="bio">{t('כמה מילים עליי', 'Short Bio')}</label>
      <textarea id="bio" value={bio} maxLength={BIO_MAX} rows={3} onChange={(e) => setBio(e.target.value)}
        placeholder={t('ספרו במילים ספורות מה אתם אוהבים בעיר…', 'Tell us in a few words what you love about the city…')}
        className="mt-2 w-full resize-none rounded-xl border border-line p-3 text-sm outline-none focus:border-midblue" />
      <p className="mt-1 text-end text-xs text-[#6D6D6D]">{bio.length}/{BIO_MAX}</p>
    </Frame>
  );
}

// ─── Step 2: interests ───

function Interests({ lang, me, onDone, onSkip, onBack }: { lang: Lang; me: Mine; onDone: () => void; onSkip: () => void; onBack: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [chosen, setChosen] = useState<string[]>(me.interests);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const toggle = (k: string) => setChosen((c) => (c.includes(k) ? c.filter((x) => x !== k) : c.length >= MAX_INTERESTS ? c : [...c, k]));
  async function save() {
    if (chosen.length < MIN_INTERESTS) return setError(t(`בחרו לפחות ${MIN_INTERESTS} תחומי עניין`, `Choose at least ${MIN_INTERESTS} interests`));
    setBusy(true); setError(null);
    try { await saveInterests(chosen); onDone(); } catch { setError(t('לא ניתן היה לשמור. נסו שוב.', 'Could not save. Please try again.')); setBusy(false); }
  }
  return (
    <Frame lang={lang} step={2} busy={busy} error={error} onPrimary={save} onSkip={onSkip} onBack={onBack}
      title={t('מה מעניין אתכם?', 'What Interests You?')}
      subtitle={t('בחרו תחומי עניין כדי שנתאים לכם את מודיעין.', 'Choose your interests to help us personalize your Modiin experience.')}
      primary={t('המשך', 'Continue')}>
      <p className="text-xs text-[#6D6D6D]">
        {chosen.length >= MAX_INTERESTS ? t(`עד ${MAX_INTERESTS} תחומי עניין`, `Up to ${MAX_INTERESTS} interests`)
          : t(`בחרו לפחות ${MIN_INTERESTS} תחומי עניין · נבחרו ${chosen.length}`, `Choose at least ${MIN_INTERESTS} interests · ${chosen.length} chosen`)}
      </p>
      <div className="mt-3 flex flex-wrap gap-2">
        {INTERESTS.map(([key, emoji, he, en]) => {
          const on = chosen.includes(key);
          return (
            <button key={key} type="button" onClick={() => toggle(key)} aria-pressed={on}
              className={`flex items-center gap-1.5 rounded-full border px-3.5 py-2 text-sm ${on ? 'border-midblue bg-midblue text-white' : 'border-line bg-white text-[#3D3D3D]'}`}>
              <span aria-hidden>{emoji}</span>{lang === 'he' ? he : en}
            </button>
          );
        })}
      </div>
    </Frame>
  );
}

// ─── Step 3: favourite places ───

function Places({ lang, me, onDone, onSkip, onBack }: { lang: Lang; me: Mine; onDone: () => void; onSkip: () => void; onBack: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [chosen, setChosen] = useState<Place[]>(me.places);
  const [query, setQuery] = useState('');
  const [found, setFound] = useState<Place[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  useEffect(() => {
    const id = setTimeout(() => { searchPlaces(query).then(setFound, () => setFound([])); }, query ? 300 : 0);
    return () => clearTimeout(id);
  }, [query]);
  const name = (p: Place) => (lang === 'en' && p.name_en?.trim()) || p.name;
  const has = (p: Place) => chosen.some((c) => c.id === p.id);
  const toggle = (p: Place) => {
    if (has(p)) return setChosen((c) => c.filter((x) => x.id !== p.id));
    if (chosen.length >= MAX_PLACES) return setError(t(`עד ${MAX_PLACES} מקומות`, `Up to ${MAX_PLACES} places`));
    setError(null); setChosen((c) => [...c, p]);
  };
  async function save() {
    setBusy(true); setError(null);
    try { await savePlaces(chosen); onDone(); } catch { setError(t('לא ניתן היה לשמור. נסו שוב.', 'Could not save. Please try again.')); setBusy(false); }
  }
  const tile = (p: Place) => (
    <li key={p.id}>
      <button type="button" onClick={() => toggle(p)} aria-pressed={has(p)}
        className={`flex w-full items-center gap-3 rounded-xl border p-2 text-start ${has(p) ? 'border-midblue bg-midblue/[0.04]' : 'border-line'}`}>
        <span className="size-12 shrink-0 overflow-hidden rounded-lg bg-[#E7ECF7]">{p.image && <img src={ownPhoto(p.image, 120) ?? p.image} alt="" loading="lazy" className="size-full object-cover" />}</span>
        <span dir="auto" className="min-w-0 flex-1 truncate text-sm font-medium text-[#1C1C1E]">{name(p)}</span>
        <span className={`text-xs font-medium ${has(p) ? 'text-midblue' : 'text-[#6D6D6D]'}`}>
          {has(p) ? <TickCircle size={20} color="#123A72" variant="Bold" /> : t('הוספה', 'Add')}
        </span>
      </button>
    </li>
  );
  return (
    <Frame lang={lang} step={3} busy={busy} error={error} onPrimary={save} onSkip={onSkip} onBack={onBack}
      title={t('המקומות האהובים עליכם', 'Your Favorite Places')}
      subtitle={t(`בחרו עד ${MAX_PLACES} מקומות במודיעין שתמיד כיף לחזור אליהם.`, `Choose up to ${MAX_PLACES} places in Modiin you are always happy to return to.`)}
      primary={t('בואו נתחיל', 'Get Started')}>
      <label className="flex h-11 items-center gap-2 rounded-full border border-line px-4">
        <SearchNormal1 size={18} color="#6D6D6D" />
        <input value={query} onChange={(e) => setQuery(e.target.value)} placeholder={t('חיפוש מקומות במודיעין…', 'Search places in Modiin…')}
          className="min-w-0 flex-1 bg-transparent text-sm outline-none" />
      </label>
      {chosen.length > 0 && (
        <>
          <p className="mt-5 text-[13px] font-medium text-[#1C1C1E]">{t(`המקומות שלכם (${chosen.length}/${MAX_PLACES})`, `Your places (${chosen.length}/${MAX_PLACES})`)}</p>
          <ul className="mt-2 flex flex-col gap-2">{chosen.map(tile)}</ul>
        </>
      )}
      <p className="mt-5 text-[13px] font-medium text-[#1C1C1E]">{query ? t('תוצאות', 'Results') : t('מקומות פופולריים', 'Popular Places')}</p>
      {found.length === 0
        ? <p className="mt-2 text-sm text-[#6D6D6D]">{query ? t('לא נמצא מקום בשם הזה.', 'No place by that name.') : t('חפשו מקום למעלה.', 'Search for a place above.')}</p>
        : <ul className="mt-2 flex max-h-[360px] flex-col gap-2 overflow-y-auto">{found.filter((p) => !has(p)).map(tile)}</ul>}
    </Frame>
  );
}

// ─── Ready: the link, and who may see it ───

function Done({ lang, me, reload, enter }: { lang: Lang; me: Mine; reload: () => void; enter: string }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [settled, setSettled] = useState(false);
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState('');
  const [note, setNote] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  // On arrival: a link made if there is none (a permanent username for
  // everyone), and a profile with all three steps marked complete.
  useEffect(() => {
    if (settled) return;
    setSettled(true);
    (async () => {
      let changed = false;
      try {
        if (!me.username) {
          const free = await suggestUsernames(usernameSeed(me.name, me.email));
          if (free[0]) { await setUsername(free[0]); changed = true; }
        }
        if (firstIncomplete(me) === null && !me.completed_at) { await markCompleted(); changed = true; }
      } catch { /* the link can still be made below */ }
      if (changed) reload();
    })();
  }, [settled, me, reload]);
  const link = me.username ? PROFILE_BASE + me.username : null;
  const missing = firstIncomplete(me);
  async function saveName() {
    const name = draft.trim().toLowerCase();
    if (!/^[a-z0-9_.]{3,30}$/.test(name)) return setNote(t('3–30 אותיות באנגלית, ספרות, נקודה או קו תחתון.', '3–30 Latin letters, digits, dot or underscore.'));
    try {
      if (!(await usernameAvailable(name))) return setNote(t('השם הזה תפוס.', 'That name is taken.'));
      await setUsername(name); setEditing(false); setNote(null); reload();
    } catch { setNote(t('השם הזה נתפס הרגע. נסו אחר.', 'That name was just taken. Try another.')); }
  }
  return (
    <Card>
      <h1 className="text-center font-nunito text-2xl font-semibold text-[#1C1C1E]">{t('הפרופיל העירוני שלכם מוכן 🎉', 'Your Urban Profile is ready 🎉')}</h1>
      <div className="mt-6 flex flex-col items-center text-center">
        <span className="size-24 overflow-hidden rounded-full bg-[#E7ECF7]">
          {me.avatar_url ? <img src={ownPhoto(me.avatar_url, 240) ?? me.avatar_url} alt="" className="size-full object-cover" /> : <span className="flex size-full items-center justify-center"><User size={40} color="#123A72" /></span>}
        </span>
        <p dir="auto" className="mt-3 font-nunito text-xl font-semibold text-navy">{me.name}</p>
        {me.bio && <p dir="auto" className="mt-1 max-w-[380px] text-sm text-[#4F4F4F]">{me.bio}</p>}
        {me.interests.length > 0 && (
          <div className="mt-3 flex flex-wrap justify-center gap-1.5">
            {me.interests.map((k) => { const i = INTERESTS.find((x) => x[0] === k); return i ? <span key={k} className="rounded-full bg-[#F1F6FD] px-2.5 py-1 text-xs text-midblue">{i[1]} {lang === 'he' ? i[2] : i[3]}</span> : null; })}
          </div>
        )}
      </div>
      {missing && (
        <Link href={`/urban-profile/${missing}/`} className="mt-5 block rounded-xl bg-[#FFF8E6] p-3 text-center text-sm text-[#7A5B00]">
          {t('נשאר עוד משהו להשלים — המשיכו מכאן', 'Something is still missing — continue here')}
        </Link>
      )}
      <div className="mt-6 rounded-xl border border-line p-4">
        <p className="text-[13px] font-medium text-[#1C1C1E]">{t('הקישור לפרופיל שלכם', 'Your profile link')}</p>
        {!editing ? (
          <div className="mt-2 flex items-center gap-2">
            <span dir="ltr" className="min-w-0 flex-1 truncate text-sm text-[#3D3D3D]">{link ?? '…'}</span>
            {link && (
              <button type="button" onClick={() => { navigator.clipboard?.writeText(link).then(() => { setCopied(true); setTimeout(() => setCopied(false), 2000); }); }}
                className="flex items-center gap-1 text-sm font-medium text-midblue"><Copy size={16} color="currentColor" />{copied ? t('הקישור הועתק', 'Link copied') : t('העתקת הקישור לפרופיל', 'Copy Profile Link')}</button>
            )}
            <button type="button" onClick={() => { setDraft(me.username ?? ''); setEditing(true); }} className="text-sm font-medium text-[#6D6D6D]">{t('שינוי', 'Change')}</button>
          </div>
        ) : (
          <div className="mt-2 flex items-center gap-2" dir="ltr">
            <span className="text-sm text-[#6D6D6D]">/u/</span>
            <input value={draft} onChange={(e) => setDraft(e.target.value)} className="min-w-0 flex-1 rounded-lg border border-line px-3 py-2 text-sm outline-none focus:border-midblue" />
            <button type="button" onClick={saveName} className="text-sm font-medium text-midblue">{t('שמירה', 'Save')}</button>
            <button type="button" onClick={() => { setEditing(false); setNote(null); }} className="text-sm text-[#6D6D6D]">{t('ביטול', 'Cancel')}</button>
          </div>
        )}
        {note && <p className="mt-2 text-xs text-error">{note}</p>}
        <label className="mt-4 flex items-center justify-between gap-3 border-t border-line pt-4 text-sm text-[#3D3D3D]">
          {t('תושבים אחרים יכולים לראות את הפרופיל העירוני שלי', 'Let other residents see my Urban Profile')}
          <input type="checkbox" checked={me.visibility === 'residents'} onChange={(e) => { setVisible(e.target.checked).then(reload, () => setNote(t('לא ניתן היה לשמור. נסו שוב.', 'Could not save. Please try again.'))); }}
            className="size-5 accent-[#123A72]" />
        </label>
      </div>
      <div className="mt-6 flex flex-col gap-3">
        <Link href={enter} className="flex h-12 items-center justify-center rounded-full bg-midblue text-base font-medium text-white hover:bg-midblue/90">{t('כניסה למודיעין בשבילך', 'Enter Modiin4U')}</Link>
        <Link href="/urban-profile/1/" className="text-center text-sm font-medium text-midblue">{t('עריכת הפרופיל', 'Edit my profile')}</Link>
      </div>
    </Card>
  );
}
