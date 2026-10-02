import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The panel's own language, Hebrew unless the admin picks English.
///
/// The client asked for a setting in the panel to switch it between Hebrew
/// and English, Hebrew by default. It is separate from the website's
/// language: the panel is the client's tool and keeps its language whatever
/// language the site was last viewed in. The choice is kept on this
/// browser, so each admin sees the panel in the language they chose.
///
/// Every text in the panel is written as `tr('עברית', 'English')`, so the
/// two versions sit side by side in the code and neither can be forgotten.
/// The dashboard rebuilds on [adminEnglish], and with it every section.
final adminEnglish = ValueNotifier<bool>(false);

const _prefsKey = 'admin_language';

/// The text in the panel's language.
String tr(String he, String en) => adminEnglish.value ? en : he;

TextDirection get adminDir =>
    adminEnglish.value ? TextDirection.ltr : TextDirection.rtl;

Locale get adminLocale =>
    adminEnglish.value ? const Locale('en') : const Locale('he');

/// The language last chosen on this browser; Hebrew if none was.
Future<void> loadAdminLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    adminEnglish.value = prefs.getString(_prefsKey) == 'en';
  } catch (_) {
    // Storage blocked: the panel stays in Hebrew.
  }
}

Future<void> setAdminEnglish(bool english) async {
  adminEnglish.value = english;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, english ? 'en' : 'he');
  } catch (_) {}
}
