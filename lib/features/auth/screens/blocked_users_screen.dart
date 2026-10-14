import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/providers/blocked_users_provider.dart';
import '../widgets/m_account_widgets.dart';

/// Profile → Blocked users: the people this resident blocked from a comment,
/// a review or a reply (block_user.dart), and the way back — the block
/// dialog says it can be undone here. Unblocking shows their writing again;
/// the report the block filed stays with the team.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider).entries.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                MAccountTopBar(title: mTr(context, 'Blocked users', 'משתמשים חסומים')),
                const SizedBox(height: 16),
                Expanded(
                  child: blocked.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              mTr(
                                context,
                                'You have not blocked anyone. To block someone, tap Block under their comment or review.',
                                'לא חסמתם אף אחד. כדי לחסום, הקישו על „חסימה” מתחת לתגובה או לביקורת.',
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14, color: MAccountColors.label),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: blocked.length,
                          separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEDEDED)),
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    blocked[i].value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: MAccountColors.value,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ref.read(blockedUsersProvider.notifier).unblock(blocked[i].key),
                                  child: Text(
                                    mTr(context, 'Unblock', 'ביטול חסימה'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.inter,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.midBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
