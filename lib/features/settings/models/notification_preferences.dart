/// What the person has allowed the app to use, on their profile.
///
/// Notification choices used to live here too, on `profiles`; they moved to
/// the device (lib/core/push/push_settings.dart) because notifications need
/// no account. The `notify_*` and `push_enabled` columns 00016 added are no
/// longer read or written.
///
/// Kept apart from `UserModel` because it is read and written on its own: the
/// settings screen is the only place that touches it, and a toggle should not
/// rewrite a name or an avatar on its way to the database.
class NotificationPreferences {
  final bool locationEnabled;
  final bool healthEnabled;

  const NotificationPreferences({
    this.locationEnabled = false,
    this.healthEnabled = false,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      locationEnabled: json['location_enabled'] as bool? ?? false,
      healthEnabled: json['health_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'location_enabled': locationEnabled,
    'health_enabled': healthEnabled,
  };

  NotificationPreferences copyWith({bool? locationEnabled, bool? healthEnabled}) {
    return NotificationPreferences(
      locationEnabled: locationEnabled ?? this.locationEnabled,
      healthEnabled: healthEnabled ?? this.healthEnabled,
    );
  }
}
