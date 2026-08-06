import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

// ✅ Task 1.4: Read versionName/versionCode from pubspec.yaml (single source of
// truth for app versioning) instead of local.properties, which is a
// machine-local, gitignored file that shouldn't drive release version numbers.
// pubspec.yaml format: "version: 1.0.0+1" -> name="1.0.0", code=1
val pubspecFile = rootProject.file("../pubspec.yaml")
val pubspecVersionLine = pubspecFile.readLines()
    .firstOrNull { it.trim().startsWith("version:") }
    ?.substringAfter("version:")
    ?.trim()
    ?: "1.0.0+1"

val flutterVersionName = pubspecVersionLine.substringBefore("+").trim()
val flutterVersionCode = pubspecVersionLine
    .substringAfter("+", "1")
    .trim()
    .toIntOrNull() ?: 1

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// ✅ Task 1.5: Gradle safeguard — fail the build immediately (during
// configuration) if a release-type task was requested but key.properties
// is missing, instead of silently falling back to debug signing and
// producing an unsigned/mis-signed release artifact.
val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}
if (isReleaseTaskRequested && !keystorePropertiesFile.exists()) {
    throw GradleException(
        "❌ Release build requested but 'android/key.properties' is missing.\n" +
        "   Copy 'android/key.properties.example' to 'android/key.properties' and fill in your\n" +
        "   real signing credentials before building a release artifact."
    )
}

android {
    namespace = "com.fadoul.muslimplatform"
    
    // ✅ 1. SDK Version
    compileSdk = 36
    
    // ✅ 2. NDK Version
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        
        // 👇 FIX 1: تصحيح الكتابة لـ Kotlin DSL
        isCoreLibraryDesugaringEnabled = true
    }

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        applicationId = "com.fadoul.muslimplatform"
        minSdk = flutter.minSdkVersion
        
        // ✅ 3. Target SDK
        targetSdk = 36
        
        versionCode = flutterVersionCode
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// 👇 FIX 2: إضافة المكتبة الضرورية خارج android block
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.work:work-runtime-ktx:2.8.1")
    implementation("com.batoulapps.adhan:adhan:1.2.1") // ✅ Native Adhan Calculation (Stable)
}
