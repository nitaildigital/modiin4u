import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The client's PersonaAI chat, in the app.
///
/// On the website the client's own widget script draws the chat bubble
/// (web/index.html). The app is not a web page and cannot run that script,
/// so it draws the same bubble — the logo in his colour, bottom right — and
/// opens the chat page the widget itself loads inside the app, in a sheet
/// of its own. It opened in the phone's browser at first, with Chrome's bar
/// and the personaai.me address, which read as being sent out of the app.
const _kBusinessId = '25ea67c7-94cd-4771-8f71-1d530bc7b2a1';
const _kColor = Color(0xFF5B21E6);

final _chatUri = Uri.parse(
  'https://personaai.me/chat/embed.html'
  '?businessId=$_kBusinessId&color=%235B21E6',
);

class PersonaAiChatButton extends StatelessWidget {
  const PersonaAiChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kColor,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: const Color(0x55000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showPersonaAiChat(context),
        // The site's logo in the circle, as the website's bubble shows it.
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

/// The chat in a sheet over the app, nearly full height, closed with the
/// chat's own × or by dragging it down.
Future<void> showPersonaAiChat(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: const _ChatSheet(),
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
    // The chat draws its own header (logo, name, ×); the sheet adds only a
    // handle to drag it down by.
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD0D0D0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: _web),
              if (_loading)
                const Center(child: CircularProgressIndicator(color: _kColor)),
            ],
          ),
        ),
      ],
    );
  }
}
