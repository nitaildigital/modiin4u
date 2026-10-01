import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/step_group.dart';
import '../repositories/step_groups_repository.dart';

final stepGroupsRepositoryProvider = Provider<StepGroupsRepository>(
  (ref) => StepGroupsRepository(),
);

/// The signed-in person's groups; empty when signed out.
final myStepGroupsProvider = FutureProvider<List<StepGroupSummary>>((
  ref,
) async {
  if (ref.watch(authProvider) == null) return const [];
  return ref.watch(stepGroupsRepositoryProvider).myGroups();
});

final stepGroupProvider = FutureProvider.family<StepGroup?, String>((
  ref,
  id,
) async {
  if (ref.watch(authProvider) == null) return null;
  return ref.watch(stepGroupsRepositoryProvider).group(id);
});

final stepGroupStatsProvider = FutureProvider.family<List<GroupMember>, String>(
  (ref, id) async {
    if (ref.watch(authProvider) == null) return const [];
    return ref.watch(stepGroupsRepositoryProvider).stats(id);
  },
);

/// What an invitation code leads to. Watches the account so that signing
/// in from the join screen re-reads "already a member".
final groupPreviewProvider = FutureProvider.family<GroupPreview?, String>((
  ref,
  code,
) async {
  ref.watch(authProvider);
  return ref.watch(stepGroupsRepositoryProvider).preview(code);
});

/// Where invitation links point: Remote Config `site_url` when the client
/// has set it in the panel, otherwise the site's domain.
///
/// A setting rather than a constant because the address changes once:
/// until app.modiin4u.co.il has its record, links go to the server's interim
/// secure address (https://45-93-94-49.sslip.io), and when the domain is
/// live one edit in the panel moves every installed app's invitations to
/// it. Both are in the app's link configuration (AndroidManifest.xml,
/// Runner.entitlements), so either opens the app.
const kDefaultSiteUrl = 'https://app.modiin4u.co.il';

final siteUrlProvider = FutureProvider<String>((ref) async {
  try {
    final row = await SupabaseConfig.client
        .from('remote_config')
        .select('value')
        .eq('key', 'site_url')
        .maybeSingle();
    final set = (row?['value'] as String? ?? '').trim();
    if (set.startsWith('https://')) {
      return set.endsWith('/') ? set.substring(0, set.length - 1) : set;
    }
  } catch (_) {
    // Unreadable setting: the domain.
  }
  return kDefaultSiteUrl;
});

/// Invitation codes are eight characters from an alphabet without 0/O and
/// 1/I/L (00041). What someone types is upper-cased and stripped of spaces
/// and dashes before it is sent.
String normalizeInviteCode(String raw) =>
    raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
