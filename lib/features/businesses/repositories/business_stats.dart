import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_config.dart';

/// What can be counted on a business page (migration 00048).
enum BusinessStat {
  view,
  call,
  website,
  whatsapp,
  directions,
  share,
  instagram,
}

/// Counts what people do on a business page, for the client's statistics:
/// the page opened, and each of its buttons pressed.
///
/// Nothing about the person is sent: the business, what was done, app or
/// web, and a random id this browser or phone made for itself, so the panel
/// can tell ten visits from ten visitors. A view is counted once per visitor
/// per business per half hour by the database itself.
///
/// It never holds the page up and never fails it: the button does its job
/// whether the count reached the database or not.
class BusinessStats {
  BusinessStats._();

  static const _kVisitorKey = 'stats_visitor';
  static Future<String>? _visitor;

  static Future<String> _visitorId() => _visitor ??= () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kVisitorKey);
      if (saved != null && saved.length >= 8) return saved;
      final id = _randomId();
      await prefs.setString(_kVisitorKey, id);
      return id;
    } catch (_) {
      // Storage the browser will not open: a visitor for this visit only.
      return _randomId();
    }
  }();

  /// The same random id, for the other pages that count visits (articles).
  static Future<String> visitorId() => _visitorId();

  static String _randomId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  /// Counts a view of [articleId] (00066), in the background, as a business
  /// view is: once per visitor per article per half hour, by the database.
  static void recordArticleView(String articleId) {
    () async {
      try {
        await SupabaseConfig.client.rpc('record_article_view', params: {
          'p_article': articleId,
          'p_platform': kIsWeb ? 'web' : 'app',
          'p_visitor': await _visitorId(),
        });
      } catch (e) {
        debugPrint('Article view not recorded: $e');
      }
    }();
  }

  /// Records [stat] for [businessId], in the background.
  static void record(String businessId, BusinessStat stat) {
    () async {
      try {
        await SupabaseConfig.client.rpc('record_business_event', params: {
          'p_business': businessId,
          'p_kind': stat.name,
          'p_platform': kIsWeb ? 'web' : 'app',
          'p_visitor': await _visitorId(),
        });
      } catch (e) {
        debugPrint('Business statistics not recorded: $e');
      }
    }();
  }
}
