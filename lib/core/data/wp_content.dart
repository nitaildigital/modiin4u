import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// One item exported from the modiin4u.co.il WordPress site.
///
/// The site keeps its content in JetEngine custom post types (news,
/// business, professionals, apartments) rather than in plain WP posts.
/// The bundled JSON is a snapshot pulled from `/wp-json/wp/v2/<type>`;
/// it stands in for real content until the backend is wired up, so it
/// is read-only and deliberately small.
class WpItem {
  final int id;
  final String title, excerpt, image, link;
  final DateTime date;
  final List<String> terms;

  const WpItem({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.image,
    required this.link,
    required this.date,
    required this.terms,
  });

  factory WpItem.fromJson(Map<String, dynamic> json) {
    return WpItem(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      excerpt: (json['excerpt'] ?? '') as String,
      image: (json['image'] ?? '') as String,
      link: (json['link'] ?? '') as String,
      date: DateTime.tryParse((json['date'] ?? '') as String) ?? DateTime(2026),
      terms: ((json['terms'] as List?) ?? const []).cast<String>(),
    );
  }

  bool hasTerm(String term) => terms.contains(term);

  /// "16 בספטמבר 2026 | 11:58" / "September 16, 2026 | 11:58"
  String formatDate({required bool isHebrew}) {
    final d = date;
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (isHebrew) {
      return '${d.day} ב${_hebrewMonths[d.month - 1]} ${d.year} | $time';
    }
    return '${_englishMonths[d.month - 1]} ${d.day}, ${d.year} | $time';
  }
}

const _hebrewMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];

const _englishMonths = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Loads a bundled export, e.g. `loadWpItems('wp_news')`. Returns an empty
/// list rather than throwing — callers fall back to their own demo content,
/// so a missing or malformed asset degrades to the previous screen.
Future<List<WpItem>> loadWpItems(String name) async {
  try {
    final raw = await rootBundle.loadString('assets/data/$name.json');
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => WpItem.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}
