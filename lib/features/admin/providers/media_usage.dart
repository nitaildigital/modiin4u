import '../../../core/supabase/supabase_config.dart';

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
            'business' => 'גלריה של עסק',
            'neighborhood' => 'גלריה של שכונה',
            final other => 'גלריה ($other)',
          }
        : '${_tables[source] ?? source} · ${_columns[column] ?? column}';
    final name = (label ?? '').trim();
    return name.isEmpty ? where : '$where · $name';
  }

  static const _tables = {
    'businesses': 'עסקים',
    'articles': 'כתבות',
    'events': 'אירועים',
    'offers': 'מבצעים',
    'campaigns': 'קמפיינים',
    'categories': 'קטגוריות',
    'neighborhoods': 'שכונות',
    'listings': 'נדל״ן',
    'real_estate_agents': 'סוכנים',
    'parking_lots': 'חניונים',
    'media': 'ספריית המדיה',
    'profiles': 'פרופילים',
  };

  static const _columns = {
    'logo_url': 'לוגו',
    'cover_url': 'תמונת כריכה',
    'og_image_url': 'תמונת שיתוף',
    'og_image': 'תמונת שיתוף',
    'featured_image': 'תמונת כריכה',
    'body': 'בתוך הטקסט',
    'image_url': 'תמונה',
    'gallery': 'גלריה',
    'desktop_image': 'תמונה למחשב',
    'mobile_image': 'תמונה לנייד',
    'photo_url': 'תמונה',
    'avatar_url': 'תמונת פרופיל',
    'url': 'קובץ',
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
