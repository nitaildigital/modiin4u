// The title the page was served with, for the website's tab and for Google.
//
// tool/build_seo_pages.py writes each address its own <title> — the article's
// SEO title, the business's — and Flutter then replaces whatever is there
// with the app's name, so every page would end up called the same thing in
// the version of it Google renders. The app keeps the served title while
// the visitor stays on the page they arrived at (see main.dart).
export 'page_title_stub.dart'
    if (dart.library.js_interop) 'page_title_web.dart';
