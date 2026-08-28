import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_revenue_provider.dart';

class AdminRevenueScreen extends ConsumerStatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  ConsumerState<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends ConsumerState<AdminRevenueScreen> {
  String _statusFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminRevenueListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(children: [
      // ─── Stats ───
      asyncData.whenData((list) {
        final aug = list.where((t) => (t['due_date'] as String? ?? '').startsWith('2026-08')).toList();
        final augPaid = aug.where((t) => t['payment_status'] == 'paid').fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
        final pending = list.where((t) => t['payment_status'] == 'pending').fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
        final overdue = list.where((t) => t['payment_status'] == 'overdue').fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
        final yearTotal = list.where((t) => t['payment_status'] == 'paid').fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
          child: Row(children: [
            _StatChip('הכנסות אוגוסט', '₪${augPaid.toStringAsFixed(0)}', AppColors.turquoise),
            const SizedBox(width: 14),
            _StatChip('ממתין לתשלום', '₪${pending.toStringAsFixed(0)}', AppColors.gold),
            const SizedBox(width: 14),
            _StatChip('חובות', '₪${overdue.toStringAsFixed(0)}', AppColors.error),
            const SizedBox(width: 14),
            _StatChip('סה"כ שנתי', '₪${yearTotal.toStringAsFixed(0)}', AppColors.success),
          ]),
        );
      }).value ?? const SizedBox.shrink(),

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
                hintText: 'חיפוש לפי עסק / חשבונית...',
                hintStyle: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayLight),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.grayLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.turquoise)),
              ),
              onChanged: (v) => _debouncer.run(() => ref.read(adminRevenueListProvider.notifier).setSearch(v.isEmpty ? null : v)),
            ),
          ),
          const SizedBox(width: 12),
          _FilterChip('הכל', _statusFilter.isEmpty, () { setState(() => _statusFilter = ''); ref.read(adminRevenueListProvider.notifier).setStatusFilter(null); }),
          _FilterChip('שולם', _statusFilter == 'paid', () { setState(() => _statusFilter = 'paid'); ref.read(adminRevenueListProvider.notifier).setStatusFilter('paid'); }),
          _FilterChip('ממתין', _statusFilter == 'pending', () { setState(() => _statusFilter = 'pending'); ref.read(adminRevenueListProvider.notifier).setStatusFilter('pending'); }),
          _FilterChip('באיחור', _statusFilter == 'overdue', () { setState(() => _statusFilter = 'overdue'); ref.read(adminRevenueListProvider.notifier).setStatusFilter('overdue'); }),
          _FilterChip('זיכוי', _statusFilter == 'refunded', () { setState(() => _statusFilter = 'refunded'); ref.read(adminRevenueListProvider.notifier).setStatusFilter('refunded'); }),
          const Spacer(),
          asyncData.whenData((l) => Text('${l.length} רשומות', style: GoogleFonts.rubik(fontSize: 13, color: AppColors.grayText))).value ?? const SizedBox.shrink(),
        ]),
      ),

      // ─── Table ───
      Expanded(
        child: asyncData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('שגיאה: $e', style: GoogleFonts.rubik(color: AppColors.error))),
          data: (list) {
            if (list.isEmpty) {
              return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.grayLight.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('אין רשומות', style: GoogleFonts.rubik(color: AppColors.grayText)),
              ]));
            }
            return Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surfaceLight, border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.5)))),
                child: Row(children: [
                  _Col('עסק', flex: 3),
                  _Col('סוג', flex: 1),
                  _Col('סכום', flex: 1),
                  if (isWide) _Col('אמצעי', flex: 1),
                  if (isWide) _Col('חשבונית', flex: 2),
                  _Col('סטטוס', flex: 1),
                  if (isWide) _Col('תאריך', flex: 1),
                  const SizedBox(width: 40),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final status = t['payment_status'] as String? ?? 'pending';
                    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                    final isOverdue = status == 'overdue';
                    final isRefund = amount < 0;
                    final typeLabel = _typeLabel(t['type'] as String? ?? '');
                    final method = _methodLabel(t['payment_method'] as String? ?? '');

                    return Container(
                      color: isOverdue ? AppColors.error.withValues(alpha: 0.04) : null,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(children: [
                        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t['business_name'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                          Text(t['description'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 11, color: AppColors.grayLight)),
                        ])),
                        Expanded(flex: 1, child: Text(typeLabel, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                        Expanded(flex: 1, child: Text(
                          '${isRefund ? "" : "₪"}${amount.abs().toStringAsFixed(0)}${isRefund ? "₪-" : ""}',
                          style: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w700, color: isRefund ? AppColors.error : AppColors.navy, fontFeatures: [const FontFeature.tabularFigures()]),
                        )),
                        if (isWide) Expanded(flex: 1, child: Text(method, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                        if (isWide) Expanded(flex: 2, child: Text(t['invoice_number'] as String? ?? '', style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText, fontFeatures: [const FontFeature.tabularFigures()]))),
                        Expanded(flex: 1, child: _StatusPill(status)),
                        if (isWide) Expanded(flex: 1, child: Text(_shortDate(t['due_date'] as String? ?? ''), style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText))),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.grayLight),
                          onSelected: (v) {
                            if (v == 'mark_paid') ref.read(adminRevenueListProvider.notifier).updateStatus(t['id'] as String, 'paid');
                          },
                          itemBuilder: (_) => [
                            if (status != 'paid') PopupMenuItem(value: 'mark_paid', child: Text('סמן כשולם', style: GoogleFonts.rubik(fontSize: 13))),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
              ),
            ]);
          },
        ),
      ),
    ]);
  }

  String _typeLabel(String t) => switch (t) { 'subscription' => 'מנוי', 'banner' => 'באנר', 'push' => 'Push', 'featured' => 'מומלץ', 'sponsored' => 'ממומן', 'custom' => 'מותאם', _ => t };
  String _methodLabel(String m) => switch (m) { 'credit_card' => 'אשראי', 'bank_transfer' => 'העברה', 'cash' => 'מזומן', 'check' => "צ'ק", _ => m };
  String _shortDate(String iso) { try { final parts = iso.split('-'); return '${parts[2]}/${parts[1]}'; } catch (_) { return iso; } }
}

// ─── Shared Widgets ───

class _StatChip extends StatelessWidget {
  final String label, value; final Color color;
  const _StatChip(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w700, color: color, fontFeatures: [const FontFeature.tabularFigures()])),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.rubik(fontSize: 12, color: AppColors.grayText)),
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status; const _StatusPill(this.status);
  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) { 'paid' => ('שולם', AppColors.success), 'pending' => ('ממתין', AppColors.gold), 'overdue' => ('באיחור', AppColors.error), 'refunded' => ('זיכוי', AppColors.grayLight), _ => (status, AppColors.grayLight) };
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: color)));
  }
}

class _Col extends StatelessWidget {
  final String label; final int flex; const _Col(this.label, {this.flex = 1});
  @override Widget build(BuildContext context) => Expanded(flex: flex, child: Text(label, style: GoogleFonts.rubik(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grayLight)));
}

class _FilterChip extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(left: 6), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: selected ? AppColors.turquoise.withValues(alpha: 0.1) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: selected ? AppColors.turquoise : AppColors.border, width: 0.5)),
      child: Text(label, style: GoogleFonts.rubik(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.turquoise : AppColors.grayText)),
    )));
  }
}

class _Debouncer {
  final int milliseconds; _Debouncer({required this.milliseconds}); Future<void>? _pending;
  void run(VoidCallback action) { _pending?.ignore(); _pending = Future.delayed(Duration(milliseconds: milliseconds)).then((_) => action()); }
}
