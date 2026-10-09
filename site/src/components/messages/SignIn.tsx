'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Eye, EyeSlash, Messages2, TickCircle } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb, useSession } from '@/lib/session';

/** Where to go after signing in: a page of this site only, never another
 *  address someone put in the link. */
function safeNext(raw: string | null): string {
  if (!raw || !raw.startsWith('/') || raw.startsWith('//')) return '/messages/';
  return raw;
}

/** Sign in, for Messages (the app's Login frame, on the site's card). No
 *  sign-up here: accounts are made in the app, where the onboarding is. */
export function SignIn({ lang, stores }: { lang: Lang; stores: { android: string | null; ios: string | null } }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const router = useRouter();
  const { session, ready } = useSession();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [show, setShow] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [resetSent, setResetSent] = useState(false);
  const [next, setNext] = useState('/messages/');

  useEffect(() => {
    setNext(safeNext(new URLSearchParams(window.location.search).get('next')));
  }, []);

  // Already signed in: straight on.
  useEffect(() => {
    if (ready && session) router.replace(next);
  }, [ready, session, next, router]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim() || !password) return setError(t('הזינו אימייל וסיסמה.', 'Enter your e-mail and password.'));
    setBusy(true);
    setError(null);
    const { error: failed } = await sessionDb().auth.signInWithPassword({ email: email.trim(), password });
    setBusy(false);
    if (!failed) return router.replace(next);
    const m = failed.message.toLowerCase();
    if (m.includes('not confirmed')) {
      setError(t('יש לאשר קודם את כתובת האימייל — הקישור נשלח אליכם בהרשמה.', 'Confirm your e-mail address first — the link was sent when you signed up.'));
    } else if (m.includes('invalid')) {
      setError(t('האימייל או הסיסמה שגויים.', 'The e-mail or password is wrong.'));
    } else {
      setError(t('ההתחברות נכשלה. נסו שוב.', 'Signing in failed. Please try again.'));
    }
  }

  async function forgot() {
    if (!email.trim()) return setError(t('הזינו את האימייל, ואז "שכחתי סיסמה".', 'Enter your e-mail, then "Forgot password".'));
    setError(null);
    // The e-mail's link opens /auth/confirm/, which asks for the new
    // password (AuthLanding), as it does for the app.
    const { error: failed } = await sessionDb().auth.resetPasswordForEmail(email.trim());
    if (failed) return setError(t('לא ניתן היה לשלוח. נסו שוב בעוד דקה.', 'Could not send. Try again in a minute.'));
    setResetSent(true);
  }

  return (
    <div className="wrap">
      <div className="mx-auto max-w-[520px] py-10 desk:py-14">
        <div className="rounded-[20px] border border-line bg-white p-6 shadow-[0_6px_24px_rgba(0,0,0,0.06)] desk:p-10">
          <span className="flex size-[72px] items-center justify-center rounded-full bg-midblue/[0.08]">
            <Messages2 size={32} color="#123A72" />
          </span>
          <h1 className="mt-6 font-nunito text-[32px] font-semibold leading-[1.2] text-[#1C1C1E]">{t('התחברות', 'Sign in')}</h1>
          <p className="mt-2 text-sm leading-[1.45] text-[#6D6D6D]">
            {t('התחברו עם החשבון שלכם באפליקציה כדי לקרוא את ההודעות ולענות להן.', 'Sign in with your app account to read and answer your messages.')}
          </p>
          <form onSubmit={submit} noValidate className="mt-8 flex flex-col gap-5">
            <div>
              <label htmlFor="email" className="text-sm font-medium text-[#4F4F4F]">{t('אימייל', 'E-mail')}</label>
              <input id="email" type="email" dir="ltr" value={email} onChange={(e) => setEmail(e.target.value)} autoComplete="email"
                placeholder={t('הזינו את האימייל', 'Enter your e-mail')}
                className="mt-2.5 h-[50px] w-full rounded-[10px] border border-[#C6C6C6] bg-white px-4 text-sm font-medium text-[#1F1F1F] outline-none placeholder:text-[#6D6D6D] focus:border-[1.5px] focus:border-midblue" />
            </div>
            <div>
              <label htmlFor="password" className="text-sm font-medium text-[#4F4F4F]">{t('סיסמה', 'Password')}</label>
              <div className="relative mt-2.5">
                <input id="password" type={show ? 'text' : 'password'} value={password} onChange={(e) => setPassword(e.target.value)} autoComplete="current-password"
                  placeholder={t('הזינו את הסיסמה', 'Enter your password')}
                  className="h-[50px] w-full rounded-[10px] border border-[#C6C6C6] bg-white pe-12 ps-4 text-sm font-medium text-[#1F1F1F] outline-none placeholder:text-[#6D6D6D] focus:border-[1.5px] focus:border-midblue" />
                <button type="button" onClick={() => setShow(!show)} aria-label={show ? t('הסתרת הסיסמה', 'Hide password') : t('הצגת הסיסמה', 'Show password')}
                  className="absolute end-3 top-1/2 -translate-y-1/2 p-1">
                  {show ? <Eye size={20} color="#6D6D6D" /> : <EyeSlash size={20} color="#6D6D6D" />}
                </button>
              </div>
              <button type="button" onClick={forgot} className="mt-2 text-sm font-medium text-midblue hover:underline">
                {t('שכחתי סיסמה', 'Forgot password')}
              </button>
            </div>
            {resetSent && (
              <p role="status" className="flex items-start gap-2 rounded-xl bg-[#2ECC711F] px-4 py-3 text-sm text-[#1E7B45]">
                <TickCircle size={18} color="#1E7B45" className="mt-0.5 shrink-0" />
                {t('שלחנו אליכם קישור לבחירת סיסמה חדשה.', 'We sent you a link to choose a new password.')}
              </p>
            )}
            {error && <p role="alert" className="rounded-xl bg-[#E74C3C1A] px-4 py-3 text-sm text-[#C0392B]">{error}</p>}
            <button type="submit" disabled={busy}
              className="flex h-[50px] w-full items-center justify-center rounded-full bg-midblue text-base font-medium text-white disabled:bg-midblue/60">
              {busy ? <span className="size-[22px] animate-spin rounded-full border-[2.5px] border-white border-t-transparent" /> : t('התחברות', 'Sign in')}
            </button>
          </form>
          <div className="mt-8 border-t border-line pt-6 text-sm text-[#6D6D6D]">
            <p>{t('אין לכם חשבון? ההרשמה באפליקציה:', 'No account? Sign up in the app:')}</p>
            <div className="mt-3 flex flex-wrap gap-3">
              {stores.ios && (
                <a href={stores.ios} target="_blank" rel="noopener" className="flex h-11 items-center gap-2 rounded-full border border-line px-4 font-medium text-ink hover:bg-surface">
                  <img src="/images/apple_logo.svg" alt="" className="size-5" /> App Store
                </a>
              )}
              {stores.android && (
                <a href={stores.android} target="_blank" rel="noopener" className="flex h-11 items-center gap-2 rounded-full border border-line px-4 font-medium text-ink hover:bg-surface">
                  <img src="/images/google_play.svg" alt="" className="size-5" /> Google Play
                </a>
              )}
              {!stores.ios && !stores.android && <Link href="/" className="font-medium text-midblue hover:underline">{t('לדף הבית', 'Home')}</Link>}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
