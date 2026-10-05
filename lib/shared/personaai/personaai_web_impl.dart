import 'dart:js_interop';

@JS('PersonaAI')
external _PersonaAI? get _personaAi;

extension type _PersonaAI(JSObject _) implements JSObject {
  external JSFunction? get open;
}

/// Opens the widget's chat window; false when the script has not loaded.
bool openPersonaAiWidget() {
  final open = _personaAi?.open;
  if (open == null) return false;
  open.callAsFunction(_personaAi);
  return true;
}
