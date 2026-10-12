/// Searching names typed in Hebrew the way people type them (the client,
/// TestFlight 11 Oct: "the searches don't work well in Hebrew").
///
/// * A space may or may not be in the name: "נאי תאי" finds "נאיתאי", and
///   "פיצה אנג׳ל" finds "פיצה  אנג׳ל". The words are joined by `%`.
/// * Geresh and gershayim are typed several ways — ׳ ' ` and ״ " — so each
///   matches any one character: "אנג'ל" finds "אנג׳ל".
/// * Characters that would break the filter PostgREST reads (`,` `(` `)`)
///   or act as wildcards themselves (`%` `*` `_` `\`) are dropped.

final _dropped = RegExp(r'[,()%*_\\]');
final _quotes = RegExp('[\'`׳"״]');
final _spaces = RegExp(r'\s+');

/// The body of an `ilike` pattern for [query]; put `%` on each side.
String searchPattern(String query) {
  final cleaned = query.replaceAll(_dropped, ' ').replaceAll(_quotes, '_').trim();
  return cleaned.split(_spaces).where((w) => w.isNotEmpty).join('%');
}

/// [text] as compared in memory: lower case, without spaces or quote marks.
String searchKey(String text) =>
    text.toLowerCase().replaceAll(_quotes, '').replaceAll(_spaces, '');
