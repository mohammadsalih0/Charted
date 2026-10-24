import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read local.properties if present
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

// Parse version directly from pubspec.yaml as the single source of truth
fun parsePubspecVersion(): Pair<String, Int> {
    val pubspecFile = rootProject.file("../pubspec.yaml")
    if (pubspecFile.exists()) {
        val versionLine = pubspecFile.useLines { lines ->
            lines.firstOrNull { line ->
                val trimmed = line.trim()
                trimmed.startsWith("version:") && !trimmed.startsWith("#")
            }
        }
        if (versionLine != null) {
            val rawVersion = versionLine.substringAfter("version:").trim()
                .removeSurrounding("\"", "\"")
                .removeSurrounding("'", "'")
            val parts = rawVersion.split("+")
            val name = parts.getOrNull(0)?.ifBlank { null } ?: "1.0.0"
            val code = parts.getOrNull(1)?.toIntOrNull() ?: 1
            return Pair(name, code)
        }
    }
    return Pair("1.0.0", 1)
}

val (pubspecVersionName, pubspecVersionCode) = parsePubspecVersion()

// Resolves version with fallback priority:
// CLI project property > local.properties > pubspec.yaml
val resolvedVersionName = (project.findProperty("flutter.versionName") as? String)
    ?: localProperties.getProperty("flutter.versionName")
    ?: pubspecVersionName

val resolvedVersionCode = (project.findProperty("flutter.versionCode") as? String)?.toIntOrNull()
    ?: localProperties.getProperty("flutter.versionCode")?.toIntOrNull()
    ?: pubspecVersionCode

android {
    namespace = "com.zentex.charted"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zentex.charted"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = resolvedVersionCode
        versionName = resolvedVersionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
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
