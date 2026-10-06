import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// The step competition's prize, as the panel words it, in the page's
/// language; null when the challenge has none.
String? challengePrize(Map<String, dynamic> c, bool hebrew) {
  String? clean(Object? v) => (v as String?)?.trim().isEmpty ?? true ? null : (v as String).trim();
  final he = clean(c['prize']);
  final en = clean(c['prize_en']);
  return hebrew ? (he ?? en) : (en ?? he);
}

String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// The competition banner on the steps pages (client, 5 Oct, point 13): the
/// prize, how to win it, until when — and, once the database has named the
/// first to reach the goal (00058), who won. Shown only when the challenge
/// has a prize; the progress card under it is unchanged.
class ChallengePrizeBanner extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool hebrew;
  final String? myId;

  /// Opens the win message again, for the winner.
  final VoidCallback? onShowWin;

  const ChallengePrizeBanner({
    super.key,
    required this.challenge,
    required this.hebrew,
    this.myId,
    this.onShowWin,
  });

  @override
  Widget build(BuildContext context) {
    final prize = challengePrize(challenge, hebrew);
    if (prize == null) return const SizedBox.shrink();
    String t(String en, String he) => hebrew ? he : en;

    final goal = (challenge['goal'] as num?)?.toInt() ?? 0;
    final perDay = challenge['goal_per_day'] == true;
    // The last day as Israel's calendar has it: the panel saves the end at
    // 23:59 there, which a phone set to a zone further east read as the next
    // day ("Until 1.11" for a competition ending on the 31st). Israel is
    // UTC+2 or +3; +2 keeps 23:59 on its own day either way.
    final end = DateTime.tryParse(challenge['end_at'] as String? ?? '')
        ?.toUtc()
        .add(const Duration(hours: 2));
    final winner = (challenge['winner_name'] as String?)?.trim();
    final iWon = myId != null && challenge['winner_id'] == myId;

    final rule = perDay
        ? t('The first to walk ${_thousands(goal)} steps in one day wins',
            'הראשון שהולך ${_thousands(goal)} צעדים ביום אחד זוכה')
        : t('The first to reach ${_thousands(goal)} steps wins',
            'הראשון שמגיע ל-${_thousands(goal)} צעדים זוכה');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xFF0A1230), Color(0xFF123A72)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 10, 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('STEP COMPETITION', 'תחרות צעדים'),
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: const Color(0xFFFFC107),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('Win $prize', 'זכו ב$prize'),
                    style: TextStyle(
                      fontFamily: AppFonts.nunito,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rule,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: Colors.white.withValues(alpha: 0.85), height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  if (winner != null && winner.isNotEmpty)
                    _Pill(
                      text: iWon ? t('🏆 You won!', '🏆 זכית!') : t('🏆 Won by $winner', '🏆 הזוכה: $winner'),
                      onTap: iWon ? onShowWin : null,
                    )
                  else if (end != null)
                    _Pill(text: t('Until ${end.day}.${end.month}.${end.year}', 'עד ${end.day}.${end.month}.${end.year}')),
                ],
              ),
            ),
            SizedBox(
              width: 96,
              height: 96,
              child: Lottie.asset('assets/lottie/trophy.json', repeat: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _Pill({required this.text, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        text,
        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0A1230)),
      ),
    ),
  );
}

final _asked = <String>{};

/// The win message, with confetti falling over it. [force] shows it again
/// (the banner's "You won!"); otherwise once per challenge on this device.
Future<void> showChallengeWin(
  BuildContext context,
  Map<String, dynamic> challenge, {
  required bool hebrew,
  bool force = false,
}) async {
  final key = 'challenge_win_seen_${challenge['id']}';
  // Two listeners can ask in the same moment; only the first goes on.
  if (!force && !_asked.add(key)) return;
  if (!force) {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
    } catch (_) {}
  }
  if (!context.mounted) return;
  String t(String en, String he) => hebrew ? he : en;
  final prize = challengePrize(challenge, hebrew);
  final steps = (challenge['won_steps'] as num?)?.toInt();
  final name = (challenge['name'] as String?)?.trim() ?? '';

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: t('Close', 'סגירה'),
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (_, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
      child: child,
    ),
    pageBuilder: (dialog, _, _) => Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 150, height: 150, child: Lottie.asset('assets/lottie/trophy.json')),
                      Text(
                        t('You won!', 'זכית!'),
                        style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.midBlue),
                      ),
                      const SizedBox(height: 8),
                      if (prize != null) ...[
                        Text(t('Your prize', 'הפרס שלך'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: const Color(0xFF6D6D6D))),
                        const SizedBox(height: 4),
                        Text(
                          prize,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: AppFonts.nunito, fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFFE0A100)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        [
                          name,
                          if (steps != null) t('${_thousands(steps)} steps', '${_thousands(steps)} צעדים'),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: const Color(0xFF3D3D3D), height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.midBlue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
                          ),
                          onPressed: () => Navigator.of(dialog).pop(),
                          child: Text(t('Great!', 'מעולה!'), style: TextStyle(fontFamily: AppFonts.inter, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Over the card and under nothing: the confetti does not take taps.
        Positioned.fill(
          child: IgnorePointer(
            child: Lottie.asset('assets/lottie/confetti.json', fit: BoxFit.cover, repeat: false),
          ),
        ),
      ],
    ),
  );
}
