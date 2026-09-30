import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_config.dart';
import '../models/municipal_place.dart';

/// The shown places on one Municipal tile, in the panel's order and then by
/// name. Row security returns only the shown ones to the public.
final municipalPlacesProvider =
    FutureProvider.autoDispose.family<List<MunicipalPlace>, MunicipalSection>((
      ref,
      section,
    ) async {
      final rows = await SupabaseConfig.client
          .from('municipal_places')
          .select(
            'id, category, name, name_en, address, phone, notes, latitude, longitude, source',
          )
          .inFilter('category', section.categories)
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(
        rows,
      ).map(MunicipalPlace.fromJson).toList();
    });
