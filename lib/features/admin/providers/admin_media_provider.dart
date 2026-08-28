import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminMediaListProvider = StateNotifierProvider<AdminMediaListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return AdminMediaListNotifier();
});

class AdminMediaListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  List<Map<String, dynamic>> _allData = [];
  String? _search;
  String? _mimeFilter;

  AdminMediaListNotifier() : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    _allData = List<Map<String, dynamic>>.from(_mockMedia);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_allData);
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      filtered = filtered.where((m) =>
        (m['filename'] as String).toLowerCase().contains(q) ||
        (m['alt_text'] as String? ?? '').toLowerCase().contains(q)).toList();
    }
    if (_mimeFilter != null && _mimeFilter!.isNotEmpty) {
      filtered = filtered.where((m) => (m['mime_type'] as String).startsWith(_mimeFilter!)).toList();
    }
    state = AsyncValue.data(filtered);
  }

  void setSearch(String? s) { _search = s; _applyFilters(); }
  void setMimeFilter(String? f) { _mimeFilter = f; _applyFilters(); }

  Future<void> createMedia(Map<String, dynamic> media) async {
    media['id'] = 'med_${DateTime.now().millisecondsSinceEpoch}';
    media['created_at'] = DateTime.now().toIso8601String();
    _allData.insert(0, media);
    _applyFilters();
  }

  Future<void> updateMedia(String id, Map<String, dynamic> fields) async {
    final idx = _allData.indexWhere((m) => m['id'] == id);
    if (idx >= 0) { _allData[idx] = {..._allData[idx], ...fields}; _applyFilters(); }
  }

  Future<void> deleteMedia(String id) async {
    _allData.removeWhere((m) => m['id'] == id);
    _applyFilters();
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

final _mockMedia = <Map<String, dynamic>>[
  {'id': 'med_1', 'filename': 'pizza-frago-cover.jpg', 'url': '', 'alt_text': 'פיצה פרגו — תמונת כיסוי', 'mime_type': 'image/jpeg', 'file_size': 245000, 'width': 1200, 'height': 630, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'business', 'entity_id': 'b1', 'media_role': 'cover', 'created_at': '2024-03-15T10:00:00Z'},
  {'id': 'med_2', 'filename': 'pizza-frago-logo.png', 'url': '', 'alt_text': 'לוגו פיצה פרגו', 'mime_type': 'image/png', 'file_size': 42000, 'width': 400, 'height': 400, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'business', 'entity_id': 'b1', 'media_role': 'logo', 'created_at': '2024-03-15T10:00:00Z'},
  {'id': 'med_3', 'filename': 'park-anaba-hero.webp', 'url': '', 'alt_text': 'פארק ענבה — מבט מלמעלה', 'mime_type': 'image/webp', 'file_size': 380000, 'width': 1920, 'height': 1080, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'article', 'entity_id': 'a1', 'media_role': 'cover', 'created_at': '2026-08-15T10:00:00Z'},
  {'id': 'med_4', 'filename': 'super-pharm-cover.jpg', 'url': '', 'alt_text': 'סופר פארם מודיעין', 'mime_type': 'image/jpeg', 'file_size': 198000, 'width': 1200, 'height': 630, 'uploaded_by': 'יוסי כהן', 'entity_type': 'business', 'entity_id': 'b2', 'media_role': 'cover', 'created_at': '2024-05-01T10:00:00Z'},
  {'id': 'med_5', 'filename': 'studio-sara-gallery-1.jpg', 'url': '', 'alt_text': 'שיעור יוגה בסטודיו שרה', 'mime_type': 'image/jpeg', 'file_size': 312000, 'width': 1600, 'height': 900, 'uploaded_by': 'שרה אברהם', 'entity_type': 'business', 'entity_id': 'b3', 'media_role': 'gallery', 'created_at': '2024-09-05T10:00:00Z'},
  {'id': 'med_6', 'filename': 'studio-sara-gallery-2.jpg', 'url': '', 'alt_text': 'פילאטיס קבוצתי', 'mime_type': 'image/jpeg', 'file_size': 289000, 'width': 1600, 'height': 900, 'uploaded_by': 'שרה אברהם', 'entity_type': 'business', 'entity_id': 'b3', 'media_role': 'gallery', 'created_at': '2024-09-06T10:00:00Z'},
  {'id': 'med_7', 'filename': 'shlomo-artzi-event.jpg', 'url': '', 'alt_text': 'הופעת שלמה ארצי — היכל התרבות מודיעין', 'mime_type': 'image/jpeg', 'file_size': 456000, 'width': 1920, 'height': 1080, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'event', 'entity_id': 'ev_1', 'media_role': 'cover', 'created_at': '2026-08-01T10:00:00Z'},
  {'id': 'med_8', 'filename': 'beer-fest-banner.webp', 'url': '', 'alt_text': 'פסטיבל בירה מודיעין 2026', 'mime_type': 'image/webp', 'file_size': 520000, 'width': 1920, 'height': 600, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'event', 'entity_id': 'ev_5', 'media_role': 'cover', 'created_at': '2026-08-10T10:00:00Z'},
  {'id': 'med_9', 'filename': 'modiin-skyline-og.jpg', 'url': '', 'alt_text': 'מודיעין — קו רקיע', 'mime_type': 'image/jpeg', 'file_size': 178000, 'width': 1200, 'height': 630, 'uploaded_by': 'ניתאי לוי', 'entity_type': null, 'entity_id': null, 'media_role': 'og', 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'med_10', 'filename': 'football-promotion.jpg', 'url': '', 'alt_text': 'קבוצת הכדורגל העירונית', 'mime_type': 'image/jpeg', 'file_size': 267000, 'width': 1200, 'height': 800, 'uploaded_by': 'דנה כהן', 'entity_type': 'article', 'entity_id': 'a3', 'media_role': 'cover', 'created_at': '2026-08-10T10:00:00Z'},
  {'id': 'med_11', 'filename': 'commercial-center-render.png', 'url': '', 'alt_text': 'הדמיה — מרכז מסחרי חדש', 'mime_type': 'image/png', 'file_size': 890000, 'width': 2400, 'height': 1350, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'article', 'entity_id': 'a2', 'media_role': 'cover', 'created_at': '2026-08-12T10:00:00Z'},
  {'id': 'med_12', 'filename': 'bistro-modiin-menu.jpg', 'url': '', 'alt_text': 'תפריט ביסטרו מודיעין', 'mime_type': 'image/jpeg', 'file_size': 145000, 'width': 800, 'height': 1200, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'business', 'entity_id': 'b4', 'media_role': 'gallery', 'created_at': '2026-08-10T10:00:00Z'},
  {'id': 'med_13', 'filename': 'summer-safety-infographic.png', 'url': '', 'alt_text': 'אינפוגרפיקה — בטיחות קיץ', 'mime_type': 'image/png', 'file_size': 670000, 'width': 1080, 'height': 1920, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'article', 'entity_id': 'a4', 'media_role': 'gallery', 'created_at': '2026-08-08T10:00:00Z'},
  {'id': 'med_14', 'filename': 'modiin-logo-white.svg', 'url': '', 'alt_text': 'לוגו מודיעין בשבילך — לבן', 'mime_type': 'image/svg+xml', 'file_size': 8500, 'width': 200, 'height': 60, 'uploaded_by': 'ניתאי לוי', 'entity_type': null, 'entity_id': null, 'media_role': 'logo', 'created_at': '2024-01-01T10:00:00Z'},
  {'id': 'med_15', 'filename': 'home-banner-autumn.jpg', 'url': '', 'alt_text': 'באנר מסך בית — סתיו 2026', 'mime_type': 'image/jpeg', 'file_size': 410000, 'width': 1440, 'height': 480, 'uploaded_by': 'ניתאי לוי', 'entity_type': null, 'entity_id': null, 'media_role': 'cover', 'created_at': '2026-08-20T10:00:00Z'},
  {'id': 'med_16', 'filename': 'deal-yoga-free.jpg', 'url': '', 'alt_text': 'שיעור יוגה חינם — מבצע', 'mime_type': 'image/jpeg', 'file_size': 156000, 'width': 600, 'height': 600, 'uploaded_by': 'שרה אברהם', 'entity_type': 'offer', 'entity_id': 'off_3', 'media_role': 'cover', 'created_at': '2026-07-01T10:00:00Z'},
  {'id': 'med_17', 'filename': 'app-promo-video-thumb.jpg', 'url': '', 'alt_text': 'סרטון פרומו — מודיעין בשבילך', 'mime_type': 'image/jpeg', 'file_size': 234000, 'width': 1280, 'height': 720, 'uploaded_by': 'ניתאי לוי', 'entity_type': null, 'entity_id': null, 'media_role': 'gallery', 'created_at': '2026-06-15T10:00:00Z'},
  {'id': 'med_18', 'filename': 'neighborhood-map-avnei-hen.png', 'url': '', 'alt_text': 'מפת שכונת אבני חן', 'mime_type': 'image/png', 'file_size': 520000, 'width': 1400, 'height': 1000, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'neighborhood', 'entity_id': 'n1', 'media_role': 'cover', 'created_at': '2024-06-01T10:00:00Z'},
  {'id': 'med_19', 'filename': 'campaign-pizza-20off.jpg', 'url': '', 'alt_text': 'קמפיין 20% הנחה — פיצה פרגו', 'mime_type': 'image/jpeg', 'file_size': 189000, 'width': 728, 'height': 90, 'uploaded_by': 'ניתאי לוי', 'entity_type': 'campaign', 'entity_id': 'camp_1', 'media_role': 'cover', 'created_at': '2026-07-15T10:00:00Z'},
  {'id': 'med_20', 'filename': 'running-event-cover.webp', 'url': '', 'alt_text': 'ריצת ערב קהילתית — אגם ענבה', 'mime_type': 'image/webp', 'file_size': 340000, 'width': 1600, 'height': 900, 'uploaded_by': 'דנה מזרחי', 'entity_type': 'event', 'entity_id': 'ev_7', 'media_role': 'cover', 'created_at': '2026-08-18T10:00:00Z'},
];
