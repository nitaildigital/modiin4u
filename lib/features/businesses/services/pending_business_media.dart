import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The logo and photographs picked at a business sign-up, kept on the phone
/// until the account can upload them.
///
/// Sign-up needs the address confirmed, so it returns no session, and storage
/// takes uploads from a signed-in account only. The business itself is
/// created from the sign-up's details by the database (00068); its pictures
/// wait here, in the app's own folder, and go up the first time that account
/// is signed in on this phone. Signed in on another phone first, the
/// business simply has no pictures yet.
///
/// Kept by e-mail address, the one thing known before the account has an id.
abstract final class PendingBusinessMedia {
  static Future<Directory> _dir(String email) async {
    final base = await getApplicationSupportDirectory();
    final key = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return Directory('${base.path}/pending_business/$key');
  }

  /// Copies the picked files, replacing anything kept for [email] before.
  /// Done before the account is created, so even a sign-up that comes back
  /// signed in finds them.
  static Future<void> save({
    required String email,
    XFile? logo,
    required List<XFile> photos,
  }) async {
    if (kIsWeb) return;
    final dir = await _dir(email);
    if (await dir.exists()) await dir.delete(recursive: true);
    if (logo == null && photos.isEmpty) return;
    await dir.create(recursive: true);
    if (logo != null) {
      await File('${dir.path}/logo${_extensionOf(logo.name)}')
          .writeAsBytes(await logo.readAsBytes());
    }
    for (var i = 0; i < photos.length; i++) {
      // Numbered so the order picked, and so the cover, is kept.
      final n = '$i'.padLeft(2, '0');
      await File('${dir.path}/photo_$n${_extensionOf(photos[i].name)}')
          .writeAsBytes(await photos[i].readAsBytes());
    }
  }

  /// Drops what was kept for [email] — after a sign-up that failed, so a
  /// later account at that address does not receive someone else's pictures.
  static Future<void> discard(String email) async {
    if (kIsWeb) return;
    try {
      final dir = await _dir(email);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static bool _running = false;

  /// Uploads whatever the signed-in account left from its sign-up, onto the
  /// business it owns. Each file is deleted once it is stored, so a run cut
  /// short carries on next time without storing anything twice.
  static Future<void> uploadForCurrentUser(SupabaseClient client) async {
    if (kIsWeb || _running) return;
    final user = client.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) return;
    _running = true;
    try {
      final dir = await _dir(email);
      if (!await dir.exists()) return;
      final files = (await dir.list().toList()).whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (files.isEmpty) {
        await dir.delete(recursive: true);
        return;
      }

      // The business the sign-up created. None yet means the database could
      // not create it; the pictures stay for when the panel assigns one.
      final business = await client
          .from('businesses')
          .select('id, logo_url, cover_url')
          .eq('owner_id', user.id)
          .order('created_at')
          .limit(1)
          .maybeSingle();
      if (business == null) return;
      final id = business['id'] as String;
      var hasCover = business['cover_url'] != null;

      final existing = await client
          .from('entity_media')
          .select('id')
          .eq('entity_type', 'business')
          .eq('entity_id', id)
          .eq('role', 'gallery');
      var order = List<dynamic>.from(existing).length;

      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final isLogo = name.startsWith('logo');
        final url = await _store(client, user.id, id, file, isLogo: isLogo, order: order);
        if (isLogo) {
          await client.from('businesses').update({'logo_url': url}).eq('id', id);
        } else {
          order++;
          // The first photograph heads the business page, as on the
          // apartment form.
          if (!hasCover) {
            await client.from('businesses').update({'cover_url': url}).eq('id', id);
            hasCover = true;
          }
        }
        await file.delete();
      }
      await dir.delete(recursive: true);
    } catch (e) {
      // Tried again at the next sign-in; nothing here may stop the app.
      debugPrint('pending business media: $e');
    } finally {
      _running = false;
    }
  }

  /// Puts one file under `businesses/<business id>/`, the folder an owner may
  /// upload to (00051). A photograph also gets its library row and its place
  /// in the gallery, as the panel's gallery editor writes them.
  static Future<String> _store(
    SupabaseClient client,
    String uid,
    String businessId,
    File file, {
    required bool isLogo,
    required int order,
  }) async {
    final ext = _extensionOf(file.path);
    final mime = _mimeOf(ext);
    final bytes = await file.readAsBytes();
    // Time plus a random tail, as the panel names them: two files stored in
    // the same instant must not collide.
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final fileName = '${isLogo ? 'logo_' : ''}${stamp}_$tail$ext';
    final folder = 'businesses/$businessId';
    final path = '$folder/$fileName';

    await client.storage
        .from('media')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    final url = client.storage.from('media').getPublicUrl(path);
    if (isLogo) return url;

    final media = await client
        .from('media')
        .insert({
          'file_name': fileName,
          'file_path': path,
          'url': url,
          'mime_type': mime,
          'size_bytes': bytes.lengthInBytes,
          'folder': folder,
          'uploaded_by': uid,
        })
        .select('id')
        .single();
    await client.from('entity_media').insert({
      'media_id': media['id'],
      'entity_type': 'business',
      'entity_id': businessId,
      'role': 'gallery',
      'sort_order': order,
    });
    return url;
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
