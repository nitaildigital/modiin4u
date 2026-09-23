# Flutter-specific ProGuard rules
# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / network
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class com.google.gson.** { *; }

# Google Fonts
-keep class com.google.android.gms.** { *; }

# image_picker
-keep class androidx.core.content.FileProvider { *; }

# Flutter's embedding references Play Core for deferred components, which this
# app does not use and does not ship. Without these R8 fails the release build
# on the missing classes.
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
