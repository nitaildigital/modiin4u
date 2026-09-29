import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../../businesses/models/business.dart';
import '../../businesses/providers/business_providers.dart';

// ═══════════════════════════════════════════════════════════
// What the two web detail pages — a listing, and a neighbourhood — read
// beyond the listing row itself.
//
// Kept apart from `listing_providers.dart` and `neighborhood_providers.dart`
// because those serve the phone screens and the browse pages too, and these
// are shaped to what the desktop design draws.
// ═══════════════════════════════════════════════════════════

/// A neighbourhood's photographs, the one the admin set as its picture first.
///
/// `neighborhoods` holds a single `image_url`; the rest sit in `entity_media`
/// with `entity_type = 'neighborhood'`, the same polymorphic table the
/// business galleries use, so no column had to be added for them. The design
/// draws three panels and a "Show all photos" button; with one photo on file
/// the page draws one.
final neighborhoodPhotosProvider =
    FutureProvider.family<List<String>, String>((ref, id) async {
      final client = SupabaseConfig.client;

      final hood = await client
          .from('neighborhoods')
          .select('image_url')
          .eq('id', id)
          .maybeSingle();

      final rows = await client
          .from('entity_media')
          .select('sort_order, media(url)')
          .eq('entity_type', 'neighborhood')
          .eq('entity_id', id)
          .eq('role', 'gallery')
          .order('sort_order', ascending: true);

      final photos = <String>[];
      void add(Object? url) {
        if (url is String && url.trim().isNotEmpty && !photos.contains(url)) {
          photos.add(url);
        }
      }

      add(hood?['image_url']);
      for (final r in List<Map<String, dynamic>>.from(rows)) {
        add((r['media'] as Map?)?['url']);
      }
      return photos;
    });

/// Active businesses filed under one neighbourhood, the ones with a
/// photograph first — a card with a picture reads as a place, one without
/// reads as a gap, and the strip opens on the former.
final neighborhoodBusinessesProvider =
    FutureProvider.family<List<Business>, String>((ref, id) async {
      final rows = await ref
          .watch(businessRepositoryProvider)
          .fetchAll(status: 'active', neighborhoodId: id);
      final all = rows.map(Business.fromJson).toList();
      return [
        ...all.where((b) => (b.imageUrl ?? '').isNotEmpty),
        ...all.where((b) => (b.imageUrl ?? '').isEmpty),
      ];
    });

/// The two figures in the neighbourhood's stats box that the database can
/// answer: flats for sale there now, and businesses there.
///
/// The design's box has four; "Parks & Playgrounds" and "Schools &
/// Kindergardens" have no table behind them, so they are not drawn.
typedef NeighborhoodStats = ({int forSale, int businesses});

final neighborhoodStatsProvider =
    FutureProvider.family<NeighborhoodStats, String>((ref, id) async {
      final client = SupabaseConfig.client;

      final forSale = await client
          .from('listings')
          .select('id')
          .eq('neighborhood_id', id)
          .eq('status', 'active')
          .eq('kind', 'sale')
          .count();

      final businesses = await client
          .from('businesses')
          .select('id')
          .eq('neighborhood_id', id)
          .eq('status', 'active')
          .count();

      return (forSale: forSale.count, businesses: businesses.count);
    });

/// The ways to reach a listing's agent that the listing join leaves out.
///
/// `ListingRepository` joins the agent's name, agency, phone and photo — what
/// a card needs. The detail page's Contact button also offers WhatsApp and
/// email when the agent has them, so it reads those here rather than
/// widening a select every browse page pays for.
typedef AgentContact = ({String? phone, String? whatsapp, String? email});

final listingAgentContactProvider =
    FutureProvider.family<AgentContact?, String>((ref, agentId) async {
      final row = await SupabaseConfig.client
          .from('real_estate_agents')
          .select('phone, whatsapp, email')
          .eq('id', agentId)
          .maybeSingle();
      if (row == null) return null;

      String? clean(Object? v) =>
          v is String && v.trim().isNotEmpty ? v.trim() : null;
      return (
        phone: clean(row['phone']),
        whatsapp: clean(row['whatsapp']),
        email: clean(row['email']),
      );
    });
