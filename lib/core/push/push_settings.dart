import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What this device has chosen to be told about.
///
/// Kept on the device, not on a profile: the client was promised that anyone
/// who installs the app gets notifications without an account. The push
/// service copies it to the device's row in `push_devices`, which is what
/// the sender reads (migration 00045).
class PushSettings {
  /// The master switch. Off, nothing is sent whatever the topics say.
  final bool enabled;

  /// Each new article, event and business is sent to these automatically.
  final bool news;
  final bool events;
  final bool businesses;

  /// Sent by hand from the panel.
  final bool deals;
  final bool realestate;

  /// Updates the panel sends to one neighbourhood, for the one chosen here.
  final bool neighborhood;
  final String? neighborhoodId;

  /// Someone replied in a review conversation this person is part of. Only
  /// reaches a device someone is signed in on.
  final bool replies;

  /// Each new job opening (00069).
  final bool jobs;

  const PushSettings({
    this.enabled = true,
    this.news = true,
    this.events = true,
    this.businesses = true,
    this.deals = true,
    this.realestate = false,
    this.neighborhood = true,
    this.neighborhoodId,
    this.replies = true,
    this.jobs = true,
  });

  factory PushSettings.fromJson(Map<String, dynamic> json) {
    bool flag(String key, bool fallback) => json[key] as bool? ?? fallback;
    const d = PushSettings();
    return PushSettings(
      enabled: flag('enabled', d.enabled),
      news: flag('news', d.news),
      events: flag('events', d.events),
      businesses: flag('businesses', d.businesses),
      deals: flag('deals', d.deals),
      realestate: flag('realestate', d.realestate),
      neighborhood: flag('neighborhood', d.neighborhood),
      neighborhoodId: json['neighborhood_id'] as String?,
      replies: flag('replies', d.replies),
      jobs: flag('jobs', d.jobs),
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'news': news,
    'events': events,
    'businesses': businesses,
    'deals': deals,
    'realestate': realestate,
    'neighborhood': neighborhood,
    'neighborhood_id': neighborhoodId,
    'replies': replies,
    'jobs': jobs,
  };

  PushSettings copyWith({
    bool? enabled,
    bool? news,
    bool? events,
    bool? businesses,
    bool? deals,
    bool? realestate,
    bool? neighborhood,
    String? neighborhoodId,
    bool? replies,
    bool? jobs,
  }) {
    return PushSettings(
      enabled: enabled ?? this.enabled,
      news: news ?? this.news,
      events: events ?? this.events,
      businesses: businesses ?? this.businesses,
      deals: deals ?? this.deals,
      realestate: realestate ?? this.realestate,
      neighborhood: neighborhood ?? this.neighborhood,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      replies: replies ?? this.replies,
      jobs: jobs ?? this.jobs,
    );
  }
}

final pushSettingsProvider =
    StateNotifierProvider<PushSettingsNotifier, PushSettings>((ref) {
      return PushSettingsNotifier();
    });

class PushSettingsNotifier extends StateNotifier<PushSettings> {
  static const _key = 'push_settings';

  PushSettingsNotifier() : super(const PushSettings()) {
    _restore();
  }

  /// Set once something is changed in this run, so the saved settings —
  /// read a moment after start — do not overwrite it.
  bool _changed = false;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == null || _changed || !mounted) return;
      state = PushSettings.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    } catch (_) {
      // Unreadable storage leaves the defaults in place.
    }
  }

  Future<void> update(PushSettings next) async {
    _changed = true;
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(next.toJson()));
    } catch (_) {
      // The change still holds for this run.
    }
  }
}
