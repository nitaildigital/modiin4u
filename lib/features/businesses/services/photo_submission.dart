import 'dart:math';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';

/// A photograph a resident sent for a business page (00071), as its sender
/// sees it: waiting for the panel, published, or declined with a reason.
class PhotoSubmission {
  final String id;
  final String url;
  final String? caption;
  final String status;
  final String? reason;
  final DateTime createdAt;

  const PhotoSubmission({
    required this.id,
    required this.url,
    this.caption,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory PhotoSubmission.fromJson(Map<String, dynamic> json) => PhotoSubmission(
    id: json['id'] as String,
    url: json['url'] as String,
    caption: json['caption'] as String?,
    status: json['status'] as String? ?? 'pending',
    reason: json['reason'] as String?,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}

/// The picked file is over [PhotoSubmissions.maxBytes].
class PhotoTooLarge implements Exception {
  const PhotoTooLarge();
}

/// The panel blocked this account (00054), so the database would refuse the
/// row — found out before the file is uploaded, so none is left behind with
/// no submission pointing at it.
class PhotoSenderBlocked implements Exception {
  const PhotoSenderBlocked();
}

/// Sending a photograph of a business, and reading back one's own.
///
/// The file goes first, to `submissions/<your id>/` in the public `media`
/// bucket — the one folder a resident may upload to there — and then the
/// row that puts it in the panel's queue. It reaches the business's gallery
/// only when the panel approves it (`admin_decide_photo`).
abstract final class PhotoSubmissions {
  static const maxBytes = 10 * 1024 * 1024;

  static Future<void> send({
    required String businessId,
    required Uint8List bytes,
    required String fileName,
    String? caption,
  }) async {
    if (bytes.lengthInBytes > maxBytes) throw const PhotoTooLarge();
    final client = SupabaseConfig.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('signed-out');

    try {
      if (await client.rpc('is_banned_user') == true) {
        throw const PhotoSenderBlocked();
      }
    } on PhotoSenderBlocked {
      rethrow;
    } catch (_) {
      // Not known; the database still refuses a blocked account's row.
    }

    final ext = _extensionOf(fileName);
    // Time plus a random tail, as the panel names its files: two sent in the
    // same instant must not collide.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final path = 'submissions/$uid/${stamp}_$tail$ext';

    await client.storage
        .from('media')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mimeOf(ext), upsert: false),
        );
    final url = client.storage.from('media').getPublicUrl(path);

    final text = caption?.trim() ?? '';
    await client.from('photo_submissions').insert({
      'entity_type': 'business',
      'entity_id': businessId,
      'profile_id': uid,
      'file_path': path,
      'url': url,
      'caption': text.isEmpty ? null : text,
    });
  }

  /// This person's photographs of one business still waiting for the panel,
  /// newest first. Approved ones are in the gallery itself.
  static Future<List<PhotoSubmission>> pendingOf(String businessId) async {
    final client = SupabaseConfig.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return const [];
    final rows = await client
        .from('photo_submissions')
        .select('id, url, caption, status, reason, created_at')
        .eq('entity_type', 'business')
        .eq('entity_id', businessId)
        .eq('profile_id', uid)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(PhotoSubmission.fromJson).toList();
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = name.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext) ? ext : '.jpg';
  }

  static String _mimeOf(String ext) => switch (ext) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
