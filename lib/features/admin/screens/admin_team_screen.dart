import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_team_provider.dart';

class AdminTeamScreen extends ConsumerStatefulWidget {
  const AdminTeamScreen({super.key});
  @override
  ConsumerState<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends ConsumerState<AdminTeamScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminTeamProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Toolbar ───
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
        child: Row(children: [
          SizedBox(
            width: isWide ? 280 : 180, height: 40,
            child: TextField(
              controller: _searchController, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש חבר צוות...', hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => ref.read(adminTeamProvider.notifier).setSearch(v.isEmpty ? null : v),
            ),
          ),
          const Spacer(),
          asyncData.whenData((l) => Text('${l.length} חברי צוות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _showEditor(context, null),
            icon: const Icon(Icons.person_add, size: 18),
            label: Text('הוספת חבר צוות', style: GoogleFonts.rubik(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.turquoise, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
      ),

      // ─── Cards Grid ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.group_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין חברי צוות', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 3 : 1, childAspectRatio: isWide ? 2.2 : 3.5, crossAxisSpacing: 16, mainAxisSpacing: 16,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => _TeamCard(member: list[i], onEdit: () => _showEditor(context, list[i]), onToggle: () => ref.read(adminTeamProvider.notifier).toggleActive(list[i]['id'] as String)),
            );
          },
        ),
      ),
    ]);
  }

  void _showEditor(BuildContext context, Map<String, dynamic>? existing) {
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final emailC = TextEditingController(text: existing?['email'] ?? '');
    String role = existing?['role'] as String? ?? 'editor';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(existing == null ? 'הוספת חבר צוות' : 'עריכת חבר צוות', style: GoogleFonts.rubik(fontWeight: FontWeight.w700, color: AppColors.navy)),
          content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(labelText: 'שם מלא', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            const SizedBox(height: 14),
            TextField(controller: emailC, style: GoogleFonts.rubik(fontSize: 14),
              decoration: InputDecoration(labelText: 'אימייל', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10))),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: role,
              style: GoogleFonts.rubik(fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(labelText: 'תפקיד', labelStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              items: [
                DropdownMenuItem(value: 'super_admin', child: Text('סופר אדמין', style: GoogleFonts.rubik())),
                DropdownMenuItem(value: 'admin', child: Text('אדמין', style: GoogleFonts.rubik())),
                DropdownMenuItem(value: 'editor', child: Text('עורך', style: GoogleFonts.rubik())),
                DropdownMenuItem(value: 'moderator', child: Text('מנהל תוכן', style: GoogleFonts.rubik())),
                DropdownMenuItem(value: 'sales', child: Text('מכירות', style: GoogleFonts.rubik())),
                DropdownMenuItem(value: 'viewer', child: Text('צופה', style: GoogleFonts.rubik())),
              ],
              onChanged: (v) => setD(() => role = v!),
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ביטול', style: GoogleFonts.rubik(color: AppColors.grayText))),
            ElevatedButton(
              onPressed: () {
                final data = {'name': nameC.text, 'email': emailC.text, 'role': role};
                if (existing != null) {
                  ref.read(adminTeamProvider.notifier).updateUser(existing['id'] as String, data);
                } else {
                  ref.read(adminTeamProvider.notifier).createUser({...data, 'is_active': true});
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.turquoise, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(existing == null ? 'הוסף' : 'שמור', style: GoogleFonts.rubik()),
            ),
          ],
        ),
      )),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onEdit, onToggle;
  const _TeamCard({required this.member, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isActive = member['is_active'] as bool? ?? true;
    final role = member['role'] as String? ?? 'editor';
    final name = member['name'] as String? ?? '';
    final email = member['email'] as String? ?? '';

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      elevation: 1,
      child: InkWell(
        onTap: onEdit, borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isActive ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 24, backgroundColor: _roleColor(role).withValues(alpha: 0.12),
                child: Text(name.isNotEmpty ? name[0] : '?', style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.w700, color: _roleColor(role)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(name, style: GoogleFonts.rubik(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(email, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _roleColor(role).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(_roleLabel(role), style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(role))),
                ),
              ])),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.turquoise,
              ),
            ]),
          ),
        ),
      ),
    );
  }

  String _roleLabel(String r) => switch (r) { 'super_admin' => 'סופר אדמין', 'admin' => 'אדמין', 'editor' => 'עורך', 'moderator' => 'מנהל תוכן', 'sales' => 'מכירות', 'viewer' => 'צופה', _ => r };
  Color _roleColor(String r) => switch (r) { 'super_admin' => AppColors.error, 'admin' => AppColors.turquoise, 'editor' => AppColors.midBlue, 'moderator' => AppColors.gold, 'sales' => AppColors.success, _ => AppColors.grayLight };
}
