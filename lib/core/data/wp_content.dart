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

/// A business from the site's directory.
///
/// These fields live in JetEngine postmeta, which the REST API does not
/// expose, so they come from a WXR export parsed by tool/parse_wxr.py.
class WpBusiness {
  final int id;
  final String title, description, address, phone, site, hours, image, logo, link;
  final bool kosher, delivery;
  final double? lat, lng, rating;
  final int views;
  final List<String> terms, gallery;

  const WpBusiness({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.phone,
    required this.site,
    required this.hours,
    required this.image,
    required this.logo,
    required this.link,
    required this.kosher,
    required this.delivery,
    required this.views,
    required this.terms,
    required this.gallery,
    this.lat,
    this.lng,
    this.rating,
  });

  factory WpBusiness.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? v) => v == null ? null : (v as num).toDouble();
    return WpBusiness(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      site: (json['site'] ?? '') as String,
      hours: (json['hours'] ?? '') as String,
      image: (json['image'] ?? '') as String,
      logo: (json['logo'] ?? '') as String,
      link: (json['link'] ?? '') as String,
      kosher: (json['kosher'] ?? false) as bool,
      delivery: (json['delivery'] ?? false) as bool,
      views: (json['views'] ?? 0) as int,
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
      rating: asDouble(json['rating']),
      terms: ((json['terms'] as List?) ?? const []).cast<String>(),
      gallery: ((json['gallery'] as List?) ?? const []).cast<String>(),
    );
  }

  /// The address without the ", מודיעין מכבים רעות, ישראל" every entry repeats.
  String get shortAddress {
    final parts = address.split(',');
    return parts.isEmpty ? address : parts.first.trim();
  }

  /// The most specific category, skipping the site-wide bucket terms.
  String get primaryTerm => terms.isEmpty ? '' : terms.first;
}

Future<List<WpBusiness>> loadWpBusinesses() async {
  try {
    final raw = await rootBundle.loadString('assets/data/wp_business.json');
    return (jsonDecode(raw) as List)
        .map((e) => WpBusiness.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}
