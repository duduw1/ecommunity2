import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Função para carregar variáveis do arquivo .env
fun loadEnv(): Properties {
    val envFile = rootProject.file("../.env")
    val properties = Properties()
    if (envFile.exists()) {
        properties.load(envFile.inputStream())
    }
    return properties
}

val env = loadEnv()

android {
    namespace = "com.example.ecommunity"
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
        applicationId = "com.example.ecommunity"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Injeta a chave do .env no Manifesto
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = env.getProperty("GOOGLE_MAPS_API_KEY") ?: ""
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
