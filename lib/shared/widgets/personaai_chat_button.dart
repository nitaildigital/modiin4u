import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../personaai/personaai_web.dart';

/// The client's PersonaAI chat, opened by the home page's "Ask" button.
///
/// On the website the client's own widget script draws the chat (web/
/// index.html). The app is not a web page and cannot run that script, so it
/// opens the chat page the widget itself loads, inside the app, on a screen
/// of its own. It opened in the phone's browser at first, with Chrome's bar
/// and the personaai.me address, which read as being sent out of the app.
/// Until 5 Oct a floating bubble opened it; the client asked for the "Ask"
/// button instead.
const _kBusinessId = '25ea67c7-94cd-4771-8f71-1d530bc7b2a1';
const _kColor = Color(0xFF5B21E6);

final _chatUri = Uri.parse(
  'https://personaai.me/chat/embed.html'
  '?businessId=$_kBusinessId&color=%235B21E6',
);

/// The home page's "Ask" button: the client's PersonaAI chat.
///
/// On the website the widget's own window opens (its floating bubble is
/// hidden, web/index.html); should the script not have loaded, the chat page
/// opens in a new tab. In the app, the chat's screen.
void openPersonaAiChat(BuildContext context) {
  if (!kIsWeb) {
    showPersonaAiChat(context);
    return;
  }
  if (!openPersonaAiWidget()) {
    launchUrl(_chatUri, webOnlyWindowName: '_blank');
  }
}

/// The chat on a screen of its own, closed with the chat's own × or Back.
///
/// It was a sheet at first, which kept its height when the keyboard opened:
/// the box being typed in and the newest answers went behind the keyboard,
/// and a drag inside it pulled the sheet down instead of scrolling the
/// chat. A full screen shrinks above the keyboard, as a messaging app does,
/// and every gesture goes to the chat.
Future<void> showPersonaAiChat(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(child: _ChatSheet()),
      ),
    ),
  );
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet();

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  late final WebViewController _web;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      // The chat's own × asks its host page to close it (the website's widget
      // listens for 'personaai-close'); in the app the sheet is the host.
      ..addJavaScriptChannel(
        'ModiinChat',
        onMessageReceived: (m) {
          if (m.message == 'close' && mounted) Navigator.of(context).pop();
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // The page is not inside another page here, so it has no host to
            // tell; it is given one that hands 'personaai-close' to the app.
            _web.runJavaScript(
              "(function () {"
              "  function relay(d) {"
              "    if (d && d.type === 'personaai-close') ModiinChat.postMessage('close');"
              "  }"
              "  try { window.parent = { postMessage: relay }; } catch (e) {}"
              "  window.addEventListener('message', function (e) { relay(e.data); });"
              "})();",
            );
            if (mounted) setState(() => _loading = false);
          },
          // The chat stays in the sheet; a link it gives — a business's
          // site, WhatsApp, a phone number — opens where it belongs.
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.host.endsWith('personaai.me') || uri.scheme == 'about') {
              return NavigationDecision.navigate;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(_chatUri);
  }

  @override
  Widget build(BuildContext context) {
    // The chat draws its own header (logo, name, ×).
    return Stack(
      children: [
        WebViewWidget(controller: _web),
        if (_loading) const Center(child: CircularProgressIndicator(color: _kColor)),
      ],
    );
  }
}
