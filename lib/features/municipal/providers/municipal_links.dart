import 'package:url_launcher/url_launcher.dart';

import '../../../core/supabase/supabase_config.dart';

/// The municipality's own forms page — "טפסים, הנחיות, חוקים ותקנות": every
/// department's forms and guidelines, kept current by the city. The Forms
/// tile opens it, as the client chose (30 Sep), rather than a list of forms
/// copied into the app that would go stale.
const kMunicipalFormsUrl =
    'https://www.modiin.muni.il/modiinwebsite/ChannelArticle.aspx?PageID=51_108';

/// Opens [fallback] — or the link the client has set in the panel under
/// Remote Config `municipal_forms_url`, which wins when present — outside
/// the app. Read on tap, so the tile needs nothing loaded to be shown.
Future<void> openMunicipalLink(String fallback) async {
  var url = fallback;
  try {
    final row = await SupabaseConfig.client
        .from('remote_config')
        .select('value')
        .eq('key', 'municipal_forms_url')
        .maybeSingle();
    final set = (row?['value'] as String? ?? '').trim();
    if (set.startsWith('http')) url = set;
  } catch (_) {
    // Unreadable setting: the municipality's own page, which is the default.
  }
  // In the app's own browser sheet (a Chrome custom tab, Safari's view on
  // an iPhone): the page stays over the app, with a close button, and the
  // municipality's uploads and payments still work. A new tab on the web.
  await launchUrl(Uri.parse(url), mode: LaunchMode.inAppBrowserView);
}
