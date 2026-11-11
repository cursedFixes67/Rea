plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.serialization")
}
android {
    namespace = "com.dreamreader.extensionapi"
    compileSdk = 37
    defaultConfig { minSdk = 26 }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
}
kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }
dependencies {
    api("com.squareup.okhttp3:okhttp:5.5.1")
    api("com.squareup.okhttp3:okhttp-brotli:5.5.1")
    api("com.squareup.okhttp3:okhttp-zstd:5.5.1")
    api("org.jsoup:jsoup:1.24.1")
    api("io.reactivex:rxjava:1.3.8")
    api("uy.kohesive.injekt:injekt-core:1.16.1")
    api("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.11.0")
    api("org.jetbrains.kotlinx:kotlinx-serialization-json:1.12.0")
    api("org.jetbrains.kotlinx:kotlinx-serialization-json-okio:1.12.0")
    api("org.jetbrains.kotlinx:kotlinx-serialization-protobuf:1.12.0")
    api("androidx.preference:preference-ktx:1.2.1")
    api("androidx.compose.runtime:runtime:1.11.0")
}
