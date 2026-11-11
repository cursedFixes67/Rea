package eu.kanade.tachiyomi.network

import android.content.Context
import android.webkit.CookieManager
import eu.kanade.tachiyomi.network.interceptor.*
import okhttp3.Cache
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import java.io.File
import java.util.concurrent.TimeUnit

class NetworkHelper(context: Context) {
    val cookieJar = AndroidCookieJar()
    val defaultUserAgentProvider: () -> String = { // Matches NetworkPreferences in the pinned Mihon reference. WebView uses this too.
        "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/149.0.0.0 Mobile Safari/537.36" }
    fun defaultUserAgentProvider(): String = defaultUserAgentProvider.invoke()
    val client: OkHttpClient = OkHttpClient.Builder()
        .cookieJar(cookieJar)
        .addInterceptor(UncaughtExceptionInterceptor())
        .addInterceptor(UserAgentInterceptor(::defaultUserAgentProvider))
        .addInterceptor(CloudflareInterceptor())
        .cache(Cache(File(context.cacheDir, "source_http"), 32L * 1024 * 1024))
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(40, TimeUnit.SECONDS)
        .callTimeout(60, TimeUnit.SECONDS)
        .retryOnConnectionFailure(true)
        .build()
    val cloudflareClient: OkHttpClient get() = client
}
