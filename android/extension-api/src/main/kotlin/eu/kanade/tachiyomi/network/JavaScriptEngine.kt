package eu.kanade.tachiyomi.network
import android.content.Context
import android.webkit.WebView
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import org.json.JSONTokener
import org.json.JSONObject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class JavaScriptEngine(private val context: Context) {
    @Suppress("UNCHECKED_CAST", "SetJavaScriptEnabled")
    suspend fun <T> evaluate(script: String): T = withContext(Dispatchers.Main) {
        withTimeout(15000) {
            val view = WebView(context)
            view.settings.javaScriptEnabled = true
            view.settings.blockNetworkLoads = true
            view.settings.allowFileAccess = false
            view.settings.allowContentAccess = false
            try {
                suspendCancellableCoroutine { continuation ->
                    val wrapped = "(function(){try{return JSON.stringify({value:(0,eval)(" + JSONObject.quote(script) + ")});}catch(e){return JSON.stringify({error:String(e)});}})()"
                    view.evaluateJavascript(wrapped) { encoded ->
                        if (continuation.isActive) {
                            try {
                                val result = JSONObject(JSONTokener(encoded).nextValue() as String)
                                if (result.has("error")) throw IllegalStateException(result.getString("error"))
                                continuation.resume(result.opt("value") as T)
                            } catch (error: Exception) { continuation.resumeWithException(error) }
                        }
                    }
                }
            } finally { view.destroy() }
        }
    }
}
