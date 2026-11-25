'use client';
import { useEffect } from 'react';
import { useConsent } from '@/lib/consent';

const ORIGIN = 'https://personaai.me';

/** The chat page the PersonaAI widget itself loads, for when its script has
 *  not (personaai_chat_button.dart). */
const CHAT_PAGE = `${ORIGIN}/chat/embed.html?businessId=25ea67c7-94cd-4771-8f71-1d530bc7b2a1&color=%235B21E6`;

type Persona = { open?: () => void };
const persona = () => (window as unknown as { PersonaAI?: Persona }).PersonaAI;

/** The widget's script, fetched on the first "Ask" rather than on every
 *  page: it keeps the visitor's visit details in the browser, which waits
 *  for them to ask (the cookie notice, 23 Oct). Its settings are set by the
 *  layout. */
let loading: Promise<boolean> | null = null;
function loadWidget(): Promise<boolean> {
  loading ??= new Promise((resolve) => {
    const s = document.createElement('script');
    s.src = `${ORIGIN}/widget.js`;
    s.async = true;
    s.onerror = () => { loading = null; resolve(false); };
    s.onload = () => {
      // The script starts itself; wait the moment it takes to be ready.
      let tries = 0;
      const ready = () => {
        if (typeof persona()?.open === 'function') resolve(true);
        else if (++tries > 40) resolve(false);
        else setTimeout(ready, 100);
      };
      ready();
    };
    document.body.appendChild(s);
  });
  return loading;
}

/** The chat, loaded ahead of the first "Ask" for a visitor who accepted
 *  marketing cookies. PersonaAI's chat is heavy (on 25 Nov one of its files
 *  was 4.6 MB, from one server in Tel Aviv), and loaded only on "Ask" it
 *  could show its grey placeholder for up to a minute. The widget builds its
 *  chat window, hidden, as soon as its script runs, so loading the script
 *  once the page has settled has the chat ready by the time someone asks;
 *  that is how the widget is meant to be installed. It waits for marketing
 *  consent because the script keeps, for 30 days, where the visitor came
 *  from (ad tags, the referring site), which is what the cookie notice asks
 *  about (23 Oct). Without that consent the first "Ask" loads it, as before. */
export function ChatPreload() {
  const allowed = useConsent()?.marketing === true;
  useEffect(() => {
    if (!allowed) return;
    let cancel = () => {};
    // After the page's own loading, so the chat never competes with it.
    const start = () => {
      // Safari has no requestIdleCallback.
      if (typeof window.requestIdleCallback === 'function') {
        const id = window.requestIdleCallback(() => void loadWidget(), { timeout: 5000 });
        cancel = () => window.cancelIdleCallback(id);
      } else {
        const id = window.setTimeout(() => void loadWidget(), 2000);
        cancel = () => window.clearTimeout(id);
      }
    };
    if (document.readyState === 'complete') start();
    else {
      window.addEventListener('load', start, { once: true });
      cancel = () => window.removeEventListener('load', start);
    }
    return () => cancel();
  }, [allowed]);
  return null;
}

/** A pointer, a finger or the keyboard on "Ask": the connection to PersonaAI
 *  is opened then, so the script that the tap loads arrives sooner. Only a
 *  connection: nothing is stored until the visitor asks. */
let warmed = false;
function warmUp() {
  if (warmed) return;
  warmed = true;
  const l = document.createElement('link');
  l.rel = 'preconnect';
  l.href = ORIGIN;
  document.head.appendChild(l);
}

/** Opens the client's PersonaAI chat — the widget's own window, its bubble
 *  being hidden (globals.css); or, should the script not load, the chat page
 *  in a new tab. */
export async function openChat() {
  if (typeof persona()?.open === 'function') return persona()!.open!();
  if (await loadWidget()) persona()!.open!();
  else window.open(CHAT_PAGE, '_blank', 'noopener');
}

/** "Ask" — the client's choice (5 Oct) in place of the widget's bubble. */
export function AskButton({ label, className = '', iconClassName = '' }: { label: string; className?: string; iconClassName?: string }) {
  return (
    <button type="button" onClick={openChat} onPointerEnter={warmUp} onTouchStart={warmUp} onFocus={warmUp} className={className}>
      <span className="flex size-6 shrink-0 items-center justify-center">
        <img src="/web/home/ai.svg" alt="" width={17.45} height={21} className={iconClassName} />
      </span>
      {label}
    </button>
  );
}

/** Anything that opens the chat when tapped — the phone's search bar. */
export function AskArea({ children, className = '', label }: { children: React.ReactNode; className?: string; label: string }) {
  return (
    <button type="button" onClick={openChat} onPointerEnter={warmUp} onTouchStart={warmUp} onFocus={warmUp} className={className} aria-label={label}>
      {children}
    </button>
  );
}
