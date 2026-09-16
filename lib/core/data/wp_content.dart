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

/// A service provider from the site's professionals directory.
/// These use their own meta keys — `photo-logo`, `profssional-discription`.
class WpProfessional {
  final int id;
  final String title, description, phone, image, link;
  final List<String> terms;

  const WpProfessional({
    required this.id,
    required this.title,
    required this.description,
    required this.phone,
    required this.image,
    required this.link,
    required this.terms,
  });

  factory WpProfessional.fromJson(Map<String, dynamic> json) => WpProfessional(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    phone: (json['phone'] ?? '') as String,
    image: (json['image'] ?? '') as String,
    link: (json['link'] ?? '') as String,
    terms: ((json['terms'] as List?) ?? const []).cast<String>(),
  );

  String get profession => terms.isEmpty ? '' : terms.first;
}

/// A listing from the site's apartments directory.
class WpApartment {
  final int id;
  final String title, address, neighborhood, type, vibe, rooms, floor, meters;
  final String description, seller, phone, image, link;
  final int? price;
  final double? lat, lng;
  final bool elevator, parking, storage, ac, terrace, shelter, byAgent;

  const WpApartment({
    required this.id,
    required this.title,
    required this.address,
    required this.neighborhood,
    required this.type,
    required this.vibe,
    required this.rooms,
    required this.floor,
    required this.meters,
    required this.description,
    required this.seller,
    required this.phone,
    required this.image,
    required this.link,
    required this.elevator,
    required this.parking,
    required this.storage,
    required this.ac,
    required this.terrace,
    required this.shelter,
    required this.byAgent,
    this.price,
    this.lat,
    this.lng,
  });

  factory WpApartment.fromJson(Map<String, dynamic> json) {
    String str(String k) => (json[k] ?? '') as String;
    bool flag(String k) => (json[k] ?? false) as bool;
    double? asDouble(Object? v) => v == null ? null : (v as num).toDouble();
    return WpApartment(
      id: json['id'] as int,
      title: str('title'),
      address: str('address'),
      neighborhood: str('neighborhood'),
      type: str('type'),
      vibe: str('vibe'),
      rooms: str('rooms'),
      floor: str('floor'),
      meters: str('meters'),
      description: str('description'),
      seller: str('seller'),
      phone: str('phone'),
      image: str('image'),
      link: str('link'),
      price: json['price'] as int?,
      lat: asDouble(json['lat']),
      lng: asDouble(json['lng']),
      elevator: flag('elevator'),
      parking: flag('parking'),
      storage: flag('storage'),
      ac: flag('ac'),
      terrace: flag('terrace'),
      shelter: flag('shelter'),
      byAgent: flag('byAgent'),
    );
  }

  /// "₪4,950,000" — the site stores a bare integer.
  String get priceLabel {
    if (price == null) return '';
    final digits = price!.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return '₪$buf';
  }

  String get shortAddress => address.split(',').first.trim();
}

/// A broker from the site's real-estate-agents directory.
class WpAgent {
  final int id;
  final String title, phone, photo, logo, link;

  const WpAgent({
    required this.id,
    required this.title,
    required this.phone,
    required this.photo,
    required this.logo,
    required this.link,
  });

  factory WpAgent.fromJson(Map<String, dynamic> json) => WpAgent(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    phone: (json['phone'] ?? '') as String,
    photo: (json['photo'] ?? '') as String,
    logo: (json['logo'] ?? '') as String,
    link: (json['link'] ?? '') as String,
  );
}

Future<List<T>> _loadList<T>(String name, T Function(Map<String, dynamic>) parse) async {
  try {
    final raw = await rootBundle.loadString('assets/data/$name.json');
    return (jsonDecode(raw) as List)
        .map((e) => parse(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return const [];
  }
}

Future<List<WpProfessional>> loadWpProfessionals() =>
    _loadList('wp_professionals', WpProfessional.fromJson);

Future<List<WpApartment>> loadWpApartments() =>
    _loadList('wp_apartments', WpApartment.fromJson);

Future<List<WpAgent>> loadWpAgents() => _loadList('wp_agents', WpAgent.fromJson);
