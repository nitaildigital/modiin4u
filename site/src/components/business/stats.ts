import { browserDb } from '@/lib/supabase';

/** What can be counted on a business page (00048, business_stats.dart). */
export type BusinessStat = 'view' | 'call' | 'website' | 'whatsapp' | 'directions' | 'share' | 'instagram';

/** The same storage key the Flutter site used (shared_preferences keeps
 *  `flutter.<key>` in localStorage, the value JSON-encoded), so a visitor the
 *  old site already counted stays one visitor. */
const KEY = 'flutter.stats_visitor';

function randomId(): string {
  const a = new Uint8Array(16);
  crypto.getRandomValues(a);
  return Array.from(a, (b) => b.toString(16).padStart(2, '0')).join('');
}

let visitor: string | null = null;
let client: ReturnType<typeof browserDb> | null = null;

/** A random id this browser made for itself, so the panel can tell ten
 *  visits from ten visitors. Nothing about the person. */
function visitorId(): string {
  if (visitor) return visitor;
  try {
    const raw = localStorage.getItem(KEY);
    const saved = raw ? (JSON.parse(raw) as unknown) : null;
    if (typeof saved === 'string' && saved.length >= 8) return (visitor = saved);
    visitor = randomId();
    localStorage.setItem(KEY, JSON.stringify(visitor));
  } catch {
    // Storage the browser will not open: a visitor for this visit only.
    visitor ??= randomId();
  }
  return visitor;
}

/** Counts [stat] for the business through record_business_event, which
 *  anyone may call (a view counts once per visitor per half hour, by the
 *  database). In the background: the button does its job whatever happens. */
export function track(businessId: string, stat: BusinessStat): void {
  // Only the live site counts: before launch every visit is someone testing,
  // and a test visit is a real row in the client's statistics.
  // tool/deploy_site.sh --live builds with NEXT_PUBLIC_RECORD_STATS=1.
  if (process.env.NEXT_PUBLIC_RECORD_STATS !== '1') return;
  try {
    void (client ??= browserDb()).rpc('record_business_event', {
      p_business: businessId, p_kind: stat, p_platform: 'web', p_visitor: visitorId(),
    }).then(() => undefined, () => undefined);
  } catch { /* never fails the page */ }
}

/** Counts a view of an article through record_article_view (00066): once
 *  per visitor per article per half hour, by the database — as the current
 *  site counts it. Only on the live site, as above. */
export function trackArticleView(articleId: string): void {
  if (process.env.NEXT_PUBLIC_RECORD_STATS !== '1') return;
  try {
    void (client ??= browserDb()).rpc('record_article_view', {
      p_article: articleId, p_platform: 'web', p_visitor: visitorId(),
    }).then(() => undefined, () => undefined);
  } catch { /* never fails the page */ }
}
