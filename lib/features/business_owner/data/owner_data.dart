import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../businesses/models/business.dart';
import '../../deals/models/offer.dart';

/// What a business owner reads and writes about their own business: its page,
/// hours, photos, deals, and requests to promote them. The rules are 00051's
/// (an owner's edits are live at once) and 00069's (promotion is the panel's
/// to grant).

/// A promotion request, as the business and the panel see it.
class PromotionRequest {
  final String id;
  final String entityType; // business | offer | job
  final String entityId;
  final String businessId;
  final int days;
  final String? message;
  final String status; // pending | approved | declined | cancelled
  final String? reason;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final DateTime? endsAt;

  // From `promotion_target`, filled where the screen asks for it.
  final String? title;
  final String? imageUrl;
  final String? businessName;

  const PromotionRequest({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.businessId,
    required this.days,
    this.message,
    required this.status,
    this.reason,
    required this.createdAt,
    this.decidedAt,
    this.endsAt,
    this.title,
    this.imageUrl,
    this.businessName,
  });

  factory PromotionRequest.fromJson(Map<String, dynamic> j) {
    final b = j['businesses'];
    return PromotionRequest(
      id: j['id'] as String,
      entityType: j['entity_type'] as String,
      entityId: j['entity_id'] as String,
      businessId: j['business_id'] as String,
      days: (j['days'] as num).toInt(),
      message: j['message'] as String?,
      status: (j['status'] as String?) ?? 'pending',
      reason: j['reason'] as String?,
      createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      decidedAt: DateTime.tryParse(j['decided_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(j['ends_at'] as String? ?? ''),
      businessName: b is Map ? b['name'] as String? : null,
    );
  }

  PromotionRequest withTarget(String? title, String? imageUrl) => PromotionRequest(
    id: id,
    entityType: entityType,
    entityId: entityId,
    businessId: businessId,
    days: days,
    message: message,
    status: status,
    reason: reason,
    createdAt: createdAt,
    decidedAt: decidedAt,
    endsAt: endsAt,
    title: title,
    imageUrl: imageUrl,
    businessName: businessName,
  );
}

class OwnerRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  /// The owner's business, whatever its status — a pending one included,
  /// which the public lists never show.
  Future<Business?> fetchBusiness(String id) async {
    final row = await _client
        .from('businesses')
        .select('*, neighborhoods!businesses_neighborhood_id_fkey(id, name, name_en, slug), business_hours(*)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Business.fromJson(row);
  }

  Future<void> updateBusiness(String id, Map<String, dynamic> patch) =>
      _client.from('businesses').update(patch).eq('id', id);

  /// Opening hours, a row per day, 0 = Sunday. A day that is not open is
  /// stored closed rather than left out, so the page says so.
  Future<void> saveHours(String businessId, Map<int, ({String open, String close})?> byDay) async {
    final rows = [
      for (final e in byDay.entries)
        {
          'business_id': businessId,
          'day_of_week': e.key,
          'open_time': e.value?.open,
          'close_time': e.value?.close,
          'is_closed': e.value == null,
        },
    ];
    await _client.from('business_hours').upsert(rows, onConflict: 'business_id,day_of_week');
  }

  /// A file under `businesses/<id>/` (logo, cover, gallery — 00051) or
  /// `offers/<id>/` (a deal's picture — 00069).
  Future<String> upload({
    required String folder,
    required String businessId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final dot = fileName.lastIndexOf('.');
    var ext = dot == -1 ? '.jpg' : fileName.substring(dot).toLowerCase();
    if (!const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext)) ext = '.jpg';
    final mime = ext == '.png' ? 'image/png' : ext == '.webp' ? 'image/webp' : 'image/jpeg';
    final tail = Random().nextInt(0x7fffffff).toRadixString(16);
    final path = '$folder/$businessId/${DateTime.now().microsecondsSinceEpoch}_$tail$ext';
    await _client.storage
        .from('media')
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    return _client.storage.from('media').getPublicUrl(path);
  }

  /// Adds a photo to the business's gallery, at the end, as the panel's
  /// gallery editor stores it.
  Future<void> addGalleryPhoto({
    required String businessId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final url = await upload(folder: 'businesses', businessId: businessId, fileName: fileName, bytes: bytes);
    final path = url.split('/object/public/media/').last;
    final existing = await _client
        .from('entity_media')
        .select('id')
        .eq('entity_type', 'business')
        .eq('entity_id', businessId)
        .eq('role', 'gallery');
    final media = await _client
        .from('media')
        .insert({
          'file_name': path.split('/').last,
          'file_path': path,
          'url': url,
          'mime_type': path.endsWith('.png') ? 'image/png' : 'image/jpeg',
          'size_bytes': bytes.lengthInBytes,
          'folder': 'businesses/$businessId',
          'uploaded_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();
    await _client.from('entity_media').insert({
      'media_id': media['id'],
      'entity_type': 'business',
      'entity_id': businessId,
      'role': 'gallery',
      'sort_order': List<dynamic>.from(existing).length,
    });
  }

  // ── Deals ──

  static const _offerSelect =
      '*, businesses(id, name, name_en, logo_url, cover_url, address)';

  /// All the business's deals, live or not, newest first.
  Future<List<Offer>> fetchDeals(String businessId) async {
    final rows = await _client
        .from('offers')
        .select(_offerSelect)
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(Offer.fromJson).toList();
  }

  Future<Offer?> fetchDeal(String id) async {
    final row = await _client.from('offers').select(_offerSelect).eq('id', id).maybeSingle();
    return row == null ? null : Offer.fromJson(row);
  }

  /// Writes a deal — new, or over [id] — live at once (00051). Returns it.
  Future<Offer> saveDeal({String? id, required Map<String, dynamic> row}) async {
    final saved = id == null
        ? await _client.from('offers').insert(row).select(_offerSelect).single()
        : await _client.from('offers').update(row).eq('id', id).select(_offerSelect).single();
    return Offer.fromJson(saved);
  }

  /// Closes a deal: it stops showing and stops taking claims; claims already
  /// made keep their vouchers.
  Future<void> closeDeal(String id) =>
      _client.from('offers').update({'status': 'expired'}).eq('id', id);

  /// Deletes a deal nobody has claimed (00069 refuses the rest).
  Future<bool> deleteDeal(String id) async {
    final rows = await _client.from('offers').delete().eq('id', id).select('id');
    return List<dynamic>.from(rows).isNotEmpty;
  }

  // ── Promotions ──

  Future<String> requestPromotion({
    required String type,
    required String id,
    required int days,
    String? message,
  }) async {
    final rid = await _client.rpc('request_promotion', params: {
      'p_type': type,
      'p_id': id,
      'p_days': days,
      'p_message': message,
    });
    return rid as String;
  }

  Future<List<PromotionRequest>> myPromotionRequests(String businessId) async {
    final rows = await _client
        .from('promotion_requests')
        .select()
        .eq('business_id', businessId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).map(PromotionRequest.fromJson).toList();
  }

  /// The title and picture of what a request is for.
  Future<({String? title, String? imageUrl})> target(String type, String id) async {
    final rows = await _client.rpc('promotion_target', params: {'p_type': type, 'p_id': id});
    final list = List<Map<String, dynamic>>.from(rows as List);
    if (list.isEmpty) return (title: null, imageUrl: null);
    return (title: list.first['title'] as String?, imageUrl: list.first['image_url'] as String?);
  }
}

final ownerRepositoryProvider = Provider((ref) => OwnerRepository());

/// The id of the business the signed-in person owns, or null.
final myBusinessIdProvider = Provider<String?>(
  (ref) => ref.watch(authProvider.select((u) => u?.ownedBusinessId)),
);

final myBusinessProvider = FutureProvider.autoDispose<Business?>((ref) {
  final id = ref.watch(myBusinessIdProvider);
  if (id == null) return null;
  return ref.watch(ownerRepositoryProvider).fetchBusiness(id);
});

final myDealsProvider = FutureProvider.autoDispose<List<Offer>>((ref) {
  final id = ref.watch(myBusinessIdProvider);
  if (id == null) return const [];
  return ref.watch(ownerRepositoryProvider).fetchDeals(id);
});

final myPromotionRequestsProvider = FutureProvider.autoDispose<List<PromotionRequest>>((ref) {
  final id = ref.watch(myBusinessIdProvider);
  if (id == null) return const [];
  return ref.watch(ownerRepositoryProvider).myPromotionRequests(id);
});

/// The pending request for one thing, if any — so its Promote button says
/// "Requested" rather than letting a second be sent.
final pendingPromotionProvider = Provider.autoDispose.family<PromotionRequest?, String>((ref, entityId) {
  final list = ref.watch(myPromotionRequestsProvider).valueOrNull ?? const [];
  return list.where((r) => r.entityId == entityId && r.status == 'pending').firstOrNull;
});
