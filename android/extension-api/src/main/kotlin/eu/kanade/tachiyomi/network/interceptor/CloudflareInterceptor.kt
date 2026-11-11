package eu.kanade.tachiyomi.network.interceptor

import okhttp3.Interceptor
import okhttp3.Response
import java.io.IOException

/** Detects interactive challenges. Clearance is obtained by the user in the source's shared-cookie WebView. */
class CloudflareInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val response = chain.proceed(chain.request())
        if (response.header("cf-mitigated") == "challenge") {
            response.close()
            throw IOException("This source requires browser verification. Open its website from the source menu, complete verification, then retry.")
        }
        return response
    }
}
