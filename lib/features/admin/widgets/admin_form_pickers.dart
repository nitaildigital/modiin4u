import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../providers/admin_campaigns_provider.dart';

/// Pickers the commercial sections share — agreements, revenue — so a row
/// points at a real business and a real team member rather than at a name
/// typed into a text box. Those forms used to write `business_name` and
/// `salesperson`, which are not columns, so every save was refused.

/// The database's own message where there is one; the rest as-is. A
/// duplicate is said in Hebrew, since it is the one the client will meet —
/// keys, names and slugs are unique — and the raw text is an English
/// constraint name.
String adminErrorText(Object e) {
  final text = e is PostgrestException ? '${e.code} ${e.message}' : '$e';
  if (text.contains('23505') || text.contains('duplicate key')) {
    return 'כבר קיים פריט עם אותו ערך (שם, מפתח או slug חייבים להיות ייחודיים)';
  }
  return e is PostgrestException ? e.message : '$e';
}

/// A red snackbar saying what failed and why.
void showAdminError(BuildContext context, String what, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$what: ${adminErrorText(e)}',
        style: TextStyle(fontFamily: AppFonts.rubik),
      ),
      backgroundColor: AppColors.error,
    ),
  );
}

InputDecoration _decoration(String label, {String? error}) => InputDecoration(
  labelText: label,
  errorText: error,
  labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
);

/// A business chosen from the list, shown by name.
class AdminBusinessField extends ConsumerWidget {
  final String label;
  final String? businessId;

  /// The name to show before the list has loaded, e.g. from the row's join.
  final String? initialName;
  final ValueChanged<Map<String, dynamic>> onPicked;
  final String? errorText;

  const AdminBusinessField({
    super.key,
    required this.label,
    required this.businessId,
    required this.onPicked,
    this.initialName,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(adminCampaignBusinessOptionsProvider).valueOrNull;
    String? name = initialName;
    if (businessId != null && all != null) {
      for (final b in all) {
        if (b['id'] == businessId) name = b['name'] as String?;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => const _BusinessPickerDialog(),
          );
          if (picked != null) onPicked(picked);
        },
        child: InputDecorator(
          decoration: _decoration(
            label,
            error: errorText,
          ).copyWith(suffixIcon: const Icon(Icons.search, size: 18)),
          child: Text(
            businessId == null ? 'בחירת עסק' : (name ?? '…'),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 13,
              color: businessId == null ? AppColors.grayLight : AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

/// Every business, searchable by name; hands back the chosen row.
class _BusinessPickerDialog extends ConsumerStatefulWidget {
  const _BusinessPickerDialog();

  @override
  ConsumerState<_BusinessPickerDialog> createState() =>
      _BusinessPickerDialogState();
}

class _BusinessPickerDialogState extends ConsumerState<_BusinessPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(adminCampaignBusinessOptionsProvider);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש עסק לפי שם',
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: all.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'לא ניתן לטעון עסקים: ${adminErrorText(e)}',
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    data: (list) {
                      final q = _query.toLowerCase();
                      final shown = q.isEmpty
                          ? list
                          : list
                                .where(
                                  (b) => (b['name'] as String? ?? '')
                                      .toLowerCase()
                                      .contains(q),
                                )
                                .toList();
                      if (shown.isEmpty) {
                        return Center(
                          child: Text(
                            'לא נמצא עסק',
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              color: AppColors.grayText,
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: shown.length,
                        itemBuilder: (_, i) {
                          final b = shown[i];
                          return ListTile(
                            dense: true,
                            title: Text(
                              b['name'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: AppFonts.rubik,
                                fontSize: 13,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, b),
                          );
                        },
                      );
                    },
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

/// A team member for "salesperson" — an `admin_users` id, shown by the name
/// on its profile. Optional.
class AdminSalespersonField extends ConsumerWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const AdminSalespersonField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(adminCampaignSalespeopleProvider).valueOrNull;
    if (team == null) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    String nameOf(Map<String, dynamic> a) {
      final p = a['profiles'] as Map?;
      final name = (p?['full_name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) return name;
      return p?['email'] as String? ?? a['id'] as String;
    }

    final items = <String, String>{
      '': 'ללא',
      for (final a in team)
        if (a['is_active'] == true || a['id'] == value)
          a['id'] as String: nameOf(a),
    };
    if (value != null && !items.containsKey(value)) {
      items[value!] = 'איש צוות שאינו ברשימה';
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value ?? '',
        decoration: _decoration('איש מכירות'),
        items: [
          for (final e in items.entries)
            DropdownMenuItem(
              value: e.key,
              child: Text(
                e.value,
                style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              ),
            ),
        ],
        onChanged: (v) => onChanged((v ?? '').isEmpty ? null : v),
      ),
    );
  }
}

/// A calendar date, stored the way a `date` column takes it: yyyy-mm-dd.
class AdminDateField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;

  const AdminDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  static String format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final shown = value == null || value!.isEmpty ? null : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FormField<String>(
        initialValue: shown,
        validator: (_) => required && shown == null ? 'שדה חובה' : null,
        builder: (state) => InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.tryParse(shown ?? '') ?? now,
              firstDate: DateTime(2020),
              lastDate: DateTime(now.year + 10),
            );
            if (picked != null) {
              onChanged(format(picked));
              state.didChange(format(picked));
            }
          },
          child: InputDecorator(
            decoration: _decoration(label, error: state.errorText).copyWith(
              suffixIcon: shown != null && !required
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      tooltip: 'ניקוי',
                      onPressed: () {
                        onChanged(null);
                        state.didChange(null);
                      },
                    )
                  : const Icon(Icons.calendar_today, size: 16),
            ),
            child: Text(
              shown ?? 'בחירת תאריך',
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 13,
                color: shown == null ? AppColors.grayLight : AppColors.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
