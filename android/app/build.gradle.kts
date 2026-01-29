plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // kotlin-android yerine bu önerilir
    id("dev.flutter.flutter-gradle-plugin")

    // 🔥 Firebase'i aktif ediyoruz
    id("com.google.gms.google-services")
}

android {
    namespace = "com.rw.fitnessapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.rw.fitnessapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 🔥 Firebase SDK'larını buraya ekle
dependencies {
    // BOM: Firebase sürümlerini otomatik yönetir
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))

    // Temel servis: Analytics
    implementation("com.google.firebase:firebase-analytics")

    // Diğerleri (isteğe bağlı)
    // implementation("com.google.firebase:firebase-auth")
    // implementation("com.google.firebase:firebase-firestore")
    // implementation("com.google.firebase:firebase-storage")
}
