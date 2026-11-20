
plugins {
    id("com.android.application")

    // Firebase
    id("com.google.gms.google-services")

    // Flutter
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ice_cream_mobile"

    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Habilitar desugaring para las notificaciones
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.ice_cream_mobile"

        minSdk = 24
        targetSdk = flutter.targetSdkVersion

        multiDexEnabled = true

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dependencia necesaria para core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
