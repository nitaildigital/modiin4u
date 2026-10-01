import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/step_group.dart';

/// Step groups (migration 00041).
///
/// Every change is a database function that checks who is asking — a
/// resident cannot write the tables directly — and other members' steps
/// come only through `step_group_stats`, which first checks membership.
class StepGroupsRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<StepGroupSummary>> myGroups() async {
    final rows = await _client.rpc('my_step_groups');
    return List<Map<String, dynamic>>.from(
      rows ?? const [],
    ).map(StepGroupSummary.fromJson).toList();
  }

  Future<StepGroup?> group(String id) async {
    final row = await _client
        .from('step_groups')
        .select('id, name, invite_code')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : StepGroup.fromJson(row);
  }

  Future<List<GroupMember>> stats(String id) async {
    final rows = await _client.rpc(
      'step_group_stats',
      params: {'p_group': id},
    );
    return List<Map<String, dynamic>>.from(
      rows ?? const [],
    ).map(GroupMember.fromJson).toList();
  }

  /// Null when the code matches no group (mistyped, replaced, or hidden by
  /// the panel).
  Future<GroupPreview?> preview(String code) async {
    final rows = await _client.rpc(
      'step_group_preview',
      params: {'p_code': code},
    );
    final list = List<Map<String, dynamic>>.from(rows ?? const []);
    return list.isEmpty ? null : GroupPreview.fromJson(list.first);
  }

  /// The new group's id.
  Future<String> create(String name) async =>
      await _client.rpc('create_step_group', params: {'p_name': name})
          as String;

  /// The group's id.
  Future<String> join(String code) async =>
      await _client.rpc('join_step_group', params: {'p_code': code}) as String;

  Future<void> leave(String id) =>
      _client.rpc('leave_step_group', params: {'p_group': id});

  Future<void> removeMember(String id, String profileId) => _client.rpc(
    'remove_step_group_member',
    params: {'p_group': id, 'p_profile': profileId},
  );

  Future<void> rename(String id, String name) => _client.rpc(
    'rename_step_group',
    params: {'p_group': id, 'p_name': name},
  );

  /// The new code; links with the old one stop working.
  Future<String> resetCode(String id) async =>
      await _client.rpc('reset_step_group_code', params: {'p_group': id})
          as String;

  Future<void> delete(String id) =>
      _client.rpc('delete_step_group', params: {'p_group': id});
}
