import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read properties from key.properties file
val keyPropertiesFile = rootProject.file("../android/key.properties") // Adjusted path relative to rootProject
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

android {
    namespace = "com.example.polish_learning_app"
    compileSdk = flutter.compileSdkVersion
    // ndkVersion = flutter.ndkVersion // Comment out or remove the old line
    ndkVersion = "27.0.12077973" // Set the required NDK version

    // Add signingConfigs block
    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = keyProperties["storeFile"]?.let { file(it) }
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hamilcar1026.polish_learning_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use the release signing config
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

// Add the dependencies block for Firebase
dependencies {
    // Import the Firebase BoM
    // Make sure to use the latest version of the BoM
    implementation(platform("com.google.firebase:firebase-bom:33.2.0"))

    // Add the dependency for Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Add other Firebase dependencies here as needed, without specifying versions
    // Example: implementation("com.google.firebase:firebase-auth")
    // Example: implementation("com.google.firebase:firebase-firestore")
}
