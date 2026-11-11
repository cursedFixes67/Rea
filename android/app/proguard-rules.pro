# Extension DEX links to host API names and signatures at runtime.
-keep class eu.kanade.tachiyomi.** { *; }
-keep class uy.kohesive.injekt.** { *; }
# Inlined Injekt calls create type tokens in the caller's package. Keeping only
# uy.kohesive.injekt does not retain their generic superclass under R8 full mode.
# FullTypeReference's constructor reads that signature through reflection.
-keep,allowshrinking class * extends uy.kohesive.injekt.api.FullTypeReference
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
# Current KeiSource filter caches call these Kotlin top-level APIs directly.
-keep class com.squareup.zstd.** { *; }
-keep class app.cash.quickjs.** { *; }
-keep class org.jsoup.** { *; }
-keep class kotlinx.serialization.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class kotlin.** { *; }
-keep class androidx.preference.** { *; }
-keep class rx.** { *; }
-keepattributes Signature,InnerClasses,EnclosingMethod,*Annotation*
