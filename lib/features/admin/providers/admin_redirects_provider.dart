import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_table_notifier.dart';

/// The website's redirects (`redirects`, 00010): an old address sent to a new
/// one, as Yoast's redirect manager did on WordPress. The Next.js site reads
/// the active ones (site/src/middleware.ts) and answers with a 301 or 302.
///
/// Removing one is switching it off (`is_active`), never deleting it — the
/// client asked for nothing in the panel to be permanent.
final adminRedirectListProvider =
    StateNotifierProvider<
      AdminRedirectListNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >((ref) => AdminRedirectListNotifier());

class AdminRedirectListNotifier extends AdminTableNotifier {
  AdminRedirectListNotifier()
    : super(
        table: 'redirects',
        searchColumns: const ['old_path', 'new_path'],
        orderBy: 'created_at',
        hasStatus: false,
      );
}

/// The site's own host names: a link to one of them is an address on the
/// site, kept as its path.
const _ownHosts = {'www.modiin4u.co.il', 'modiin4u.co.il'};

/// An address as the redirects table keeps it and the site looks it up:
/// the path only, decoded (Hebrew as letters, not %D7…), starting with a
/// slash and ending with one — the site's addresses all do — unless it
/// names a file. Null when [input] is not an address on the site.
///
/// [keepQuery] keeps a `?…` part, which a destination may carry
/// (`/search-apartments/?kind=sale`); an old address is matched on its path.
String? siteAddress(String input, {bool keepQuery = false}) {
  var t = input.trim();
  if (t.isEmpty) return null;
  final full = RegExp(r'^https?://', caseSensitive: false).hasMatch(t);
  if (full) {
    final u = Uri.tryParse(t);
    if (u == null || !_ownHosts.contains(u.host.toLowerCase())) return null;
    t = u.path + (u.hasQuery ? '?${u.query}' : '');
  }
  if (!t.startsWith('/')) t = '/$t';
  var path = t;
  var query = '';
  final q = t.indexOf('?');
  if (q >= 0) {
    path = t.substring(0, q);
    query = t.substring(q);
  }
  final hash = path.indexOf('#');
  if (hash >= 0) path = path.substring(0, hash);
  try {
    path = Uri.decodeFull(path);
  } catch (_) {
    // Already plain text with a stray %, kept as typed.
  }
  path = path.replaceAll(RegExp(r'/{2,}'), '/');
  final last = path.split('/').last;
  if (!path.endsWith('/') && !last.contains('.')) path = '$path/';
  return keepQuery ? path + query : path;
}

/// A destination: an address on the site (as [siteAddress] keeps it) or a
/// full link elsewhere. Null when it is neither.
String? redirectTarget(String input) {
  final t = input.trim();
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(t)) {
    final u = Uri.tryParse(t);
    if (u == null || u.host.isEmpty) return null;
    return _ownHosts.contains(u.host.toLowerCase())
        ? siteAddress(t, keepQuery: true)
        : t;
  }
  return siteAddress(t, keepQuery: true);
}
