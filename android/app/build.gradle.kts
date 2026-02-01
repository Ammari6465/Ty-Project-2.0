import java.util.Properties
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.disaster_link"
    compileSdk = 36
    // Override to satisfy plugin requirements (flutter_plugin_android_lifecycle, google_maps_flutter_android)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.disaster_link"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Inject Google Maps API key from local.properties if provided.
        // Add MAPS_API_KEY=YOUR_KEY to android/local.properties (not committed).
    val localProps = Properties()
        val localPropsFile = rootProject.file("local.properties")
        if (localPropsFile.exists()) {
            localPropsFile.inputStream().use { localProps.load(it) }
        }
        val mapsApiKey = localProps.getProperty("MAPS_API_KEY")
        if (mapsApiKey != null && mapsApiKey.isNotBlank()) {
            resValue("string", "google_maps_key", mapsApiKey)
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM to manage versions
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))
    // Analytics (optional now, helps verify integration)
    implementation("com.google.firebase:firebase-analytics")
    // Authentication
    implementation("com.google.firebase:firebase-auth")
    // (Firestore and Messaging will be added later)
}
