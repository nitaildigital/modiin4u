/// Which of a row's names the app and the website show: the Hebrew one, or
/// the English one beside it where the panel has filled it in.
///
/// Businesses and categories were Hebrew only, so a reader who chose English
/// got English menus around Hebrew names ("Businesses in Modiin" opening on
/// מסעדות, קפה ומאפה). Since 7 Oct they carry a `name_en` (00062) and their
/// models' `name` reads through [localName]. The models are read in some
/// seventy places; a getter that follows the language keeps every one of them
/// right without passing the language to each. Car parks and municipal places,
/// with few call sites, keep their `displayName(hebrew)`.
///
/// The rule is set once in main.dart and asked each time a name is read: in
/// the app, the app's language; on the website, the language of the layout
/// on screen — the navbar's above 1100 px, the app's below, as the two can
/// differ for a visitor who has not chosen (desktop pages default to
/// English, phone-width ones to Hebrew). Screens rebuild on a language
/// change, and read the name again as they do.
bool Function() _english = () => false;

bool get contentInEnglish => _english();

void setContentLanguage(bool Function() english) => _english = english;

/// [he] in Hebrew, and in English [en] when there is one.
String localName(String he, String? en) {
  final english = en?.trim();
  return contentInEnglish && english != null && english.isNotEmpty ? english : he;
}
