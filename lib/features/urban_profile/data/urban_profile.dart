import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';

/// The Urban Profile (the client's spec, 8 Oct 2026; migration 00077): a
/// photo and a few words, interests, favourite places with up to three top
/// picks, a permanent username for the profile link, and who may see it.
/// Name and neighbourhood are the account's own, never asked again.

/// Where a profile link opens: the website's `/u/<username>`, which opens the
/// app where it is installed. The www address is the client's site once it
/// moves to our server (docs/urban-profile/PLAN.md, question 3).
const urbanProfileLinkBase = 'https://www.modiin4u.co.il/u/';

String urbanProfileLink(String username) => '$urbanProfileLinkBase$username';

/// Accounts made from this day are taken through the onboarding at their
/// first sign-in; older accounts are offered it on their Profile instead
/// ("Complete your Urban Profile"), never stopped on their way into the app.
final urbanProfileLaunch = DateTime.utc(2026, 10, 9);

/// The fixed list of interests, stored as keys (00077 checks them). The spec
/// writes them with emoji; the designs draw them with line icons, as here.
class Interest {
  final String key;
  final IconData icon;
  final String emoji;
  final String en;
  final String he;
  const Interest(this.key, this.icon, this.emoji, this.en, this.he);

  String label(bool hebrew) => hebrew ? he : en;
}

const interests = <Interest>[
  Interest('cafes', IconsaxPlusLinear.coffee, '☕', 'Cafés', 'בתי קפה'),
  Interest('brunch', IconsaxPlusLinear.cake, '🥐', 'Breakfast & Brunch', 'ארוחות בוקר ובראנץ׳'),
  Interest('nightlife', IconsaxPlusLinear.glass, '🍷', 'Bars & Nightlife', 'ברים וחיי לילה'),
  Interest('restaurants', IconsaxPlusLinear.reserve, '🍽️', 'Restaurants', 'מסעדות'),
  Interest('asian', IconsaxPlusLinear.milk, '🍣', 'Asian Food', 'אוכל אסייתי'),
  Interest('nature', IconsaxPlusLinear.tree, '🌳', 'Parks & Nature', 'פארקים וטבע'),
  Interest('running', IconsaxPlusLinear.activity, '🏃', 'Running', 'ריצה'),
  Interest('cycling', IconsaxPlusLinear.routing_2, '🚴', 'Cycling', 'רכיבה על אופניים'),
  Interest('fitness', IconsaxPlusLinear.weight, '🏋️', 'Fitness & Sports', 'כושר וספורט'),
  Interest('family', IconsaxPlusLinear.people, '👨‍👩‍👧', 'Family & Kids', 'משפחה וילדים'),
  Interest('culture', IconsaxPlusLinear.mask, '🎭', 'Culture', 'תרבות'),
  Interest('music', IconsaxPlusLinear.music, '🎵', 'Music', 'מוזיקה'),
  Interest('pets', IconsaxPlusLinear.pet, '🐶', 'Pets', 'חיות מחמד'),
  Interest('shopping', IconsaxPlusLinear.shopping_bag, '🛍️', 'Shopping', 'קניות'),
  Interest('events', IconsaxPlusLinear.calendar, '🎉', 'Events', 'אירועים'),
  Interest('local_business', IconsaxPlusLinear.shop, '💼', 'Local Businesses', 'עסקים מקומיים'),
];

Interest? interestOf(String key) {
  for (final i in interests) {
    if (i.key == key) return i;
  }
  return null;
}

const minInterests = 3;
const maxInterests = 8;
const maxPlaces = 5;
const bioMax = 160;

/// The three Top Picks labels (00077's `top_pick`).
enum TopPick {
  coffee('coffee', 'My Coffee Spot', 'בית הקפה שלי', IconsaxPlusLinear.coffee),
  restaurant('restaurant', 'My Restaurant', 'המסעדה שלי', IconsaxPlusLinear.reserve),
  city('city', 'My Place in the City', 'המקום שלי בעיר', IconsaxPlusLinear.location_tick);

  final String key;
  final String en;
  final String he;
  final IconData icon;
  const TopPick(this.key, this.en, this.he, this.icon);

  String label(bool hebrew) => hebrew ? he : en;

  static TopPick? of(String? key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return null;
  }
}

/// A place on someone's profile — a business or a park from the directory.
class UrbanPlace {
  final String id;
  final String name;
  final String? nameEn;
  final String? image;
  final String kind;
  final TopPick? topPick;

  const UrbanPlace({required this.id, required this.name, this.nameEn, this.image, this.kind = 'business', this.topPick});

  String label(bool hebrew) => !hebrew && (nameEn ?? '').trim().isNotEmpty ? nameEn!.trim() : name;

  UrbanPlace withPick(TopPick? pick) =>
      UrbanPlace(id: id, name: name, nameEn: nameEn, image: image, kind: kind, topPick: pick);

  /// From a `businesses` row (the search and the suggestions).
  factory UrbanPlace.fromBusiness(Map<String, dynamic> j) => UrbanPlace(
    id: j['id'] as String,
    name: (j['name'] as String?) ?? '',
    nameEn: j['name_en'] as String?,
    image: _image(j['cover_url'] as String?, j['logo_url'] as String?),
    kind: (j['kind'] as String?) ?? 'business',
  );

  /// From `urban_profile()`'s places.
  factory UrbanPlace.fromProfile(Map<String, dynamic> j) => UrbanPlace(
    id: j['id'] as String,
    name: (j['name'] as String?) ?? '',
    nameEn: j['name_en'] as String?,
    image: _image(j['image'] as String?, null),
    kind: (j['kind'] as String?) ?? 'business',
    topPick: TopPick.of(j['top_pick'] as String?),
  );

  // A business with neither picture is drawn as a plain tile, never with an
  // image that is not its own.
  static String? _image(String? cover, String? logo) {
    final c = (cover ?? '').trim();
    if (c.isNotEmpty) return c;
    final l = (logo ?? '').trim();
    return l.isEmpty ? null : l;
  }
}

/// A whole Urban Profile as shown — one's own, or another resident's from
/// `urban_profile()`.
class UrbanProfile {
  /// The account's id — for reporting a profile (00079); null on one's own
  /// before it is read through the function.
  final String? id;
  final String? username;
  final String name;
  final String? avatarUrl;
  final String? neighborhood;
  final String? neighborhoodEn;
  final String? bio;
  final List<String> interests;
  final List<UrbanPlace> places;
  final String visibility;
  final bool isOwner;
  final DateTime? memberSince;
  final DateTime? seenAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const UrbanProfile({
    this.id,
    this.username,
    required this.name,
    this.avatarUrl,
    this.neighborhood,
    this.neighborhoodEn,
    this.bio,
    this.interests = const [],
    this.places = const [],
    this.visibility = 'private',
    this.isOwner = false,
    this.memberSince,
    this.seenAt,
    this.completedAt,
    this.createdAt,
  });

  bool get isVisible => visibility == 'residents';
  bool get hasPhoto => (avatarUrl ?? '').trim().isNotEmpty;
  bool get hasBio => (bio ?? '').trim().isNotEmpty;
  bool get hasInterests => interests.length >= minInterests;
  bool get hasPlaces => places.isNotEmpty;
  bool get hasUsername => (username ?? '').isNotEmpty;

  /// "Your Urban Profile is 70% complete" — photo, bio, interests, places
  /// and the profile link, a fifth each.
  int get completion =>
      [hasPhoto, hasBio, hasInterests, hasPlaces, hasUsername].where((d) => d).length * 20;

  /// The first step still missing something (1 photo and bio, 2 interests,
  /// 3 places), or null when they are all done.
  int? get firstIncompleteStep {
    if (!hasPhoto || !hasBio) return 1;
    if (!hasInterests) return 2;
    if (!hasPlaces) return 3;
    return null;
  }

  String? neighborhoodLabel(bool hebrew) =>
      !hebrew && (neighborhoodEn ?? '').trim().isNotEmpty ? neighborhoodEn : neighborhood;

  factory UrbanProfile.fromFunction(Map<String, dynamic> j) => UrbanProfile(
    id: j['id'] as String?,
    username: j['username'] as String?,
    name: (j['name'] as String?) ?? '',
    avatarUrl: j['avatar_url'] as String?,
    neighborhood: j['neighborhood'] as String?,
    neighborhoodEn: j['neighborhood_en'] as String?,
    bio: j['bio'] as String?,
    interests: List<String>.from((j['interests'] as List?) ?? const []),
    places: [
      for (final p in List<Map<String, dynamic>>.from((j['places'] as List?) ?? const [])) UrbanPlace.fromProfile(p),
    ],
    visibility: (j['visibility'] as String?) ?? 'private',
    isOwner: j['is_owner'] == true,
    memberSince: DateTime.tryParse(j['member_since'] as String? ?? ''),
  );
}

class UrbanProfileRepository {
  final _client = SupabaseConfig.client;

  String? get _uid => _client.auth.currentUser?.id;

  static const _placeColumns = 'id, name, name_en, cover_url, logo_url, kind';

  /// The signed-in person's own profile, read from their row (they may read
  /// all of it) with their places in order.
  Future<UrbanProfile?> mine() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select('full_name, avatar_url, bio, interests, profile_visibility, username, created_at, '
            'urban_profile_seen_at, urban_profile_completed_at, '
            'neighborhoods!profiles_neighborhood_id_fkey(name, name_en)')
        .eq('id', uid)
        .maybeSingle();
    if (row == null) return null;
    final placeRows = await _client
        .from('profile_places')
        .select('position, top_pick, businesses($_placeColumns, status)')
        .eq('profile_id', uid)
        .order('position');
    final places = <UrbanPlace>[
      for (final r in List<Map<String, dynamic>>.from(placeRows))
        if (r['businesses'] is Map && (r['businesses'] as Map)['status'] == 'active')
          UrbanPlace.fromBusiness(Map<String, dynamic>.from(r['businesses'] as Map))
              .withPick(TopPick.of(r['top_pick'] as String?)),
    ];
    final n = row['neighborhoods'] is Map ? row['neighborhoods'] as Map : const {};
    return UrbanProfile(
      id: uid,
      username: row['username'] as String?,
      name: (row['full_name'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      neighborhood: n['name'] as String?,
      neighborhoodEn: n['name_en'] as String?,
      bio: row['bio'] as String?,
      interests: List<String>.from((row['interests'] as List?) ?? const []),
      places: places,
      visibility: (row['profile_visibility'] as String?) ?? 'private',
      isOwner: true,
      memberSince: DateTime.tryParse(row['created_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      seenAt: DateTime.tryParse(row['urban_profile_seen_at'] as String? ?? ''),
      completedAt: DateTime.tryParse(row['urban_profile_completed_at'] as String? ?? ''),
    );
  }

  Future<void> _update(Map<String, dynamic> patch) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    await _client.from('profiles').update(patch).eq('id', uid);
  }

  /// The onboarding was shown — it is never opened by itself again.
  Future<void> markSeen() => _update({'urban_profile_seen_at': DateTime.now().toUtc().toIso8601String()});

  Future<void> markCompleted() => _update({'urban_profile_completed_at': DateTime.now().toUtc().toIso8601String()});

  Future<void> saveBio(String bio) {
    final text = bio.trim();
    return _update({'bio': text.isEmpty ? null : text});
  }

  Future<void> saveInterests(List<String> keys) => _update({'interests': keys});

  Future<void> setVisible(bool visible) => _update({'profile_visibility': visible ? 'residents' : 'private'});

  /// Uploads a new profile photo to `avatars/<id>/` (as Edit Profile does)
  /// and returns its address; the caller saves it on the account.
  Future<String> uploadPhoto(Uint8List bytes, String fileName) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    final dot = fileName.lastIndexOf('.');
    final ext = dot < 0 ? '.jpg' : fileName.substring(dot).toLowerCase();
    final path = 'avatars/$uid/${DateTime.now().microsecondsSinceEpoch}$ext';
    await _client.storage.from('media').uploadBinary(path, bytes);
    return _client.storage.from('media').getPublicUrl(path);
  }

  /// Replaces the favourite places with [ids], in this order, keeping each
  /// one's top pick where it stays.
  Future<void> savePlaces(List<String> ids, {Map<String, TopPick?> picks = const {}}) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    await _client.from('profile_places').delete().eq('profile_id', uid);
    if (ids.isEmpty) return;
    await _client.from('profile_places').insert([
      for (var i = 0; i < ids.length && i < maxPlaces; i++)
        {'profile_id': uid, 'business_id': ids[i], 'position': i + 1, 'top_pick': picks[ids[i]]?.key},
    ]);
  }

  /// Sets the three Top Picks: each label on at most one place.
  Future<void> saveTopPicks(Map<TopPick, String?> picks) async {
    final uid = _uid;
    if (uid == null) throw StateError('not signed in');
    // Cleared first: a label moving from one place to another would
    // otherwise meet itself in the one-of-each index.
    await _client.from('profile_places').update({'top_pick': null}).eq('profile_id', uid);
    for (final e in picks.entries) {
      if (e.value == null) continue;
      await _client
          .from('profile_places')
          .update({'top_pick': e.key.key})
          .eq('profile_id', uid)
          .eq('business_id', e.value!);
    }
  }

  /// Places matching [query] by Hebrew or English name; with no query, the
  /// suggestions — the panel's recommended and featured places and the
  /// parks, best reviewed first.
  Future<List<UrbanPlace>> searchPlaces(String query) async {
    final q = query.trim().replaceAll(RegExp(r'[,()%*]'), ' ');
    var request = _client.from('businesses').select(_placeColumns).eq('status', 'active');
    if (q.isNotEmpty) {
      request = request.or('name.ilike.%$q%,name_en.ilike.%$q%');
    } else {
      request = request.or('is_recommended.eq.true,is_featured.eq.true,kind.eq.park');
    }
    final rows = await (q.isNotEmpty
        ? request.order('review_count', ascending: false).limit(20)
        : request
            .order('is_recommended', ascending: false)
            .order('review_count', ascending: false)
            .limit(20));
    return [for (final r in List<Map<String, dynamic>>.from(rows)) UrbanPlace.fromBusiness(r)];
  }

  Future<bool> usernameAvailable(String name) async {
    final ok = await _client.rpc('username_available', params: {'p_username': name});
    return ok == true;
  }

  Future<List<String>> suggestUsernames(String base) async {
    final rows = await _client.rpc('suggest_usernames', params: {'p_base': base});
    return List<String>.from((rows as List?) ?? const []);
  }

  Future<void> setUsername(String name) => _update({'username': name.trim().toLowerCase()});

  /// Another resident's profile, as `urban_profile()` allows: null when it
  /// is private, missing, or its owner is blocked.
  Future<UrbanProfile?> byUsername(String username) async {
    final j = await _client.rpc('urban_profile', params: {'p_username': username});
    if (j is! Map) return null;
    return UrbanProfile.fromFunction(Map<String, dynamic>.from(j));
  }
}

final urbanProfileRepositoryProvider = Provider((ref) => UrbanProfileRepository());

/// The signed-in person's own Urban Profile, read again when the account
/// changes.
final myUrbanProfileProvider = FutureProvider.autoDispose<UrbanProfile?>((ref) {
  ref.watch(authProvider.select((u) => (u?.id, u?.avatarUrl, u?.name, u?.neighborhood)));
  return ref.watch(urbanProfileRepositoryProvider).mine();
});

final urbanProfileByUsernameProvider = FutureProvider.autoDispose.family<UrbanProfile?, String>(
  (ref, username) => ref.watch(urbanProfileRepositoryProvider).byUsername(username),
);

/// A username to start from: the name in Latin letters where it is written
/// in them, else the e-mail's local part — the database then finds free ones
/// near it (`suggest_usernames`).
String usernameSeed(String name, String email) {
  final latin = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.').replaceAll(RegExp(r'^\.+|\.+$'), '');
  if (latin.length >= 3) return latin;
  final local = email.split('@').first.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.]'), '');
  return local.length >= 3 ? local : 'resident';
}
