'use client';

/** The chat page the PersonaAI widget itself loads, for when its script has
 *  not (personaai_chat_button.dart). */
const CHAT_PAGE = 'https://personaai.me/chat/embed.html?businessId=25ea67c7-94cd-4771-8f71-1d530bc7b2a1&color=%235B21E6';

/** Opens the client's PersonaAI chat — the widget's own window, its bubble
 *  being hidden (globals.css); or, should the script not have loaded, the
 *  chat page in a new tab. */
export function openChat() {
  const persona = (window as unknown as { PersonaAI?: { open?: () => void } }).PersonaAI;
  if (persona && typeof persona.open === 'function') persona.open();
  else window.open(CHAT_PAGE, '_blank', 'noopener');
}

/** "Ask" — the client's choice (5 Oct) in place of the widget's bubble. */
export function AskButton({ label, className = '', iconClassName = '' }: { label: string; className?: string; iconClassName?: string }) {
  return (
    <button type="button" onClick={openChat} className={className}>
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
    <button type="button" onClick={openChat} className={className} aria-label={label}>
      {children}
    </button>
  );
}
