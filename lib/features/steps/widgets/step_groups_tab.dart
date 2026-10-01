import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_group.dart';
import '../providers/step_groups_providers.dart';

/// 6842 -> "6,842".
String formatSteps(int n) {
  final digits = n.toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

/// What a group function's refusal means to the person, in their language.
String groupErrorText(L l, Object e) {
  final message = e is PostgrestException ? e.message : '$e';
  if (message.contains('group is full')) return l.sgGroupFull;
  if (message.contains('too many groups')) return l.sgTooManyGroups;
  if (message.contains('no such group')) return l.sgInviteInvalid;
  return l.somethingWentWrong;
}

const _border = Color(0xFFE7E7E7);
const _muted = Color(0xFF6D6D6D);
const _blue = Color(0xFF216AD0);

/// The Step Counter's Groups tab: the person's groups, and the two ways in —
/// creating one, or joining one with a code someone sent.
///
/// The app has accounts, the website does not, so this tab exists only in
/// the app; signed out it says what signing in gives.
class StepGroupsTab extends ConsumerWidget {
  const StepGroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    if (ref.watch(authProvider) == null) {
      return _SignedOut(l: l);
    }
    final groups = ref.watch(myStepGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: l.sgCreateGroup,
                icon: IconsaxPlusLinear.add,
                filled: true,
                onTap: () => _create(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: l.sgJoinWithCode,
                icon: IconsaxPlusLinear.ticket,
                filled: false,
                onTap: () => _joinWithCode(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        groups.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _Note(
            text: l.somethingWentWrong,
            action: l.tryAgain,
            onAction: () => ref.invalidate(myStepGroupsProvider),
          ),
          data: (list) => list.isEmpty
              ? _Note(text: l.sgEmpty)
              : Column(
                  children: [
                    for (final g in list) ...[
                      _GroupCard(group: g),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final l = L.of(context);
    final name = await askText(
      context,
      title: l.sgCreateGroup,
      hint: l.sgGroupName,
      action: l.sgCreate,
      maxLength: 40,
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    try {
      final id = await ref.read(stepGroupsRepositoryProvider).create(name);
      ref.invalidate(myStepGroupsProvider);
      if (context.mounted) context.push('/steps/groups/$id?invite=1');
    } catch (e) {
      if (context.mounted) showGroupError(context, groupErrorText(l, e));
    }
  }

  Future<void> _joinWithCode(BuildContext context) async {
    final l = L.of(context);
    final raw = await askText(
      context,
      title: l.sgJoinWithCode,
      hint: l.sgInviteCode,
      action: l.sgContinue,
      maxLength: 12,
      code: true,
    );
    if (raw == null || !context.mounted) return;
    final code = normalizeInviteCode(raw);
    if (code.isEmpty) return;
    context.push('/join/$code');
  }
}

void showGroupError(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// A one-field dialog — a group's name, an invitation code. Null when
/// cancelled.
Future<String?> askText(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  String initial = '',
  int maxLength = 40,
  bool code = false,
}) {
  final l = L.of(context);
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: maxLength,
        textCapitalization:
            code ? TextCapitalization.characters : TextCapitalization.sentences,
        // A code is Latin letters and digits whatever the keyboard's
        // language; written left to right even in Hebrew.
        textDirection: code ? TextDirection.ltr : null,
        textAlign: code ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: code ? 20 : 15,
          letterSpacing: code ? 3 : 0,
        ),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.midBlue),
          ),
        ),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.cancel, style: const TextStyle(color: _muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.midBlue),
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: Text(action),
        ),
      ],
    ),
  );
}

/// A yes/no question before something that cannot be taken back.
Future<bool> confirmGroupAction(
  BuildContext context, {
  required String title,
  String? body,
  required String action,
  bool destructive = false,
}) async {
  final l = L.of(context);
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),
      content: body == null
          ? null
          : Text(
              body,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 14,
                color: const Color(0xFF3D3D3D),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.cancel, style: const TextStyle(color: _muted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.error : AppColors.midBlue,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(action),
        ),
      ],
    ),
  );
  return yes ?? false;
}

class _SignedOut extends StatelessWidget {
  final L l;
  const _SignedOut({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(IconsaxPlusLinear.people, size: 36, color: _blue),
          const SizedBox(height: 12),
          Text(
            l.sgSignInPrompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: const Color(0xFF3D3D3D),
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: l.signIn,
            icon: IconsaxPlusLinear.login,
            filled: true,
            onTap: () => context.push(
              '/login?next=${Uri.encodeComponent('/steps?tab=groups')}',
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final StepGroupSummary group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/steps/groups/${group.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7ECF7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  IconsaxPlusLinear.people,
                  color: AppColors.midBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.inter,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        if (group.isOwner) ...[
                          const SizedBox(width: 6),
                          OwnerTag(label: l.sgOwner),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.sgMembers(group.memberCount)} · '
                      '${l.sgStepsToday(formatSteps(group.todayTotal))}',
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: _muted,
                      ),
                    ),
                    if (group.myRank != null && group.memberCount > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        l.sgMyRankToday(group.myRank!),
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.midBlue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Material's chevron turns to face the reading direction.
              const Icon(Icons.chevron_right, size: 22, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small label beside a member: the owner (amber), or "you" (blue).
class OwnerTag extends StatelessWidget {
  final String label;
  final bool me;
  const OwnerTag({super.key, required this.label, this.me = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: me ? const Color(0xFFE7ECF7) : const Color(0xFFFFF4E0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.inter,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: me ? AppColors.midBlue : const Color(0xFFB26A00),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? Colors.white : AppColors.midBlue;
    return Material(
      color: filled ? AppColors.midBlue : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: AppColors.midBlue),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;
  const _Note({required this.text, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 14,
              color: _muted,
            ),
          ),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
