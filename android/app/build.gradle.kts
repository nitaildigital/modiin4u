plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "il.co.modiin4u.modiin4u"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "il.co.modiin4u.modiin4u"
        minSdk = flutter.minSdkVersion       // 24 (Android 7.0)
        targetSdk = flutter.targetSdkVersion  // 36 (Android 16) — meets Aug 2026 requirement
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Required for image_picker on API 33+
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Replace with your release keystore before Play Store upload:
            //   1. Generate keystore: keytool -genkey -v -keystore ~/modiin4u-release.jks ...
            //   2. Create android/key.properties with storeFile, storePassword, keyAlias, keyPassword
            //   3. Load it here and reference the release signingConfig
            signingConfig = signingConfigs.getByName("debug")

            // Minification & shrinking for smaller APK
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
