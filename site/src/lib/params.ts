/** A route parameter as text: Next hands non-ASCII slugs over still
 *  percent-encoded (`%D7%91…`), the database keeps them as typed. */
export function slugParam(s: string): string {
  try { return decodeURIComponent(s); } catch { return s; }
}

export function isUuid(s: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
}

/** "8 October 2026" / "8 באוקטובר 2026" in Israel's time. */
export function formatDate(iso: string | null | undefined, lang: 'he' | 'en', withTime = false): string {
  if (!iso) return '';
  const d = new Date(iso);
  return d.toLocaleString(lang === 'he' ? 'he-IL' : 'en-GB', {
    timeZone: 'Asia/Jerusalem', day: 'numeric', month: 'long', year: 'numeric',
    ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
  });
}
