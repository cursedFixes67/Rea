import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = file(System.getenv("DREAM_READER_SIGNING_PROPERTIES")
    ?: "${System.getenv("HOME")}/runtime/dream-reader-signing/signing.properties")
val releaseProperties = Properties()
if (signingPropertiesFile.isFile) signingPropertiesFile.inputStream().use { releaseProperties.load(it) }
if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) }) {
    check(signingPropertiesFile.isFile) { "Release signing properties are required; set DREAM_READER_SIGNING_PROPERTIES" }
}

android {
    namespace = "com.dreamreader.app"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.dreamreader.app"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (signingPropertiesFile.isFile) {
                storeFile = file(releaseProperties.getProperty("storeFile"))
                storePassword = releaseProperties.getProperty("storePassword")
                keyAlias = releaseProperties.getProperty("keyAlias")
                keyPassword = releaseProperties.getProperty("keyPassword")
                enableV1Signing = false
                enableV2Signing = true
            }
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
    implementation(project(":extension-api"))
    implementation("com.android.tools.build:apksig:9.5.1")
    implementation("androidx.fragment:fragment-ktx:1.8.9")
    implementation("androidx.work:work-runtime-ktx:2.12.0")
}
