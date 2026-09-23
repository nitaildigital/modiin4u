/// The three families the app ships, declared in `pubspec.yaml` and bundled
/// under `assets/google_fonts/`.
///
/// Styles are built with `TextStyle(fontFamily: ...)` rather than through the
/// `google_fonts` package: the package resolves the family and constructs a
/// style on every call, and those calls sit inside `build` methods that run on
/// every frame.
abstract final class AppFonts {
  static const rubik = 'Rubik';
  static const inter = 'Inter';
  static const nunito = 'Nunito';
}
