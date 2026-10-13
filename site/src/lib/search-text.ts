/** Searching names typed in Hebrew the way people type them, as the app does
 *  (shared/search_text.dart; the client, TestFlight 11 Oct: "the searches
 *  don't work well in Hebrew").
 *
 *  - A space may or may not be in the name: "נאי תאי" finds "נאיתאי".
 *  - Geresh and gershayim are typed several ways — ׳ ' ` and ״ " — so
 *    "אנג'ל" finds "אנג׳ל".
 *  - Characters that would break the filter PostgREST reads (`,` `(` `)`)
 *    or act as wildcards themselves (`%` `*` `_` `\`) are dropped. */

const DROPPED = /[,()%*_\\]/g;
const QUOTES = /['`׳"״]/g;
const SPACES = /\s+/g;

/** The body of an `ilike` pattern for [query], to put `%` on each side of:
 *  the words joined by `%`, each quote mark matching any one character. */
export function searchPattern(query: string): string {
  return query.replace(DROPPED, ' ').replace(QUOTES, '_').trim().split(SPACES).filter(Boolean).join('%');
}

/** [text] as compared in memory: lower case, without spaces or quote marks. */
export function searchKey(text: string | null | undefined): string {
  return (text ?? '').toLowerCase().replace(QUOTES, '').replace(SPACES, '');
}

/** The fields a row is found by, each as [searchKey] makes it, kept apart
 *  so that a query does not match across the end of one and the start of
 *  the next. Test it with [matches]. */
export function searchFields(...fields: (string | null | undefined)[]): string {
  return fields.map(searchKey).filter(Boolean).join('|');
}

/** Whether a row whose [searchFields] are [haystack] answers [query]. */
export function matches(haystack: string, query: string): boolean {
  const k = searchKey(query);
  return !k || haystack.includes(k);
}
