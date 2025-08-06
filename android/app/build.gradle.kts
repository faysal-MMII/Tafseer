plugins {
    id("com.android.application")
    id("kotlin-android")
    // Firebase plugins
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // Flutter plugin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dev.faisal.tafseer"
    compileSdk = 35  // Updated from 34 to 35
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        // Enable desugaring
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
    
    defaultConfig {
        applicationId = "dev.faisal.tafseer"
        minSdk = 23  // Updated from 21 to 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Enable multidex support
        multiDexEnabled = true
    }
    
    buildTypes {
        release {
            // Configure minification and resource shrinking
            isMinifyEnabled = true
            // Disabled resource shrinking to prevent potential issues with Flutter resources
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            // Enable Crashlytics for release builds
            configure<com.google.firebase.crashlytics.buildtools.gradle.CrashlyticsExtension> {
                mappingFileUploadEnabled = true
            }
            // Your existing signing config
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase Crashlytics dependencies
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    
    // Add these lines for desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Add this for multidex support
    implementation("androidx.multidex:multidex:2.0.1")
}
