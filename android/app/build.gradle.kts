import java.util.Properties
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val callbackDefines = (project.findProperty("dart-defines") as String?).orEmpty()
    .split(",").filter(String::isNotEmpty).associate { encoded ->
        val pair = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8).split("=", limit = 2)
        require(pair.size == 2) { "Invalid Dart define" }
        pair[0] to pair[1]
    }
val callbackEnabled = callbackDefines["GOOGLE_AUTH_ENABLED"] == "true"
val callbackHost = if (callbackEnabled) callbackDefines["AUTH_CALLBACK_VERIFIED_HOST"].orEmpty()
    else "clientmerchandisecontrol.invalid"
if (callbackEnabled) {
    require(callbackDefines["APP_ENV"] == "staging" &&
        callbackHost.matches(Regex("(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\\.)+[a-z]{2,63}")) &&
        !callbackHost.matches(Regex(".*\\.(invalid|localhost|test|example)")) &&
        callbackDefines["AUTH_REDIRECT_URI"] == "https://$callbackHost/auth-callback/") {
        "OAuth callback requires the approved staging host and exact HTTPS redirect"
    }
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
        manifestPlaceholders["AUTH_CALLBACK_HOST"] = callbackHost
        manifestPlaceholders["AUTH_CALLBACK_VERIFY"] = callbackEnabled.toString()
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
