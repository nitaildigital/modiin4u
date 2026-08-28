import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminCampaignListProvider = StateNotifierProvider<AdminCampaignListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminCampaignListNotifier();
});

class AdminCampaignListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];
  String? _search;
  String? _status;

  AdminCampaignListNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockCampaigns);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allData);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((c) =>
        (c['name'] as String).toLowerCase().contains(q) ||
        (c['business_name'] as String).toLowerCase().contains(q)).toList();
    }
    if (_status != null && _status!.isNotEmpty) {
      filtered = filtered.where((c) => c['status'] == _status).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? s) { _search = s; _applyFilters(); }
  void setStatusFilter(String? s) { _status = s; _applyFilters(); }

  Future<void> createCampaign(Map<String, dynamic> c) async {
    c['id'] = 'camp_${DateTime.now().millisecondsSinceEpoch}';
    c['impressions'] = 0; c['unique_impressions'] = 0; c['clicks'] = 0; c['conversions'] = 0;
    c['created_at'] = DateTime.now().toIso8601String();
    _allData.add(c);
    _applyFilters();
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((c) => c['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields}; _applyFilters(); }
  }

  Future<void> deleteCampaign(String id) async { _allData.removeWhere((c) => c['id'] == id); _applyFilters(); }

  Future<void> updateStatus(String id, String status) async {
    final idx = _allData.indexWhere((c) => c['id'] == id);
    if (idx >= 0) { _allData[idx]['status'] = status; _applyFilters(); }
  }
}

final _mockCampaigns = <Map<String, dynamic>>[
  {'id': 'camp_1', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'placement_id': 'pl_1', 'placement_label': 'ראש עמוד הבית', 'name': 'פיצה פרגו — 20% הנחה', 'status': 'active', 'destination_url': 'https://modiin4u.co.il/business/pizza-frago', 'deep_link': '/business/pizza-frago', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-09-01T00:00:00Z', 'priority': 10, 'frequency_cap': 3, 'target_audience': 'all', 'impressions': 24500, 'unique_impressions': 8200, 'clicks': 890, 'conversions': 145, 'salesperson': 'שרה אברהם', 'created_at': '2026-07-28T10:00:00Z'},
  {'id': 'camp_2', 'business_id': 'b3', 'business_name': 'סטודיו שרה — יוגה ופילאטיס', 'placement_id': 'pl_1', 'placement_label': 'ראש עמוד הבית', 'name': 'שיעור ניסיון חינם', 'status': 'active', 'destination_url': 'https://modiin4u.co.il/business/studio-sara-yoga', 'start_at': '2026-08-10T00:00:00Z', 'end_at': '2026-08-31T00:00:00Z', 'priority': 8, 'frequency_cap': 5, 'target_audience': 'all', 'impressions': 12300, 'unique_impressions': 5100, 'clicks': 520, 'conversions': 78, 'salesperson': 'שרה אברהם', 'created_at': '2026-08-08T10:00:00Z'},
  {'id': 'camp_3', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'placement_id': 'pl_3', 'placement_label': 'בתוך כתבה', 'name': 'מבצעי קיץ — סופר פארם', 'status': 'active', 'destination_url': '', 'start_at': '2026-07-15T00:00:00Z', 'end_at': '2026-08-31T00:00:00Z', 'priority': 5, 'target_audience': 'returning', 'impressions': 45200, 'unique_impressions': 12400, 'clicks': 1230, 'conversions': 210, 'salesperson': 'ניתאי לוי', 'created_at': '2026-07-12T10:00:00Z'},
  {'id': 'camp_4', 'business_id': 'b4', 'business_name': 'ביסטרו מודיעין', 'placement_id': 'pl_2', 'placement_label': 'אמצע עמוד הבית', 'name': 'פתיחה חגיגית — ביסטרו מודיעין', 'status': 'scheduled', 'destination_url': '', 'start_at': '2026-09-01T00:00:00Z', 'end_at': '2026-09-30T00:00:00Z', 'priority': 10, 'target_audience': 'all', 'impressions': 0, 'unique_impressions': 0, 'clicks': 0, 'conversions': 0, 'salesperson': 'שרה אברהם', 'created_at': '2026-08-25T10:00:00Z'},
  {'id': 'camp_5', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'placement_id': 'pl_5', 'placement_label': 'סייד-בר עסק', 'name': 'משלוח חינם מעל ₪100', 'status': 'active', 'destination_url': '', 'start_at': '2026-08-01T00:00:00Z', 'end_at': '2026-10-01T00:00:00Z', 'priority': 3, 'target_audience': 'all', 'impressions': 8900, 'unique_impressions': 3400, 'clicks': 340, 'conversions': 52, 'salesperson': 'ניתאי לוי', 'created_at': '2026-07-30T10:00:00Z'},
  {'id': 'camp_6', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'placement_id': 'pl_7', 'placement_label': 'תוצאות חיפוש', 'name': 'סופר פארם — תוצאה ממומנת', 'status': 'active', 'destination_url': '', 'start_at': '2026-06-01T00:00:00Z', 'end_at': '2026-12-31T00:00:00Z', 'priority': 7, 'target_audience': 'all', 'impressions': 52000, 'unique_impressions': 15600, 'clicks': 2100, 'conversions': 380, 'salesperson': 'ניתאי לוי', 'created_at': '2026-05-28T10:00:00Z'},
  {'id': 'camp_7', 'business_id': 'b3', 'business_name': 'סטודיו שרה', 'placement_id': 'pl_4', 'placement_label': 'תחתית כתבה', 'name': 'מנוי שנתי במחיר מיוחד', 'status': 'draft', 'destination_url': '', 'start_at': null, 'end_at': null, 'priority': 5, 'target_audience': 'all', 'impressions': 0, 'unique_impressions': 0, 'clicks': 0, 'conversions': 0, 'salesperson': 'שרה אברהם', 'created_at': '2026-08-26T10:00:00Z'},
  {'id': 'camp_8', 'business_id': 'b1', 'business_name': 'פיצה פרגו', 'placement_id': 'pl_1', 'placement_label': 'ראש עמוד הבית', 'name': 'פסטיבל פיצה — יוני', 'status': 'ended', 'destination_url': '', 'start_at': '2026-06-01T00:00:00Z', 'end_at': '2026-06-30T00:00:00Z', 'priority': 10, 'target_audience': 'all', 'impressions': 38000, 'unique_impressions': 11200, 'clicks': 1540, 'conversions': 280, 'salesperson': 'שרה אברהם', 'created_at': '2026-05-25T10:00:00Z'},
  {'id': 'camp_9', 'business_id': 'b2', 'business_name': 'סופר פארם מודיעין', 'placement_id': 'pl_1', 'placement_label': 'ראש עמוד הבית', 'name': 'Back to School — סופר פארם', 'status': 'paused', 'destination_url': '', 'start_at': '2026-08-15T00:00:00Z', 'end_at': '2026-09-15T00:00:00Z', 'priority': 8, 'target_audience': 'all', 'impressions': 5600, 'unique_impressions': 2100, 'clicks': 180, 'conversions': 25, 'salesperson': 'ניתאי לוי', 'created_at': '2026-08-12T10:00:00Z'},
  {'id': 'camp_10', 'business_id': 'b4', 'business_name': 'ביסטרו מודיעין', 'placement_id': 'pl_3', 'placement_label': 'בתוך כתבה', 'name': 'Sponsored Article — ביסטרו', 'status': 'draft', 'destination_url': '', 'start_at': null, 'end_at': null, 'priority': 5, 'target_audience': 'new', 'impressions': 0, 'unique_impressions': 0, 'clicks': 0, 'conversions': 0, 'salesperson': 'שרה אברהם', 'created_at': '2026-08-27T10:00:00Z'},
];
