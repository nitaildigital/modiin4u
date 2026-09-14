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
