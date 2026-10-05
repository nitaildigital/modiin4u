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

  /// The page did not load — offline, say. The spinner used to turn for ever,
  /// with no × to leave by, since the chat draws its own.
  bool _failed = false;

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
          onWebResourceError: (error) {
            if (error.isForMainFrame != false && mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
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

  void _retry() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    _web.loadRequest(_chatUri);
  }

  @override
  Widget build(BuildContext context) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    // The chat draws its own header (logo, name, ×); until it is there — or
    // when it could not load — this screen gives its own way out.
    return Stack(
      children: [
        if (!_failed) WebViewWidget(controller: _web),
        if (_loading) const Center(child: CircularProgressIndicator(color: _kColor)),
        if (_failed)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF6D6D6D)),
                  const SizedBox(height: 12),
                  Text(
                    he ? 'לא הצלחנו לפתוח את הצ\'אט. בדקו את החיבור לאינטרנט.'
                        : 'The chat could not be opened. Check your internet connection.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF3D3D3D)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _kColor),
                    onPressed: _retry,
                    child: Text(he ? 'נסו שוב' : 'Try again'),
                  ),
                ],
              ),
            ),
          ),
        if (_loading || _failed)
          PositionedDirectional(
            top: 8,
            end: 8,
            child: IconButton(
              tooltip: he ? 'סגירה' : 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
      ],
    );
  }
}
