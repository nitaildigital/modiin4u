// Opens the client's PersonaAI chat on the website from our own button.
//
// The widget's script (web/index.html) puts `window.PersonaAI.open()` on the
// page once it has loaded. Since 5 Oct its floating bubble is hidden and the
// home page's "Ask" button opens the chat instead (the client's request), so
// this is the only way in. False until the script has loaded, so the caller
// can fall back.
export 'personaai_web_stub.dart'
    if (dart.library.js_interop) 'personaai_web_impl.dart';
