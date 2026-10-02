import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../admin_language.dart';

// Form pieces the event and offer editors share: choosing a business, and
// typing a date or a time with a picker beside it.
//
// Both editors used to ask for these as free text — an offer's business was a
// name typed into a box, which the table has no column for, and its required
// `business_id` was never set; an event's date went into a `date` column that
// does not exist. These write the real columns in the form the database
// accepts.

/// One business, as the pickers offer it.
class AdminBusinessOption {
  final String id;
  final String name;
  final String status;
  final String? address;
  final double? latitude;
  final double? longitude;

  const AdminBusinessOption({
    required this.id,
    required this.name,
    required this.status,
    this.address,
    this.latitude,
    this.longitude,
  });

  bool get isActive => status == 'active';

  factory AdminBusinessOption.fromJson(Map<String, dynamic> json) {
    return AdminBusinessOption(
      id: json['id'] as String,
      name: (json['name'] as String?)?.trim() ?? '',
      status: json['status'] as String? ?? '',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Every business, whatever its status.
///
/// Not only the active ones: an offer or event already tied to a business
/// that has since gone to `pending` must still show whose it is, rather than
/// an empty field that reads as "none".
final adminBusinessOptionsProvider =
    FutureProvider.autoDispose<List<AdminBusinessOption>>((ref) async {
      final rows = await SupabaseConfig.client
          .from('businesses')
          .select('id, name, status, address, latitude, longitude')
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(
        rows,
      ).map(AdminBusinessOption.fromJson).toList();
    });

Map<String, String> get _statusLabels => {
  'active': tr('פעיל', 'Active'),
  'pending': tr('ממתין', 'Pending'),
  'draft': tr('טיוטה', 'Draft'),
  'suspended': tr('מושהה', 'Paused'),
  'closed': tr('סגור', 'Closed'),
};

/// Opens the searchable list and returns the business chosen, or null.
Future<AdminBusinessOption?> showAdminBusinessPicker(BuildContext context) {
  return showDialog<AdminBusinessOption>(
    context: context,
    builder: (_) => const _BusinessPickerDialog(),
  );
}

/// A form field holding a `business_id`, shown by the business's name.
///
/// Validates with the form it sits in, so "an offer must belong to a
/// business" is said beside the field rather than as a 400 from the server.
class AdminBusinessPickerField extends ConsumerWidget {
  final String label;
  final String? businessId;

  /// The name to show while the list loads, or when the id is not in it —
  /// e.g. from the row's own `businesses(name)` join.
  final String? fallbackName;
  final bool required;
  final ValueChanged<AdminBusinessOption?> onChanged;

  const AdminBusinessPickerField({
    super.key,
    required this.label,
    required this.businessId,
    required this.onChanged,
    this.fallbackName,
    this.required = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(adminBusinessOptionsProvider).valueOrNull;
    AdminBusinessOption? current;
    if (businessId != null && options != null) {
      for (final o in options) {
        if (o.id == businessId) {
          current = o;
          break;
        }
      }
    }
    final name = current?.name ?? fallbackName;

    return FormField<String>(
      // Keyed on the value so the field re-reads it after a pick; a
      // FormField otherwise keeps its first value for good.
      key: ValueKey('biz-$label-$businessId'),
      initialValue: businessId,
      validator: (v) =>
          required && (v == null || v.isEmpty) ? tr('יש לבחור עסק', 'A business must be chosen') : null,
      builder: (field) {
        Future<void> pick() async {
          final chosen = await showAdminBusinessPicker(context);
          if (chosen == null) return;
          field.didChange(chosen.id);
          onChanged(chosen);
        }

        return InkWell(
          onTap: pick,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            isEmpty: businessId == null,
            decoration: InputDecoration(
              // Empty when the form puts its labels above the fields.
              labelText: label.isEmpty ? null : label,
              labelStyle: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              errorText: field.errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!required && businessId != null)
                    IconButton(
                      tooltip: tr('ניקוי', 'Clear'),
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        field.didChange(null);
                        onChanged(null);
                      },
                    ),
                  IconButton(
                    tooltip: tr('בחירת עסק', 'Choose a business'),
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    onPressed: pick,
                  ),
                ],
              ),
            ),
            child: Text(
              businessId == null
                  ? ''
                  : (name == null || name.isEmpty)
                  ? tr('עסק לא נמצא', 'Business not found')
                  : current != null && !current.isActive
                  ? '$name (${_statusLabels[current.status] ?? current.status})'
                  : name,
              style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

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
    final async = ref.watch(adminBusinessOptionsProvider);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Directionality(
          textDirection: adminDir,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Text(
                      tr('בחירת עסק', 'Choose a business'),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  autofocus: true,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('חיפוש לפי שם או כתובת...', 'Search by name or address...'),
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      tr('שגיאה בטעינת עסקים: $e', 'Error loading businesses: $e'),
                      style: TextStyle(
                        fontFamily: AppFonts.rubik,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  data: (all) {
                    final q = _query.toLowerCase();
                    final list = q.isEmpty
                        ? all
                        : all
                              .where(
                                (b) =>
                                    b.name.toLowerCase().contains(q) ||
                                    (b.address ?? '').toLowerCase().contains(q),
                              )
                              .toList();
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          tr('לא נמצאו עסקים', 'No businesses found'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            color: AppColors.grayText,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) {
                        final b = list[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            b.name,
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy,
                            ),
                          ),
                          subtitle: (b.address ?? '').trim().isEmpty
                              ? null
                              : Text(
                                  b.address!,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 12,
                                    color: AppColors.grayText,
                                  ),
                                ),
                          trailing: b.isActive
                              ? null
                              : Text(
                                  _statusLabels[b.status] ?? b.status,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubik,
                                    fontSize: 11,
                                    color: AppColors.gold,
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
    );
  }
}

// ─── Dates and times ───

final _dateShape = RegExp(r'^\d{4}-\d{2}-\d{2}$');
final _timeShape = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

/// "2026-09-15" → that day, or null when the text is not a real date.
///
/// `DateTime.tryParse` accepts "2026-02-31" and rolls it into March, so the
/// parts are checked against the date they produce.
DateTime? parseAdminDate(String text) {
  final t = text.trim();
  if (!_dateShape.hasMatch(t)) return null;
  final d = DateTime.tryParse(t);
  if (d == null) return null;
  final parts = t.split('-').map(int.parse).toList();
  if (d.year != parts[0] || d.month != parts[1] || d.day != parts[2]) {
    return null;
  }
  return d;
}

/// "9:05" or "09:05" → (9, 5), or null.
({int hour, int minute})? parseAdminTime(String text) {
  final m = _timeShape.firstMatch(text.trim());
  if (m == null) return null;
  return (hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
}

String formatAdminDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String formatAdminTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// A `time` column as it arrives ("20:00:00") → "20:00". Empty for null.
String adminTimeFromDb(Object? value) {
  final parts = (value as String? ?? '').split(':');
  if (parts.length < 2) return '';
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  return h == null || m == null ? '' : formatAdminTime(h, m);
}

/// A date typed as YYYY-MM-DD, with a calendar beside it.
class AdminDateField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool required;

  const AdminDateField({
    super.key,
    required this.controller,
    required this.decoration,
    this.required = false,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final current = parseAdminDate(controller.text);
    final picked = await showDatePicker(
      locale: adminLocale,
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) controller.text = formatAdminDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
      // Dates read left to right even inside the Hebrew form.
      textDirection: TextDirection.ltr,
      decoration: decoration.copyWith(
        hintText: decoration.hintText ?? 'YYYY-MM-DD',
        suffixIcon: IconButton(
          tooltip: tr('בחירת תאריך', 'Choose a date'),
          icon: const Icon(Icons.calendar_today_outlined, size: 16),
          onPressed: () => _pick(context),
        ),
      ),
      validator: (v) {
        final t = (v ?? '').trim();
        if (t.isEmpty) return required ? tr('שדה חובה', 'Required field') : null;
        return parseAdminDate(t) == null ? tr('תאריך בפורמט 2026-09-15', 'Date in the format 2026-09-15') : null;
      },
    );
  }
}

/// A time typed as HH:MM (24-hour), with a clock beside it.
class AdminTimeField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool required;
  final bool enabled;

  const AdminTimeField({
    super.key,
    required this.controller,
    required this.decoration,
    this.required = false,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    final current = parseAdminTime(controller.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 20, minute: 0)
          : TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (ctx, child) => Localizations.override(
        context: ctx,
        locale: adminLocale,
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      controller.text = formatAdminTime(picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
      textDirection: TextDirection.ltr,
      decoration: decoration.copyWith(
        hintText: decoration.hintText ?? 'HH:MM',
        suffixIcon: IconButton(
          tooltip: tr('בחירת שעה', 'Choose a time'),
          icon: const Icon(Icons.schedule, size: 16),
          onPressed: enabled ? () => _pick(context) : null,
        ),
      ),
      validator: (v) {
        if (!enabled) return null;
        final t = (v ?? '').trim();
        if (t.isEmpty) return required ? tr('שדה חובה', 'Required field') : null;
        return parseAdminTime(t) == null ? tr('שעה בפורמט 20:00', 'Time in the format 20:00') : null;
      },
    );
  }
}
