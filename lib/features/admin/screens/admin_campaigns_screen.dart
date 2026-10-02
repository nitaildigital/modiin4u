import '../../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/network_photo.dart';
import '../providers/admin_ad_placements_provider.dart';
import '../providers/admin_campaigns_provider.dart';
import '../widgets/image_upload_field.dart';
import '../widgets/admin_load_error.dart';
import '../admin_language.dart';

class AdminCampaignsScreen extends ConsumerStatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  ConsumerState<AdminCampaignsScreen> createState() =>
      _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends ConsumerState<AdminCampaignsScreen> {
  String _statusFilter = '';
  final _searchController = TextEditingController();
  final _debouncer = _Debouncer(milliseconds: 400);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(adminCampaignListProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // ─── Stats bar ───
        // Only once the list is in; a failed load is shown by the table.
        if (asyncData.valueOrNull case final list?)
          Builder(
            builder: (context) {
              final live = list.where(_isLive).length;
              final totalImpressions = list.fold<int>(
                0,
                (s, c) => s + ((c['impressions'] as int?) ?? 0),
              );
              final totalClicks = list.fold<int>(
                0,
                (s, c) => s + ((c['clicks'] as int?) ?? 0),
              );
              final ctr = totalImpressions > 0
                  ? (totalClicks / totalImpressions * 100)
                  : 0.0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _StatChip(tr('מוצגים באתר עכשיו', 'Shown on the site now'), '$live', AppColors.success),
                    const SizedBox(width: 16),
                    _StatChip(
                      tr('חשיפות', 'Impressions'),
                      _formatNumber(totalImpressions),
                      AppColors.turquoise,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(
                      tr('קליקים', 'Clicks'),
                      _formatNumber(totalClicks),
                      AppColors.navy,
                    ),
                    const SizedBox(width: 16),
                    _StatChip(
                      tr('CTR ממוצע', 'Average CTR'),
                      '${ctr.toStringAsFixed(1)}%',
                      AppColors.gold,
                    ),
                  ],
                ),
              );
            },
          ),

        // ─── Toolbar ───
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: isWide ? 280 : 180,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('חיפוש קמפיין...', 'Search campaigns...'),
                    hintStyle: TextStyle(
                      fontFamily: AppFonts.rubik,
                      fontSize: 13,
                      color: AppColors.grayLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: AppColors.grayLight,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.turquoise),
                    ),
                  ),
                  onChanged: (v) => _debouncer.run(() {
                    ref
                        .read(adminCampaignListProvider.notifier)
                        .setSearch(v.isEmpty ? null : v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              _FilterChip(tr('הכל', 'All'), _statusFilter.isEmpty, () {
                setState(() => _statusFilter = '');
                ref
                    .read(adminCampaignListProvider.notifier)
                    .setStatusFilter(null);
              }),
              _FilterChip(tr('פעיל', 'Active'), _statusFilter == 'active', () {
                setState(() => _statusFilter = 'active');
                ref
                    .read(adminCampaignListProvider.notifier)
                    .setStatusFilter('active');
              }),
              _FilterChip(tr('מושהה', 'Paused'), _statusFilter == 'paused', () {
                setState(() => _statusFilter = 'paused');
                ref
                    .read(adminCampaignListProvider.notifier)
                    .setStatusFilter('paused');
              }),
              _FilterChip(tr('טיוטה', 'Draft'), _statusFilter == 'draft', () {
                setState(() => _statusFilter = 'draft');
                ref
                    .read(adminCampaignListProvider.notifier)
                    .setStatusFilter('draft');
              }),
              _FilterChip(tr('הסתיים', 'Ended'), _statusFilter == 'ended', () {
                setState(() => _statusFilter = 'ended');
                ref
                    .read(adminCampaignListProvider.notifier)
                    .setStatusFilter('ended');
              }),
              const Spacer(),
              // `valueOrNull`, not `whenData(...).value`: the latter rethrows
              // on a failed load and greys the whole section instead of letting
              // the list below show the error and a retry.
              if (asyncData.valueOrNull case final list?)
                Text(
                  tr('${list.length} קמפיינים', '${list.length} campaigns'),
                  style: TextStyle(
                    fontFamily: AppFonts.rubik,
                    fontSize: 13,
                    color: AppColors.grayText,
                  ),
                ),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: () => _showEditor(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  tr('קמפיין חדש', 'New campaign'),
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ─── Table ───
        Expanded(
          child: asyncData.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => AdminLoadError(
              message: tr('שגיאה בטעינת הקמפיינים', 'Error loading the campaigns'),
              error: e,
              onRetry: () =>
                  ref.read(adminCampaignListProvider.notifier).load(),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        size: 48,
                        color: AppColors.grayLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('אין קמפיינים', 'No campaigns'),
                        style: TextStyle(
                          fontFamily: AppFonts.rubik,
                          color: AppColors.grayText,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 84),
                        _Col(tr('קמפיין', 'Campaign'), flex: 3),
                        _Col(tr('מיקום', 'Location'), flex: 2),
                        if (isWide) _Col(tr('חשיפות', 'Impressions'), flex: 1),
                        if (isWide) _Col(tr('קליקים', 'Clicks'), flex: 1),
                        if (isWide) _Col('CTR', flex: 1),
                        _Col(tr('סטטוס', 'Status'), flex: 2),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.border.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        final status = c['status'] as String? ?? 'draft';
                        final slot = c['ad_placements'] as Map?;
                        final business = c['businesses'] as Map?;
                        final impressions = c['impressions'] as int? ?? 0;
                        final clicks = c['clicks'] as int? ?? 0;
                        final ctr = impressions > 0
                            ? (clicks / impressions * 100)
                            : 0.0;

                        return InkWell(
                          onTap: () => _showEditor(context, ref, campaign: c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // The creative itself, so a campaign with no
                                // picture — which the site cannot draw — is
                                // obvious at a glance.
                                NetworkPhoto(
                                  url: c['desktop_image'] as String?,
                                  width: 72,
                                  height: 40,
                                  radius: BorderRadius.circular(4),
                                  icon: Icons.image_not_supported_outlined,
                                  iconSize: 16,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['name'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navy,
                                        ),
                                      ),
                                      Text(
                                        business?['name'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 11,
                                          color: AppColors.grayLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        slot?['label'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                          color: AppColors.grayText,
                                        ),
                                      ),
                                      Text(
                                        slot?['code'] as String? ?? '',
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 10,
                                          color: AppColors.grayLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      _formatNumber(impressions),
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      _formatNumber(clicks),
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        fontFeatures: [
                                          const FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isWide)
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${ctr.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontFamily: AppFonts.rubik,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ctr > 3
                                            ? AppColors.success
                                            : AppColors.grayText,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _StatusPill(status),
                                      const SizedBox(height: 4),
                                      _SiteState(campaign: c),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 18,
                                    color: AppColors.grayLight,
                                  ),
                                  onSelected: (v) => _handleAction(v, c),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(
                                        tr('עריכה', 'Edit'),
                                        style: TextStyle(
                                          fontFamily: AppFonts.rubik,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (status != 'active')
                                      PopupMenuItem(
                                        value: 'activate',
                                        child: Text(
                                          tr('הפעל', 'Activate'),
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    if (status == 'active')
                                      PopupMenuItem(
                                        value: 'pause',
                                        child: Text(
                                          tr('השהה', 'Pause'),
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    // Removing a campaign ends it rather than
                                    // deleting it: the client asked for
                                    // nothing permanent, and "ended" is the
                                    // `campaign_status` that takes a banner
                                    // off the site and keeps the record.
                                    if (status != 'ended')
                                      PopupMenuItem(
                                        value: 'end',
                                        child: Text(
                                          tr('הסרה מהאתר', 'Take off the site'),
                                          style: TextStyle(
                                            fontFamily: AppFonts.rubik,
                                            fontSize: 13,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static bool _isLive(Map<String, dynamic> c) => campaignIsLive(
    c,
    placementActive: (c['ad_placements'] as Map?)?['is_active'] == true,
  );

  Future<void> _handleAction(String action, Map<String, dynamic> c) async {
    final notifier = ref.read(adminCampaignListProvider.notifier);
    final id = c['id'] as String;
    final name = c['name'] as String? ?? '';
    final was = c['status'] as String? ?? 'draft';
    try {
      switch (action) {
        case 'edit':
          _showEditor(context, ref, campaign: c);
        case 'activate':
          await notifier.updateStatus(id, 'active');
        case 'pause':
          await notifier.updateStatus(id, 'paused');
          _said(
            tr('"$name" הושהה ולא מוצג באתר. "הפעל" בתפריט מחזיר אותו.', '"$name" is paused and not shown on the site. "Activate" in the menu brings it back.'),
            undo: () => notifier.updateStatus(id, was),
          );
        case 'end':
          await notifier.endCampaign(id);
          _said(
            tr('"$name" הוסר מהאתר. הוא נשמר ברשימה תחת "הסתיים", '
            'ו"הפעל" בתפריט שלו מחזיר אותו.', '"$name" was taken off the site. It stays in the list under "Ended", and "Activate" in its menu brings it back.'),
            undo: () => notifier.updateStatus(id, was),
          );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('הפעולה נכשלה: ${_why(e)}', 'The action failed: ${_why(e)}'),
            style: TextStyle(fontFamily: AppFonts.rubik),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Says what an action did and how to take it back, with an undo that
  /// puts the previous status back.
  void _said(String message, {required Future<void> Function() undo}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: AppFonts.rubik)),
        duration: const Duration(seconds: 6),
        // Awaited like the action itself, so a refused undo says so.
        action: SnackBarAction(
          label: tr('ביטול', 'Cancel'),
          onPressed: () {
            if (mounted) runAdminAction(context, undo);
          },
        ),
      ),
    );
  }

  void _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? campaign,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CampaignEditorDialog(campaign: campaign),
    );
  }
}

// ─── Editor Dialog ───

/// One campaign: the banner, the slot it runs in, where it leads and when.
///
/// The form used to ask for the slot and the business as free text, had no
/// picture at all — the one thing the site draws — and saved into columns
/// the table does not have (`business_name`, `placement_label`,
/// `salesperson`), so every save was refused and the button spun forever.
/// It writes the table's own columns now, and says why when a save fails.
class _CampaignEditorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? campaign;
  const _CampaignEditorDialog({this.campaign});

  @override
  ConsumerState<_CampaignEditorDialog> createState() =>
      _CampaignEditorDialogState();
}

class _CampaignEditorDialogState extends ConsumerState<_CampaignEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  late final TextEditingController _name;
  late final TextEditingController _destinationUrl;
  late final TextEditingController _desktopImage;
  late final TextEditingController _mobileImage;
  late final TextEditingController _priority;
  String? _placementId;
  String? _businessId;
  String? _businessName;
  String? _salespersonId;
  DateTime? _startAt;
  DateTime? _endAt;
  String _status = 'draft';

  bool get _isEditing => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _name = TextEditingController(text: c?['name'] as String? ?? '');
    _destinationUrl = TextEditingController(
      text: c?['destination_url'] as String? ?? '',
    );
    _desktopImage = TextEditingController(
      text: c?['desktop_image'] as String? ?? '',
    );
    _mobileImage = TextEditingController(
      text: c?['mobile_image'] as String? ?? '',
    );
    _priority = TextEditingController(
      text: (c?['priority'] as int?)?.toString() ?? '0',
    );
    _placementId = c?['placement_id'] as String?;
    _businessId = c?['business_id'] as String?;
    _businessName = (c?['businesses'] as Map?)?['name'] as String?;
    _salespersonId = c?['salesperson_id'] as String?;
    _startAt = DateTime.tryParse(c?['start_at'] as String? ?? '')?.toLocal();
    _endAt = DateTime.tryParse(c?['end_at'] as String? ?? '')?.toLocal();
    _status = c?['status'] as String? ?? 'draft';
    // The preview of what the site will do follows the picture as it is
    // uploaded or removed.
    _desktopImage.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _desktopImage.removeListener(_refresh);
    _name.dispose();
    _destinationUrl.dispose();
    _desktopImage.dispose();
    _mobileImage.dispose();
    _priority.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(adminCampaignSlotOptionsProvider);
    final slot = slots.valueOrNull
        ?.where((p) => p['id'] == _placementId)
        .firstOrNull;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 820),
        child: Directionality(
          textDirection: adminDir,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isEditing ? tr('עריכת קמפיין', 'Edit campaign') : tr('קמפיין חדש', 'New campaign'),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildField(
                          tr('שם קמפיין', 'Campaign name'),
                          _name,
                          hint: tr('פיצה פרגו — 20% הנחה', 'Pizza Prego — 20% off'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? tr('שדה חובה', 'Required field') : null,
                        ),
                        const SizedBox(height: 14),
                        _buildSlotPicker(slots),
                        if (slot != null) ...[
                          const SizedBox(height: 8),
                          _SlotNote(slot: slot),
                        ],
                        const SizedBox(height: 14),
                        _buildBusinessPicker(),
                        const SizedBox(height: 14),
                        ImageUploadField(
                          label: tr('תמונת הבאנר — מה שמוצג באתר', 'The banner image — what the site shows'),
                          controller: _desktopImage,
                          folder: 'campaigns',
                        ),
                        const SizedBox(height: 14),
                        ImageUploadField(
                          label:
                              tr('תמונה למובייל (לא חובה — האתר מציג את התמונה שלמעלה)', 'Mobile image (optional — the site shows the image above)'),
                          controller: _mobileImage,
                          folder: 'campaigns/mobile',
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          tr('קישור יעד — לאן לוחצים', 'Target link — where a tap leads'),
                          _destinationUrl,
                          hint: 'https://...',
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return null;
                            return _normalizeUrl(t) == null
                                ? tr('כתובת לא תקינה — למשל https://example.co.il', 'Invalid address — for example https://example.co.il')
                                : null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                tr('תחילת הצגה', 'Show from'),
                                _startAt,
                                empty: tr('מיד', 'Immediately'),
                                onPick: (d) => setState(
                                  () => _startAt = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                  ),
                                ),
                                onClear: () => setState(() => _startAt = null),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                tr('סיום הצגה (כולל היום הזה)', 'Show until (including that day)'),
                                _endAt,
                                empty: tr('ללא סיום', 'No end'),
                                // To the end of the chosen day, so a campaign
                                // "until the 30th" runs through the 30th.
                                onPick: (d) => setState(
                                  () => _endAt = DateTime(
                                    d.year,
                                    d.month,
                                    d.day,
                                    23,
                                    59,
                                  ),
                                ),
                                onClear: () => setState(() => _endAt = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildField(
                                tr('עדיפות', 'Priority'),
                                _priority,
                                hint: '0',
                                helper: tr('מספר גבוה יותר מוצג ראשון במיקום', 'A higher number is shown first in the placement'),
                                keyboardType: TextInputType.number,
                                // The column is a 32-bit integer.
                                validator: (v) {
                                  final n = int.tryParse((v ?? '').trim());
                                  return n == null || n.abs() > 2147483647
                                      ? tr('מספר שלם', 'A whole number')
                                      : null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSalespersonPicker()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildDropdown(tr('סטטוס', 'Status'), _status, {
                          'draft': tr('טיוטה — לא מוצג', 'Draft — not shown'),
                          'active': tr('פעיל — מוצג בתאריכים שנקבעו', 'Active — shown on the set dates'),
                          'paused': tr('מושהה — לא מוצג', 'Paused — not shown'),
                          'ended': tr('הסתיים — לא מוצג', 'Ended — not shown'),
                          // Nothing moves a campaign from "scheduled" to
                          // "active", and the site shows only active ones,
                          // so it is offered only to a row that has it.
                          // Scheduling is "active" with a start date.
                          if (_status == 'scheduled')
                            'scheduled': tr('מתוכנן — לא מוצג (בחרו פעיל)', 'Planned — not shown (choose Active)'),
                        }, (v) => setState(() => _status = v!)),
                        const SizedBox(height: 14),
                        _SiteHint(
                          text: _siteHint(slot),
                          live: _wouldBeLive(slot),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 14),
                          Text(
                            tr('חשיפות: ${widget.campaign!['impressions'] ?? 0} · '
                            'קליקים: ${widget.campaign!['clicks'] ?? 0}', 'Impressions: ${widget.campaign!['impressions'] ?? 0} · Clicks: ${widget.campaign!['clicks'] ?? 0}'),
                            style: TextStyle(
                              fontFamily: AppFonts.rubik,
                              fontSize: 12,
                              color: AppColors.grayLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          tr('סגירה', 'Close'),
                          style: TextStyle(
                            fontFamily: AppFonts.rubik,
                            fontSize: 13,
                            color: AppColors.grayText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _error == null
                            ? const SizedBox.shrink()
                            : Text(
                                _error!,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 12,
                                  color: AppColors.error,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                          minimumSize: const Size(120, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isEditing ? tr('עדכון', 'Update') : tr('יצירה', 'Create'),
                                style: TextStyle(
                                  fontFamily: AppFonts.rubik,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── The slot ───

  Widget _buildSlotPicker(AsyncValue<List<Map<String, dynamic>>> slots) {
    return slots.when(
      loading: () =>
          _labelled(tr('מיקום באתר', 'Placement on the site'), const LinearProgressIndicator(minHeight: 2)),
      error: (e, _) => _labelled(
        tr('מיקום באתר', 'Placement on the site'),
        Text(
          tr('לא ניתן לטעון את המיקומים: $e', 'Could not load the placements: $e'),
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            color: AppColors.error,
          ),
        ),
      ),
      data: (list) => _buildDropdown(
        tr('מיקום באתר', 'Placement on the site'),
        _placementId,
        {
          for (final p in list)
            p['id'] as String:
                tr('${p['label']} · ${p['code']}'
                '${p['is_active'] == true ? '' : ' (מושבת)'}', '${p['label']} · ${p['code']}${p['is_active'] == true ? '' : ' (disabled)'}'),
        },
        (v) => setState(() => _placementId = v),
        validator: (v) => v == null ? tr('בחרו מיקום', 'Choose a placement') : null,
        hint: tr('בחרו היכן הבאנר יופיע', 'Choose where the banner appears'),
      ),
    );
  }

  // ─── The business ───

  Widget _buildBusinessPicker() {
    return _labelled(
      tr('עסק מפרסם (לא חובה)', 'Advertising business (optional)'),
      InkWell(
        onTap: _pickBusiness,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: _decoration().copyWith(
            suffixIcon: _businessId == null
                ? const Icon(Icons.search, size: 18)
                : IconButton(
                    tooltip: tr('ללא עסק', 'No business'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _businessId = null;
                      _businessName = null;
                    }),
                  ),
          ),
          child: Text(
            _businessId == null ? tr('ללא עסק', 'No business') : (_businessName ?? _businessId!),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 14,
              color: _businessId == null ? AppColors.grayLight : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickBusiness() async {
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _BusinessPickerDialog(),
    );
    if (picked == null) return;
    setState(() {
      _businessId = picked['id'] as String?;
      _businessName = picked['name'] as String?;
    });
  }

  // ─── The salesperson ───

  Widget _buildSalespersonPicker() {
    final team = ref.watch(adminCampaignSalespeopleProvider).valueOrNull;
    if (team == null) {
      return _labelled(
        tr('איש מכירות', 'Salesperson'),
        const LinearProgressIndicator(minHeight: 2),
      );
    }
    String nameOf(Map<String, dynamic> a) {
      final p = a['profiles'] as Map?;
      final name = (p?['full_name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) return name;
      return p?['email'] as String? ?? a['id'] as String;
    }

    final items = <String, String>{
      '': tr('ללא', 'None'),
      for (final a in team)
        if (a['is_active'] == true || a['id'] == _salespersonId)
          a['id'] as String: nameOf(a),
    };
    // A salesperson whose admin row is gone still shows as chosen rather
    // than failing the dropdown.
    if (_salespersonId != null && !items.containsKey(_salespersonId)) {
      items[_salespersonId!] = tr('איש צוות שאינו ברשימה', 'A team member not on the list');
    }
    return _buildDropdown(
      tr('איש מכירות', 'Salesperson'),
      _salespersonId ?? '',
      items,
      (v) => setState(() => _salespersonId = (v ?? '').isEmpty ? null : v),
    );
  }

  // ─── What the site will do ───

  bool _wouldBeLive(Map<String, dynamic>? slot) =>
      slot != null &&
      placementIsDrawn(slot['code'] as String?) &&
      campaignIsLive(_asRow(), placementActive: slot['is_active'] == true);

  /// The form's current state as the row it will save, for [campaignIsLive].
  Map<String, dynamic> _asRow() => {
    'status': _status,
    'desktop_image': _desktopImage.text.trim(),
    'start_at': _startAt?.toUtc().toIso8601String(),
    'end_at': _endAt?.toUtc().toIso8601String(),
  };

  /// A sentence on whether, and when, the banner will be on the site once
  /// saved — every condition `active_banners()` checks, in words.
  String _siteHint(Map<String, dynamic>? slot) {
    if (slot == null) return tr('בחרו מיקום כדי לראות אם ומתי הבאנר יוצג.', 'Choose a placement to see whether and when the banner is shown.');
    final reasons = <String>[
      if (_status != 'active')
        tr('הסטטוס "${_statusLabel(_status)}" — רק קמפיין פעיל מוצג', 'The status is "${_statusLabel(_status)}" — only an active campaign is shown'),
      if (_desktopImage.text.trim().isEmpty) tr('אין תמונה', 'No image'),
      if (slot['is_active'] != true) tr('המיקום מושבת', 'The placement is disabled'),
      if (!placementIsDrawn(slot['code'] as String?))
        tr('המיקום הזה לא מוצג באף עמוד באתר כרגע', 'This placement is not shown on any page of the site right now'),
      if (_endAt != null && !_endAt!.isAfter(DateTime.now())) tr('תאריך הסיום עבר', 'The end date has passed'),
    ];
    if (reasons.isNotEmpty) return tr('לא יוצג באתר: ${reasons.join(' · ')}.', 'Not shown on the site: ${reasons.join(' · ')}.');
    final until = _endAt == null ? '' : tr(' ועד ${_fmtDate(_endAt!)}', ' to ${_fmtDate(_endAt!)}');
    if (_startAt != null && _startAt!.isAfter(DateTime.now())) {
      return tr('יוצג באתר מ-${_fmtDate(_startAt!)}$until.', 'Shown on the site from ${_fmtDate(_startAt!)}$until.');
    }
    return tr('יוצג באתר מיד עם השמירה$until.', 'Shown on the site as soon as it is saved$until.');
  }

  // ─── Saving ───

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    if (_startAt != null && _endAt != null && !_endAt!.isAfter(_startAt!)) {
      setState(() => _error = tr('תאריך הסיום חייב להיות אחרי תאריך ההתחלה', 'The end date must be after the start date'));
      return;
    }
    // The site skips a campaign with no picture, so an active one without
    // it would be a booking that shows nothing.
    if (_status == 'active' && _desktopImage.text.trim().isEmpty) {
      setState(
        () => _error = tr('קמפיין פעיל צריך תמונה — העלו תמונה או שמרו כטיוטה', 'An active campaign needs an image — upload one or save as a draft'),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(adminCampaignListProvider.notifier);
    String? orNull(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'placement_id': _placementId,
      'business_id': _businessId,
      'desktop_image': orNull(_desktopImage),
      'mobile_image': orNull(_mobileImage),
      'destination_url': _normalizeUrl(_destinationUrl.text.trim()),
      'start_at': _startAt?.toUtc().toIso8601String(),
      'end_at': _endAt?.toUtc().toIso8601String(),
      'priority': int.tryParse(_priority.text.trim()) ?? 0,
      'salesperson_id': _salespersonId,
      'status': _status,
    };
    try {
      if (_isEditing) {
        await notifier.updateCampaign(widget.campaign!['id'] as String, data);
      } else {
        await notifier.createCampaign(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = tr('השמירה נכשלה: ${_why(e)}', 'Saving failed: ${_why(e)}');
        });
      }
    }
  }

  /// A full address the site can open, or null for none. A bare
  /// "example.co.il" gets its https:// — the site hands the link straight to
  /// the browser, which would read it as a path on this site.
  static String? _normalizeUrl(String text) {
    if (text.isEmpty) return null;
    final withScheme =
        RegExp(r'^https?://', caseSensitive: false).hasMatch(text)
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return null;
    }
    return withScheme;
  }

  // ─── Fields ───

  InputDecoration _decoration({String? hint, String? helper}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 13,
          color: AppColors.grayLight,
        ),
        helperText: helper,
        helperMaxLines: 2,
        helperStyle: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          color: AppColors.grayText,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.turquoise),
        ),
      );

  Widget _labelled(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.rubik,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grayText,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    String? helper,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return _labelled(
      label,
      TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
        decoration: _decoration(hint: hint, helper: helper),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value, {
    required String empty,
    required ValueChanged<DateTime> onPick,
    required VoidCallback onClear,
  }) {
    return _labelled(
      label,
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            locale: adminLocale,
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) onPick(picked);
        },
        child: InputDecorator(
          decoration: _decoration().copyWith(
            suffixIcon: value == null
                ? const Icon(Icons.calendar_today_outlined, size: 16)
                : IconButton(
                    tooltip: tr('ניקוי', 'Clear'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClear,
                  ),
          ),
          child: Text(
            value == null ? empty : _fmtDate(value),
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 14,
              color: value == null ? AppColors.grayLight : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    Map<String, String> items,
    ValueChanged<String?> onChanged, {
    String? Function(String?)? validator,
    String? hint,
  }) {
    return _labelled(
      label,
      DropdownButtonFormField<String>(
        initialValue: items.containsKey(value) ? value : null,
        isExpanded: true,
        validator: validator,
        hint: hint == null
            ? null
            : Text(
                hint,
                style: TextStyle(
                  fontFamily: AppFonts.rubik,
                  fontSize: 13,
                  color: AppColors.grayLight,
                ),
              ),
        items: items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: _decoration(),
      ),
    );
  }
}

/// The size to upload for the chosen slot, and a warning when the slot is
/// switched off or drawn nowhere on the site.
class _SlotNote extends StatelessWidget {
  final Map<String, dynamic> slot;
  const _SlotNote({required this.slot});

  @override
  Widget build(BuildContext context) {
    final drawn =
        placementIsDrawn(slot['code'] as String?) ||
        formatAllowedSizes(slot['allowed_sizes']).isNotEmpty;
    final inactive = slot['is_active'] != true;
    final warn = !drawn || inactive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (warn ? AppColors.error : AppColors.turquoise).withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        [
          tr('גודל: ${placementSizeText(slot)}', 'Size: ${placementSizeText(slot)}'),
          tr('עד ${slot['max_banners'] ?? 1} באנרים במיקום', 'Up to ${slot['max_banners'] ?? 1} banners in the placement'),
          if (inactive) tr('המיקום מושבת — שום באנר בו לא יוצג', 'The placement is disabled — no banner in it will be shown'),
        ].join(' · '),
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          color: warn ? AppColors.error : AppColors.navy,
        ),
      ),
    );
  }
}

/// Whether the banner will be on the site once saved, in one line.
class _SiteHint extends StatelessWidget {
  final String text;
  final bool live;
  const _SiteHint({required this.text, required this.live});

  @override
  Widget build(BuildContext context) {
    final color = live ? AppColors.success : AppColors.gold;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            live ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppFonts.rubik,
                fontSize: 13,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
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
          textDirection: adminDir,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr('חיפוש עסק לפי שם', 'Search a business by name'),
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
                        tr('לא ניתן לטעון עסקים: $e', 'Could not load businesses: $e'),
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
                            tr('לא נמצא עסק', 'No business found'),
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
                                fontSize: 14,
                              ),
                            ),
                            subtitle: b['status'] == 'active'
                                ? null
                                : Text(
                                    tr('סטטוס: ${b['status']}', 'Status: ${b['status']}'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubik,
                                      fontSize: 11,
                                      color: AppColors.grayLight,
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

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _statusLabel(String status) => switch (status) {
  'active' => tr('פעיל', 'Active'),
  'scheduled' => tr('מתוכנן', 'Planned'),
  'paused' => tr('מושהה', 'Paused'),
  'ended' => tr('הסתיים', 'Ended'),
  'draft' => tr('טיוטה', 'Draft'),
  _ => status,
};

/// On the site now, or when it will be, or why it is not — under the status
/// in the list, since "active" alone does not say whether anyone sees it.
class _SiteState extends StatelessWidget {
  final Map<String, dynamic> campaign;
  const _SiteState({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    final slot = c['ad_placements'] as Map?;
    final now = DateTime.now();
    final start = DateTime.tryParse(c['start_at'] as String? ?? '')?.toLocal();
    final end = DateTime.tryParse(c['end_at'] as String? ?? '')?.toLocal();
    final image = (c['desktop_image'] as String? ?? '').isNotEmpty;
    final (String text, Color color) = switch (c['status']) {
      'active' when !image => (tr('ללא תמונה — לא מוצג', 'No image — not shown'), AppColors.error),
      'active' when slot?['is_active'] != true => (
        tr('המיקום מושבת', 'The placement is disabled'),
        AppColors.error,
      ),
      'active' when !placementIsDrawn(slot?['code'] as String?) => (
        tr('מיקום שלא מוצג באתר', 'A placement not shown on the site'),
        AppColors.error,
      ),
      'active' when end != null && !end.isAfter(now) => (
        tr('הסתיים ב-${_fmtDate(end)}', 'Ended on ${_fmtDate(end)}'),
        AppColors.grayText,
      ),
      'active' when start != null && start.isAfter(now) => (
        tr('יתחיל ב-${_fmtDate(start)}', 'Starts on ${_fmtDate(start)}'),
        AppColors.turquoise,
      ),
      'active' => (
        end == null ? tr('באתר עכשיו', 'On the site now') : tr('באתר עד ${_fmtDate(end)}', 'On the site until ${_fmtDate(end)}'),
        AppColors.success,
      ),
      _ => (tr('לא מוצג', 'Not shown'), AppColors.grayLight),
    };
    return Text(
      text,
      style: TextStyle(fontFamily: AppFonts.rubik, fontSize: 10, color: color),
    );
  }
}

// ─── Helper Widgets ───

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.rubik,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.grayText,
            ),
          ),
        ),
      ),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.grayText,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => (tr('פעיל', 'Active'), AppColors.success),
      'scheduled' => (tr('מתוכנן', 'Planned'), AppColors.turquoise),
      'paused' => (tr('מושהה', 'Paused'), AppColors.gold),
      'ended' => (tr('הסתיים', 'Ended'), AppColors.grayText),
      'draft' => (tr('טיוטה', 'Draft'), AppColors.grayLight),
      _ => (status, AppColors.grayText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubik,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _Debouncer {
  final int milliseconds;
  _Debouncer({required this.milliseconds});
  void run(VoidCallback action) {
    Future.delayed(Duration(milliseconds: milliseconds), action);
  }
}

/// What went wrong, in the database's own words rather than the exception's
/// wrapper — "value … is out of range", not "PostgrestException(message: …".
String _why(Object e) => e is PostgrestException ? e.message : '$e';
