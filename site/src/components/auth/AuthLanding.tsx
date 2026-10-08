'use client';
import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { createClient, type EmailOtpType, type SupabaseClient } from '@supabase/supabase-js';
import { Eye, EyeSlash, Lock1, TickCircle, Warning2 } from 'iconsax-react';
import { SUPABASE_ANON_KEY, SUPABASE_URL } from '@/lib/config';
import type { Lang } from '@/lib/i18n';

// Where the app's e-mails land (auth_confirm_screen.dart,
// auth_callback_screen.dart, web_reset_password_screen.dart). The link
// carries a one-time token; it is spent only here, by this page's code in a
// real browser — a mail provider's link scanner fetches the page without
// running it, so it can no longer use the token up first. A confirmed
// address is told so and sent back to the app (the website has no resident
// accounts, so its session is ended at once); a password-reset link asks for
// the new password, saves it and ends the session too.

type Stage =
  | { kind: 'working' }
  | { kind: 'confirmed' }
  | { kind: 'failed'; recovery: boolean }
  | { kind: 'reset' }
  | { kind: 'changed' };

const OTP_TYPES: EmailOtpType[] = ['recovery', 'email', 'signup', 'invite', 'email_change'];

/** Its own client, which keeps the session the link creates for as long as
 *  the page needs it — the site's shared one keeps none. */
function authClient(): SupabaseClient {
  return createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true, storageKey: 'modiin4u-site-auth' },
  });
}

export function AuthLanding({ lang }: { lang: Lang }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [stage, setStage] = useState<Stage>({ kind: 'working' });
  const client = useRef<SupabaseClient | null>(null);

  useEffect(() => {
    const db = authClient();
    client.current = db;
    let done = false;
    const settle = (s: Stage) => { if (!done) { done = true; setStage(s); } };
    const confirmed = async () => { await db.auth.signOut().catch(() => {}); settle({ kind: 'confirmed' }); };

    const url = new URL(window.location.href);
    const hash = new URLSearchParams(url.hash.replace(/^#/, ''));
    const tokenHash = url.searchParams.get('token_hash');
    const type = (url.searchParams.get('type') ?? hash.get('type') ?? '') as EmailOtpType;
    const recovery = type === 'recovery';

    // A reset link signs the person in; that session must be spent on the
    // new password before anything else.
    const { data: sub } = db.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') settle({ kind: 'reset' });
    });

    (async () => {
      if (tokenHash) {
        // The address the e-mails use now: /auth/confirm?token_hash=…&type=….
        if (!OTP_TYPES.includes(type)) return settle({ kind: 'failed', recovery: false });
        const { error } = await db.auth.verifyOtp({ token_hash: tokenHash, type });
        if (error) return settle({ kind: 'failed', recovery });
        return recovery ? settle({ kind: 'reset' }) : confirmed();
      }
      // An older link: Supabase's own verify step sent the person here with
      // the session in the address, or with the reason it could not.
      if (hash.get('error') || url.searchParams.get('error')) return settle({ kind: 'failed', recovery });
      // Give the session a moment to arrive before deciding anything.
      await new Promise((r) => setTimeout(r, 600));
      const { data } = await db.auth.getSession();
      if (!data.session) return settle({ kind: 'failed', recovery });
      return recovery ? settle({ kind: 'reset' }) : confirmed();
    })();

    return () => sub.subscription.unsubscribe();
  }, []);

  if (stage.kind === 'reset' || stage.kind === 'changed') {
    return <ResetForm lang={lang} client={client.current} done={stage.kind === 'changed'} onDone={() => setStage({ kind: 'changed' })} />;
  }

  const circle = (ok: boolean) => (
    <span className="flex size-[88px] items-center justify-center rounded-full" style={{ background: ok ? '#2ECC711F' : '#E74C3C1A' }}>
      {ok ? <TickCircle size={44} color="#2ECC71" /> : <Warning2 size={44} color="#E74C3C" />}
    </span>
  );

  return (
    <div className="mx-auto flex min-h-[420px] max-w-[420px] flex-col items-center justify-center px-8 py-16 text-center">
      {stage.kind === 'working' && (
        <>
          <span className="size-9 animate-spin rounded-full border-[3px] border-midblue border-t-transparent" aria-hidden />
          <h1 className="mt-6 font-rubik text-base text-[#6D6D6D]">{t('מאמתים את הקישור…', 'Checking the link…')}</h1>
        </>
      )}
      {stage.kind === 'confirmed' && (
        <>
          {circle(true)}
          <h1 className="mt-7 font-rubik text-xl font-semibold leading-[1.4] text-black">
            {t('כתובת האימייל שלכם אומתה. חזרו לאפליקציה והתחברו.', 'Your email address has been confirmed. Go back to the app and sign in.')}
          </h1>
          <Link href="/" className="mt-7 px-3 py-2 text-sm text-midblue">{t('לאתר', 'Go to the website')}</Link>
        </>
      )}
      {stage.kind === 'failed' && (
        <>
          {circle(false)}
          <h1 className="mt-7 font-rubik text-[22px] font-semibold text-black">{t('הקישור אינו בתוקף', 'This link is no longer valid')}</h1>
          <p className="mt-2.5 text-sm leading-[1.55] text-[#6D6D6D]">
            {stage.recovery
              ? t('כל קישור לאיפוס סיסמה פועל פעם אחת בלבד, ובקשה חדשה מבטלת את הקודמת. בקשו קישור חדש והשתמשו בו מההודעה האחרונה שהגיעה.',
                'Each password reset link works only once, and a new request cancels the previous one. Request a new link and use it from the latest message you received.')
              : t('ייתכן שהקישור כבר נוצל או שפג תוקפו. התחברו כדי לבקש קישור חדש.', 'The link may already have been used or has expired. Sign in to request a new one.')}
          </p>
          {/* The website has no sign-in for residents; a new link is asked
              for in the app. */}
          <Link href="/" className="mt-8 flex h-12 w-full items-center justify-center rounded-full bg-midblue text-sm font-medium text-white">{t('חזרה לדף הבית', 'Back to home')}</Link>
        </>
      )}
    </div>
  );
}

/** "New Password": two fields in a card, one eye for both — they are meant
 *  to hold the same value. No current password: the link signed them in,
 *  and the one they forgot is the one being replaced. */
function ResetForm({ lang, client, done, onDone }: { lang: Lang; client: SupabaseClient | null; done: boolean; onDone: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [show, setShow] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (password.length < 8) return setError(t('הסיסמה חייבת להיות באורך 8 תווים לפחות.', 'Password must be at least 8 characters'));
    if (password !== confirm) return setError(t('הסיסמאות אינן תואמות', 'Passwords do not match'));
    if (!client) return;
    setError(null);
    setSaving(true);
    const { error: failed } = await client.auth.updateUser({ password });
    if (failed) {
      setSaving(false);
      return setError(t('לא ניתן היה לשמור. נסו שוב.', 'Could not save. Please try again.'));
    }
    // Residents have no account on the website: the session ends here.
    await client.auth.signOut().catch(() => {});
    onDone();
  }

  const field = (id: string, label: string, hint: string, value: string, set: (v: string) => void) => (
    <div>
      <label htmlFor={id} className="text-sm font-medium text-[#4F4F4F]">{label}</label>
      <div className="relative mt-2.5">
        <input id={id} type={show ? 'text' : 'password'} value={value} onChange={(e) => set(e.target.value)} placeholder={hint} autoComplete="new-password"
          className="h-[50px] w-full rounded-[10px] border border-[#C6C6C6] bg-white pe-12 ps-4 text-sm font-medium text-[#1F1F1F] outline-none placeholder:text-[#6D6D6D] focus:border-[1.5px] focus:border-midblue" />
        <button type="button" onClick={() => setShow(!show)} aria-label={show ? t('הסתרת הסיסמה', 'Hide password') : t('הצגת הסיסמה', 'Show password')}
          className="absolute end-3 top-1/2 -translate-y-1/2 p-1">
          {show ? <Eye size={20} color="#6D6D6D" /> : <EyeSlash size={20} color="#6D6D6D" />}
        </button>
      </div>
    </div>
  );

  return (
    <div className="mx-auto max-w-[520px] py-10 desk:py-14">
      <div className="rounded-[20px] border border-line bg-white p-6 shadow-[0_6px_24px_rgba(0,0,0,0.06)] desk:p-10">
        <span className="flex size-[72px] items-center justify-center rounded-full bg-midblue/[0.08]">
          {done ? <TickCircle size={32} color="#2ECC71" /> : <Lock1 size={32} color="#123A72" />}
        </span>
        <h1 className="mt-6 font-nunito text-[32px] font-semibold leading-[1.2] text-[#1C1C1E]">
          {done ? t('הסיסמה שלכם שונתה.', 'Your password has been changed.') : t('סיסמה חדשה', 'New Password')}
        </h1>
        {done ? (
          <Link href="/" className="mt-8 flex h-[50px] w-full items-center justify-center rounded-full bg-midblue text-base font-medium text-white">{t('חזרה לדף הבית', 'Back to home')}</Link>
        ) : (
          <form onSubmit={submit} noValidate>
            <p className="mt-2 text-sm leading-[1.45] text-[#6D6D6D]">{t('בחרו סיסמה חזקה באורך 8 תווים לפחות.', 'Choose a strong password of at least 8 characters.')}</p>
            <div className="mt-8 flex flex-col gap-5">
              {field('pw', t('סיסמה חדשה', 'New Password'), t('הזינו סיסמה חדשה', 'Enter a new password'), password, setPassword)}
              {field('pw2', t('אימות סיסמה חדשה', 'Confirm New Password'), t('הזינו שוב את הסיסמה החדשה', 'Re-enter the new password'), confirm, setConfirm)}
            </div>
            {error && <p role="alert" className="mt-4 rounded-xl bg-[#E74C3C1A] px-4 py-3 text-sm text-[#C0392B]">{error}</p>}
            <button type="submit" disabled={saving}
              className="mt-8 flex h-[50px] w-full items-center justify-center rounded-full bg-midblue text-base font-medium text-white disabled:bg-midblue/60">
              {saving ? <span className="size-[22px] animate-spin rounded-full border-[2.5px] border-white border-t-transparent" /> : t('שינוי סיסמה', 'Change password')}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
