import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val propertiesFile = rootProject.file("local.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(::load)
    }
}
val mapsApiKey = providers.environmentVariable("ANDROID_GOOGLE_MAPS_API_KEY").orNull
    ?.trim()
    ?.takeIf(String::isNotEmpty)
    ?: localProperties.getProperty("MAPS_API_KEY")?.trim()?.takeIf(String::isNotEmpty)
    ?: "NOT_CONFIGURED"
val releaseSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(::load)
    }
}

fun releaseSigningValue(propertyName: String, environmentName: String): String? =
    providers.environmentVariable(environmentName).orNull
        ?.trim()
        ?.takeIf(String::isNotEmpty)
        ?: releaseSigningProperties.getProperty(propertyName)
            ?.trim()
            ?.takeIf(String::isNotEmpty)

val releaseStoreFile = releaseSigningValue("storeFile", "ANDROID_KEYSTORE_PATH")
val releaseStorePassword =
    releaseSigningValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = releaseSigningValue("keyAlias", "ANDROID_KEY_ALIAS")
val releaseKeyPassword =
    releaseSigningValue("keyPassword", "ANDROID_KEY_PASSWORD")
val releaseSigningValues = listOf(
    releaseStoreFile,
    releaseStorePassword,
    releaseKeyAlias,
    releaseKeyPassword,
)
val releaseSigningConfigured = releaseSigningValues.all { it != null }

require(releaseSigningValues.none { it != null } || releaseSigningConfigured) {
    "Android release signing must be either fully configured or fully absent."
}
if (releaseSigningConfigured) {
    require(rootProject.file(releaseStoreFile!!).isFile) {
        "Android release signing keystore is unavailable."
    }
}

android {
    namespace = "com.xniw.clientmerchandisecontrol"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.xniw.clientmerchandisecontrol"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            if (releaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
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
    testImplementation("junit:junit:4.13.2")
}
