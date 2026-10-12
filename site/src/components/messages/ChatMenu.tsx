'use client';
import { useState } from 'react';
import { Flag, More, Slash } from 'iconsax-react';
import type { Lang } from '@/lib/i18n';
import { sessionDb } from '@/lib/session';

// The app's reasons (report_sheet.dart), the table's own `report_reason`.
const REASONS: [string, string, string][] = [
  ['spam', 'ספאם או פרסום', 'Spam or advertising'],
  ['offensive', 'תוכן פוגעני', 'Offensive content'],
  ['fake', 'מידע כוזב או מטעה', 'False or misleading'],
  ['personal_info', 'מידע אישי של מישהו', "Someone's personal information"],
  ['harassment', 'הטרדה', 'Harassment'],
  ['other', 'אחר', 'Something else'],
];

/** The chat's "⋯": report the conversation to the team, or block it (00080).
 *  Block is not offered while the other side has blocked it — only they can
 *  undo that. */
export function ChatMenu({ lang, conversationId, userId, blockedByMe, blockedByThem, onChanged }: {
  lang: Lang; conversationId: string; userId: string;
  blockedByMe: boolean; blockedByThem: boolean; onChanged: () => void;
}) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [open, setOpen] = useState(false);
  const [reporting, setReporting] = useState(false);

  async function setBlocked(block: boolean) {
    setOpen(false);
    if (block && !window.confirm(t('לחסום את השיחה? אף צד לא יוכל לכתוב בה עד שתבטלו את החסימה. ההודעות נשארות.',
      'Block this conversation? Nobody will be able to write in it until you unblock it. The messages stay.'))) return;
    const { error } = await sessionDb().rpc('set_conversation_blocked', { p_conversation: conversationId, p_blocked: block });
    if (error) window.alert(t('לא ניתן היה לשמור. נסו שוב.', 'Could not save. Please try again.'));
    else onChanged();
  }

  return (
    <div className="relative">
      <button type="button" onClick={() => setOpen(!open)} aria-label={t('עוד', 'More')} aria-expanded={open}
        className="flex size-9 items-center justify-center rounded-full text-[#3D3D3D] hover:bg-surface">
        <More size={22} color="currentColor" />
      </button>
      {open && (
        <div className="absolute end-0 top-10 z-20 w-48 overflow-hidden rounded-xl border border-line bg-white shadow-[0_8px_24px_rgba(0,0,0,0.12)]">
          <button type="button" onClick={() => { setOpen(false); setReporting(true); }}
            className="flex w-full items-center gap-2.5 px-4 py-3 text-start text-sm text-ink hover:bg-surface">
            <Flag size={18} color="currentColor" />{t('דיווח', 'Report')}
          </button>
          {!blockedByThem && (
            <button type="button" onClick={() => setBlocked(!blockedByMe)}
              className={`flex w-full items-center gap-2.5 px-4 py-3 text-start text-sm hover:bg-surface ${blockedByMe ? 'text-ink' : 'text-[#E5484D]'}`}>
              <Slash size={18} color="currentColor" />{blockedByMe ? t('ביטול חסימה', 'Unblock') : t('חסימה', 'Block')}
            </button>
          )}
        </div>
      )}
      {reporting && <ReportDialog lang={lang} conversationId={conversationId} userId={userId} onClose={() => setReporting(false)} />}
    </div>
  );
}

function ReportDialog({ lang, conversationId, userId, onClose }: { lang: Lang; conversationId: string; userId: string; onClose: () => void }) {
  const t = (he: string, en: string) => (lang === 'he' ? he : en);
  const [reason, setReason] = useState<string | null>(null);
  const [details, setDetails] = useState('');
  const [state, setState] = useState<'idle' | 'sending' | 'sent' | 'already' | 'failed'>('idle');

  async function send() {
    if (!reason) return;
    setState('sending');
    const { error } = await sessionDb().from('reports').insert({
      reporter_id: userId, entity_type: 'conversation', entity_id: conversationId, reason,
      ...(details.trim() ? { details: details.trim() } : {}),
    });
    // One report per person per item (00064): a second is "already reported".
    setState(!error ? 'sent' : error.code === '23505' ? 'already' : 'failed');
  }

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center bg-black/40 desk:items-center" role="dialog" aria-modal onClick={onClose}>
      <div className="w-full max-w-md rounded-t-2xl bg-white p-6 desk:rounded-2xl" onClick={(e) => e.stopPropagation()}>
        <h2 className="text-lg font-semibold text-ink">{t('דיווח על השיחה', 'Report this conversation')}</h2>
        {state === 'sent' || state === 'already' ? (
          <>
            <p className="mt-3 text-sm text-[#6D6D6D]">
              {state === 'sent' ? t('תודה. הדיווח נשלח לצוות.', 'Thank you. The report was sent to the team.')
                : t('כבר דיווחת על זה. הדיווח אצל הצוות.', 'You have already reported this. The team has it.')}
            </p>
            <button type="button" onClick={onClose} className="mt-5 h-11 w-full rounded-full bg-midblue font-medium text-white">{t('סגירה', 'Close')}</button>
          </>
        ) : (
          <>
            <p className="mt-1 text-sm text-[#6D6D6D]">{t('מה הבעיה?', "What's wrong?")}</p>
            <ul className="mt-4 flex flex-col gap-2">
              {REASONS.map(([key, he, en]) => (
                <li key={key}>
                  <label className={`flex cursor-pointer items-center gap-3 rounded-xl border px-4 py-3 text-sm ${reason === key ? 'border-midblue bg-midblue/[0.05]' : 'border-line'}`}>
                    <input type="radio" name="reason" checked={reason === key} onChange={() => setReason(key)} className="accent-[#123A72]" />
                    {lang === 'he' ? he : en}
                  </label>
                </li>
              ))}
            </ul>
            <textarea value={details} onChange={(e) => setDetails(e.target.value.slice(0, 500))} rows={2}
              placeholder={t('פרטים נוספים (לא חובה)', 'More details (optional)')}
              className="mt-3 w-full resize-none rounded-xl border border-line px-4 py-3 text-sm outline-none focus:border-midblue" />
            {state === 'failed' && <p role="alert" className="mt-2 text-sm text-[#C0392B]">{t('הדיווח לא נשלח. נסו שוב.', 'The report was not sent. Try again.')}</p>}
            <div className="mt-4 flex gap-3">
              <button type="button" onClick={onClose} className="h-11 flex-1 rounded-full border border-line font-medium text-ink">{t('ביטול', 'Cancel')}</button>
              <button type="button" onClick={send} disabled={!reason || state === 'sending'}
                className="h-11 flex-1 rounded-full bg-midblue font-medium text-white disabled:bg-midblue/40">{t('שליחה', 'Send')}</button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
