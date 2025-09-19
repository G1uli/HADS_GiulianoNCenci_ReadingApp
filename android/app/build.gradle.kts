plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.reading_app"
    compileSdk = 36
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
    
    defaultConfig {
        applicationId = "com.example.reading_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
    }
    
    buildTypes {
        getByName("release") {
            // Disable resource shrinking or enable both resource and code shrinking
            isShrinkResources = false  // Add this line to disable resource shrinking
            isMinifyEnabled = false    // Ensure this is false for debug builds
        }
        getByName("debug") {
            isShrinkResources = false  // Add this line to disable resource shrinking
            isMinifyEnabled = false    // Ensure this is false for debug builds
        }
    }
}


flutter {
    source = "../.."
}
