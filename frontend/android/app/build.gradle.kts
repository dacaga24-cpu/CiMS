import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Càrrega de la configuració de signatura release des de `android/key.properties`.
// El fitxer NO està al repositori (vegeu `.gitignore`) i conté la ruta i passwords
// del keystore. Si no existeix, la signatura release simplement queda sense
// configurar i la build de release fallarà — això evita signar accidentalment
// amb la clau de debug.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "cat.bemen3.cims"
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
        applicationId = "cat.bemen3.cims"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Configuració de la signatura per a builds de release. Llegeix les
        // credencials de `key.properties` (gitignored). Si el fitxer no existeix
        // les variables són null i la creació del signingConfig fallaria, així
        // que només l'inicialitzem quan tenim les properties carregades.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // `storeFile` es resol relatiu al rootProject (la carpeta
                // `android/`), no a `android/app/` on viu aquest fitxer.
                // Així el `storeFile=cims-release.keystore` del
                // `key.properties` apunta a `android/cims-release.keystore`,
                // que és la ubicació canònica recomanada per la docu de
                // Flutter (https://flutter.dev/to/reference-keystore).
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Si la signingConfig "release" existeix l'usem; si no, caiem a
            // debug perquè `flutter run --release` segueixi funcionant en
            // entorns de desenvolupament sense keystore. La build oficial per
            // entregar al tribunal SEMPRE ha d'usar la "release", verificable
            // amb `apksigner verify --print-certs` sobre l'APK final.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
            // No activem isMinifyEnabled / isShrinkResources: trenca
            // `flutter_secure_storage` (usa reflection) i no aporta valor per
            // a la distribució limitada que té aquesta APK.
        }
    }
}

flutter {
    source = "../.."
}
