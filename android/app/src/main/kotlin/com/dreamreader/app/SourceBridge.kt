package com.dreamreader.app

import android.content.*
import android.os.*
import kotlinx.coroutines.*
import org.json.JSONObject

/** A bound IPC request used by background workers; executable source code stays in :extensions. */
object SourceBridge {
    suspend fun call(context: Context, method: String, args: JSONObject): JSONObject = withContext(Dispatchers.Main) {
        val response = CompletableDeferred<JSONObject>()
        val receiver = Messenger(Handler(Looper.getMainLooper()) { message ->
            val error = message.data.getString("error")
            if (error != null) response.completeExceptionally(IllegalStateException(error))
            else {
                val data = message.data
                launch(Dispatchers.IO) {
                    runCatching { JSONObject(SourceReply.read(context, data)) }
                        .fold(response::complete, response::completeExceptionally)
                }
            }
            true
        })
        val connection = object : ServiceConnection {
            override fun onServiceConnected(name: ComponentName, binder: IBinder) {
                try { Messenger(binder).send(Message.obtain().apply { replyTo = receiver
                    data = Bundle().apply { putString("method", method); putString("arguments", args.toString()) }
                }) } catch (error: RemoteException) { response.completeExceptionally(error) }
            }
            override fun onServiceDisconnected(name: ComponentName) { response.completeExceptionally(IllegalStateException("Source process stopped; retry download")) }
            override fun onBindingDied(name: ComponentName) { response.completeExceptionally(IllegalStateException("Source process binding died")) }
            override fun onNullBinding(name: ComponentName) { response.completeExceptionally(IllegalStateException("Source process unavailable")) }
        }
        val bound = context.bindService(Intent(context, ExtensionService::class.java), connection, Context.BIND_AUTO_CREATE)
        check(bound) { "Could not connect to extension engine" }
        try { withTimeout(100000) { response.await() } } finally { context.unbindService(connection) }
    }
}
