// Adapted from Mihon 134e5de3d672968b91ac426fbea0020290972cff; Apache-2.0.
package eu.kanade.tachiyomi.network

import android.content.Context
import app.cash.quickjs.QuickJs
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/** Preserves the source API's native JavaScript primitive-result contract. */
@Suppress("UNUSED_PARAMETER", "UNCHECKED_CAST")
class JavaScriptEngine(context: Context) {
    suspend fun <T> evaluate(script: String): T = withContext(Dispatchers.Default) {
        // Each request owns its interpreter; QuickJs instances are not thread safe.
        QuickJs.create().use { it.evaluate(script) as T }
    }
}
