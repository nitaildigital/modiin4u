/// What a person has chosen to be told about, and what the app may use.
///
/// Kept apart from `UserModel` because it is read and written on its own: the
/// settings screen is the only place that touches it, and a toggle should not
/// rewrite a name or an avatar on its way to the database.
class NotificationPreferences {
  /// The master switch. With this off, nothing is sent whatever the topics say.
  final bool pushEnabled;

  final bool news;
  final bool deals;
  final bool neighborhood;
  final bool realestate;

  /// Access the person has granted the app.
  final bool locationEnabled;
  final bool healthEnabled;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.news = true,
    this.deals = true,
    this.neighborhood = true,
    this.realestate = false,
    this.locationEnabled = false,
    this.healthEnabled = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool flag(String key, {bool fallback = false}) =>
        json[key] as bool? ?? fallback;

    return NotificationPreferences(
      pushEnabled: flag('push_enabled', fallback: true),
      news: flag('notify_news', fallback: true),
      deals: flag('notify_deals', fallback: true),
      neighborhood: flag('notify_neighborhood', fallback: true),
      realestate: flag('notify_realestate'),
      locationEnabled: flag('location_enabled'),
      healthEnabled: flag('health_enabled'),
    );
  }

  Map<String, dynamic> toJson() => {
    'push_enabled': pushEnabled,
    'notify_news': news,
    'notify_deals': deals,
    'notify_neighborhood': neighborhood,
    'notify_realestate': realestate,
    'location_enabled': locationEnabled,
    'health_enabled': healthEnabled,
  };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? news,
    bool? deals,
    bool? neighborhood,
    bool? realestate,
    bool? locationEnabled,
    bool? healthEnabled,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      news: news ?? this.news,
      deals: deals ?? this.deals,
      neighborhood: neighborhood ?? this.neighborhood,
      realestate: realestate ?? this.realestate,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      healthEnabled: healthEnabled ?? this.healthEnabled,
    );
  }
}
