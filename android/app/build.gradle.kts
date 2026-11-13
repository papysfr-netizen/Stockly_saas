import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 🔑 Clé de signature officielle de Nguli (jamais dans Git) :
//  - sur GitHub : créée à partir des « secrets » du dépôt (.github/workflows/apk.yml)
//  - sur un ordinateur : android/key.properties + le fichier .jks, si on les a
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val aUneCle = keystorePropertiesFile.exists()
if (aUneCle) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.stockly_saas"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identifiant DÉFINITIF sur le Play Store : ne plus jamais le changer.
        applicationId = "com.nguli.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (aUneCle) {
                // Sur GitHub, les mots de passe arrivent tels quels par
                // l'environnement (aucun caractère spécial n'est déformé).
                keyAlias = System.getenv("NGULI_KEY_ALIAS")
                    ?: keystoreProperties["keyAlias"] as String
                keyPassword = System.getenv("NGULI_KEY_PASSWORD")
                    ?: keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = System.getenv("NGULI_KEYSTORE_PASSWORD")
                    ?: keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Sans la clé officielle (ordinateur sans key.properties), on signe
            // avec la clé de test : l'APK marche, mais NE PEUT PAS mettre à jour
            // une version installée avec la clé officielle.
            signingConfig = if (aUneCle) signingConfigs.getByName("release")
                            else signingConfigs.getByName("debug")
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