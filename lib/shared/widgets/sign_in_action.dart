import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';

/// "Sign in" on a "sign in to …" message, back to this page afterwards.
///
/// The messages said what to do and offered no way to do it. In the app
/// only: on the website accounts are the app's and `/login` is the panel's.
SnackBarAction? signInAction(BuildContext context) {
  if (kIsWeb) return null;
  var next = '/';
  try {
    next = GoRouterState.of(context).uri.toString();
  } catch (_) {}
  return SnackBarAction(
    label: L.of(context).signIn,
    textColor: Colors.white,
    onPressed: () => context.push('/login?next=${Uri.encodeComponent(next)}'),
  );
}
