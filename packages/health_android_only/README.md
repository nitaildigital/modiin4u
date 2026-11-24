# health 13.3.1, Android only

A copy of [carp health 13.3.1](https://pub.dev/packages/health/versions/13.3.1)
(`lib/` and `android/` byte for byte, MIT licence in `LICENSE`), used through
`dependency_overrides` in the app's `pubspec.yaml`.

The only change is in `pubspec.yaml`: the plugin declares Android and not iOS.
Android reads Health Connect through it exactly as before. The iPhone app
counts steps with Core Motion instead (`MotionSteps` in
`ios/Runner/AppDelegate.swift`), and since 24 Nov 2026 contains no HealthKit
at all — App Review rejected 1.0 (4) under Guideline 5.1.1(ix), and the
published package would still link HealthKit into the iPhone build.

To move to a newer `health`, copy its `lib/`, `android/`, `LICENSE` and
`pubspec.yaml` here again and take `ios:` out of the plugin's platforms.
