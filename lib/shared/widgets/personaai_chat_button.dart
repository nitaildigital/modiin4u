import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The client's PersonaAI chat, in the app.
///
/// On the website the client's own widget script draws the chat bubble
/// (web/index.html). The app is not a web page and cannot run that script,
/// so it draws the same bubble — the logo in his colour, bottom right — and
/// opens the chat page the widget itself loads, in the in-app browser.
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
        onTap: () => launchUrl(_chatUri, mode: LaunchMode.inAppBrowserView),
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
