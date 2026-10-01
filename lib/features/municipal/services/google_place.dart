import 'dart:convert';

import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:http/http.dart' as http;

/// What Google Maps knows about a car park, fetched when someone opens it.
///
/// The client (1 Oct): show whatever Google has. Google's terms let the app
/// keep a place's ID (`parking_lots.google_place_id`) but not its details,
/// so these are asked for live, each time the page opens, and shown with
/// Google's attribution. Any field Google does not have is null and left out.
class GooglePlaceDetails {
  final String? name;
  final String? address;
  final List<String> hours;
  final double? rating;
  final int ratingCount;
  final List<GooglePhoto> photos;
  final bool? acceptsCards;
  final bool? acceptsDebit;
  final bool? cashOnly;
  final bool? acceptsNfc;
  final String? phone;
  final String? website;
  final String? mapsUri;

  const GooglePlaceDetails({
    this.name,
    this.address,
    this.hours = const [],
    this.rating,
    this.ratingCount = 0,
    this.photos = const [],
    this.acceptsCards,
    this.acceptsDebit,
    this.cashOnly,
    this.acceptsNfc,
    this.phone,
    this.website,
    this.mapsUri,
  });

  factory GooglePlaceDetails.fromJson(Map<String, dynamic> j) {
    final pay = j['paymentOptions'] as Map<String, dynamic>? ?? const {};
    return GooglePlaceDetails(
      name: (j['displayName'] as Map?)?['text'] as String?,
      address: j['formattedAddress'] as String?,
      hours: [
        for (final d in ((j['regularOpeningHours'] as Map?)?['weekdayDescriptions'] as List?) ?? const [])
          d as String,
      ],
      rating: (j['rating'] as num?)?.toDouble(),
      ratingCount: (j['userRatingCount'] as num?)?.toInt() ?? 0,
      photos: [
        for (final p in ((j['photos'] as List?) ?? const []).take(6))
          GooglePhoto(
            name: p['name'] as String,
            authors: [
              for (final a in (p['authorAttributions'] as List?) ?? const [])
                (a['displayName'] as String?) ?? '',
            ].where((s) => s.isNotEmpty).toList(),
          ),
      ],
      acceptsCards: pay['acceptsCreditCards'] as bool?,
      acceptsDebit: pay['acceptsDebitCards'] as bool?,
      cashOnly: pay['acceptsCashOnly'] as bool?,
      acceptsNfc: pay['acceptsNfc'] as bool?,
      phone: j['nationalPhoneNumber'] as String?,
      website: j['websiteUri'] as String?,
      mapsUri: j['googleMapsUri'] as String?,
    );
  }

  bool get hasPayment =>
      acceptsCards == true || acceptsDebit == true || cashOnly == true || acceptsNfc == true;
}

class GooglePhoto {
  /// Google's resource name, `places/…/photos/…`.
  final String name;

  /// Who took it — shown under the photo, as Google requires.
  final List<String> authors;
  const GooglePhoto({required this.name, required this.authors});
}

/// The key for this platform, each given at build time and each restricted
/// in Google Cloud to its own platform: the website's to the site's
/// addresses, the Android one to the app's package and signing certificate,
/// the iOS one to the app's bundle ID (tool/deploy_web.sh, tool/build_android.sh).
const _webKey = String.fromEnvironment('PLACES_WEB_KEY');
const _androidKey = String.fromEnvironment('PLACES_ANDROID_KEY');
const _iosKey = String.fromEnvironment('PLACES_IOS_KEY');

/// The signing certificate's SHA-1, which an Android-restricted key checks
/// on every request along with the package name.
const _androidCert = String.fromEnvironment('PLACES_ANDROID_CERT');
const _bundleId = 'il.co.modiin4u.modiin4u';

String get _key => kIsWeb
    ? _webKey
    : defaultTargetPlatform == TargetPlatform.iOS
    ? _iosKey
    : _androidKey;

/// Whether this build can ask Google at all.
bool get googlePlacesAvailable => _key.isNotEmpty;

/// The headers a platform-restricted key needs. The browser sends the page's
/// address itself.
Map<String, String> get googlePlacesHeaders => {
  'X-Goog-Api-Key': _key,
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...{
    'X-Android-Package': _bundleId,
    'X-Android-Cert': _androidCert.replaceAll(':', '').toUpperCase(),
  },
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
    'X-Ios-Bundle-Identifier': _bundleId,
};

/// A photo's address at the width the page draws it.
Uri googlePhotoUri(GooglePhoto photo, {int maxWidth = 900}) => Uri.parse(
  'https://places.googleapis.com/v1/${photo.name}/media?maxWidthPx=$maxWidth'
  // The browser cannot send a header with an <img>; the key goes in the
  // address, which the website's key allows from the site only.
  '${kIsWeb ? '&key=$_key' : ''}',
);

/// One request per page opened, asking only for what the page shows.
Future<GooglePlaceDetails?> fetchGooglePlace(String placeId, {required String language}) async {
  if (!googlePlacesAvailable) return null;
  try {
    final res = await http.get(
      Uri.parse('https://places.googleapis.com/v1/places/$placeId?languageCode=$language'),
      headers: {
        ...googlePlacesHeaders,
        'X-Goog-FieldMask':
            'displayName,formattedAddress,regularOpeningHours.weekdayDescriptions,'
            'rating,userRatingCount,photos,paymentOptions,nationalPhoneNumber,'
            'websiteUri,googleMapsUri',
      },
    );
    if (res.statusCode != 200) {
      debugPrint('Google place $placeId: ${res.statusCode} ${res.body}');
      return null;
    }
    return GooglePlaceDetails.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  } catch (e) {
    debugPrint('Google place $placeId: $e');
    return null;
  }
}
