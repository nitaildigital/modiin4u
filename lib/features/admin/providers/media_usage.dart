import '../../../core/supabase/supabase_config.dart';
import '../admin_language.dart';

/// One place a stored file is shown: a row, and the column that holds its
/// address.
class MediaUse {
  /// The table — `businesses`, `articles` — or `entity_media` for a gallery.
  final String source;

  /// The column, or for a gallery `business:gallery`.
  final String column;
  final String? rowId;

  /// The row's name or title, when it has one.
  final String? label;

  const MediaUse({
    required this.source,
    required this.column,
    this.rowId,
    this.label,
  });

  /// "גלריה של עסק · פיצה צ׳אקרה", "עסקים · לוגו · מיכליס".
  String describe() {
    final where = source == 'entity_media'
        ? switch (column.split(':').first) {
            'business' => tr('גלריה של עסק', 'Business gallery'),
            'neighborhood' => tr('גלריה של שכונה', 'Neighbourhood gallery'),
            final other => tr('גלריה ($other)', 'Gallery ($other)'),
          }
        : '${_tables[source] ?? source} · ${_columns[column] ?? column}';
    final name = (label ?? '').trim();
    return name.isEmpty ? where : '$where · $name';
  }

  static Map<String, String> get _tables => {
    'businesses': tr('עסקים', 'Businesses'),
    'articles': tr('כתבות', 'Articles'),
    'events': tr('אירועים', 'Events'),
    'offers': tr('מבצעים', 'Deals'),
    'campaigns': tr('קמפיינים', 'Campaigns'),
    'categories': tr('קטגוריות', 'Categories'),
    'neighborhoods': tr('שכונות', 'Neighbourhoods'),
    'listings': tr('נדל״ן', 'Real estate'),
    'real_estate_agents': tr('סוכנים', 'Agents'),
    'parking_lots': tr('חניונים', 'Car parks'),
    'media': tr('ספריית המדיה', 'Media library'),
    'profiles': tr('פרופילים', 'Profiles'),
  };

  static Map<String, String> get _columns => {
    'logo_url': tr('לוגו', 'Logo'),
    'cover_url': tr('תמונת כריכה', 'Cover image'),
    'og_image_url': tr('תמונת שיתוף', 'Share image'),
    'og_image': tr('תמונת שיתוף', 'Share image'),
    'featured_image': tr('תמונת כריכה', 'Cover image'),
    'body': tr('בתוך הטקסט', 'Inside the text'),
    'image_url': tr('תמונה', 'Image'),
    'gallery': tr('גלריה', 'Gallery'),
    'desktop_image': tr('תמונה למחשב', 'Desktop image'),
    'mobile_image': tr('תמונה לנייד', 'Mobile image'),
    'photo_url': tr('תמונה', 'Image'),
    'avatar_url': tr('תמונת פרופיל', 'Profile photo'),
    'url': tr('קובץ', 'File'),
  };
}

/// Every row that shows the file at [path] in the `media` bucket.
///
/// Asked of the database (`media_usage`, migration 00034), which searches
/// every text column of every table with row security set aside: an address
/// is copied into whatever uses it, and a list of columns kept here would
/// miss the next table, and would not see rows the panel's reads are not
/// shown. [mediaId] names the library row being asked about, which then does
/// not count as a use of itself, and brings in the galleries that point at
/// it by id.
Future<List<MediaUse>> mediaUsage(String path, {String? mediaId}) async {
  final rows = await SupabaseConfig.client.rpc(
    'media_usage',
    params: {'p_path': path, 'p_media_id': mediaId},
  );
  return [
    for (final r in List<Map<String, dynamic>>.from(rows as List))
      MediaUse(
        source: r['source'] as String? ?? '',
        column: r['column_name'] as String? ?? '',
        rowId: r['row_id'] as String?,
        label: r['label'] as String?,
      ),
  ];
}

/// The object's path when [url] is a file in our `media` bucket, whether
/// the plain public address or storage's resized one; null for anything
/// else — a picture on the WordPress site, a typed address, an empty field.
String? mediaBucketPath(String? url) {
  final u = (url ?? '').trim();
  if (u.isEmpty) return null;
  if (!u.startsWith(SupabaseConfig.supabaseUrl)) return null;
  for (final marker in const [
    '/storage/v1/object/public/media/',
    '/storage/v1/render/image/public/media/',
  ]) {
    final i = u.indexOf(marker);
    if (i == -1) continue;
    final path = Uri.decodeFull(
      u.substring(i + marker.length).split('?').first,
    );
    return path.isEmpty ? null : path;
  }
  return null;
}
