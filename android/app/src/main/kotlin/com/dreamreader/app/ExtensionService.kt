package com.dreamreader.app
import android.app.Service
import android.content.Intent
import android.os.*
import kotlinx.coroutines.*
import org.json.JSONObject

class ExtensionService : Service() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val messenger = Messenger(Handler(Looper.getMainLooper()) { message ->
        val reply = message.replyTo
        val requestId = message.arg1
        val method = message.data.getString("method") ?: return@Handler true
        val arguments = message.data.getString("arguments") ?: "{}"
        scope.launch {
            val bundle = Bundle()
            try {
                val result = withTimeout(if (method == "install") 180000L else 90000L) {
                    ExtensionRuntime.get(applicationContext).execute(method, JSONObject(arguments))
                }
                SourceReply.write(applicationContext, bundle, result.toString())
            } catch (error: Throwable) {
                bundle.putString("error", SourceErrors.describe(error))
            }
            try { reply.send(Message.obtain().apply { arg1 = requestId; data = bundle }) } catch (_: RemoteException) { SourceReply.discard(applicationContext, bundle) }
        }
        true
    })
    override fun onBind(intent: Intent): IBinder = messenger.binder
    override fun onDestroy() { scope.cancel(); super.onDestroy() }
}

object SourceErrors {
    fun describe(error: Throwable): String {
        var cause = error
        repeat(8) { cause = cause.cause?.takeUnless { it === cause } ?: return "${cause.javaClass.simpleName}: ${cause.message ?: "Source operation failed"}".take(2000) }
        return "${cause.javaClass.simpleName}: ${cause.message ?: "Source operation failed"}".take(2000)
    }
}
