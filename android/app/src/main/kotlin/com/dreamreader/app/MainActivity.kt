package com.dreamreader.app
import android.content.*
import android.os.*
import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.json.JSONArray
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.*

class MainActivity : FlutterActivity() {
    private var service: Messenger? = null
    private var bound = false
    private val sequence = AtomicInteger()
    private val pending = mutableMapOf<Int, Pair<MethodChannel.Result, Runnable>>()
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var channel: MethodChannel
    private var directoryResult: MethodChannel.Result? = null
    private var captureVolume = false
    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val receiver = Messenger(Handler(Looper.getMainLooper()) { message ->
        val reply = message.data
        val request = pending.remove(message.arg1)
        if (request == null) {
            activityScope.launch(Dispatchers.IO) { SourceReply.discard(applicationContext, reply) }
        } else {
            val (result, timeout) = request
            handler.removeCallbacks(timeout)
            val error = reply.getString("error")
            if (error != null) result.error("SOURCE_ERROR", error, null)
            else activityScope.launch {
                try {
                    val value = withContext(Dispatchers.IO) {
                        decode(org.json.JSONTokener(SourceReply.read(applicationContext, reply)).nextValue())
                    }
                    result.success(value)
                } catch (error: Exception) { result.error("RESPONSE_ERROR", error.message, null) }
            }
        }
        true
    })
    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, binder: IBinder) { service = Messenger(binder) }
        override fun onServiceDisconnected(name: ComponentName) {
            service = null
            pending.values.toList().forEach { (result, timeout) -> handler.removeCallbacks(timeout); result.error("ENGINE_RESTART", "The extension process stopped. Retry the source operation.", null) }
            pending.clear()
        }
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.dreamreader.app/engine")
        bound = bindService(Intent(this, ExtensionService::class.java), connection, Context.BIND_AUTO_CREATE)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "backupChooseDirectory" -> {
                    if (directoryResult != null) { result.error("PICKER_OPEN", "A folder picker is already open", null) }
                    else {
                        directoryResult = result
                        startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or Intent.FLAG_GRANT_PREFIX_URI_PERMISSION), 6102)
                    }
                }
                "backupConfigure", "backupStatus", "backupNow" -> activityScope.launch {
                    try {
                        val value = withContext(Dispatchers.IO) {
                            when (call.method) {
                                "backupConfigure" -> BackupSchedule.configure(applicationContext, JSONObject(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()))
                                "backupNow" -> { androidx.work.WorkManager.getInstance(applicationContext).enqueueUniqueWork("dream-manual-backup", androidx.work.ExistingWorkPolicy.KEEP, androidx.work.OneTimeWorkRequestBuilder<BackupWorker>().build()); BackupSchedule.status(applicationContext) }
                                else -> BackupSchedule.status(applicationContext)
                            }
                        }; result.success(decode(value))
                    } catch (error: Exception) { result.error("BACKUP_ERROR", error.message, null) }
                }
                "downloadEnqueue", "downloadControl", "downloadList", "downloadPages" -> activityScope.launch {
                    try {
                        val value = withContext(Dispatchers.IO) {
                            val controller = DownloadController(applicationContext)
                            val args = JSONObject(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                            when (call.method) {
                                "downloadEnqueue" -> controller.enqueue(args)
                                "downloadControl" -> controller.control(args)
                                "downloadPages" -> controller.pages(args.getString("key"))
                                else -> controller.list()
                            }
                        }
                        result.success(decode(value))
                    } catch (error: Exception) { result.error("DOWNLOAD_ERROR", error.message, null) }
                }

                "readerSettings" -> {
                    captureVolume = call.argument<Boolean>("volumeKeys") ?: false
                    val brightness = call.argument<Double>("brightness") ?: -1.0
                    window.attributes = window.attributes.apply { screenBrightness = brightness.toFloat() }
                    if (call.argument<Boolean>("keepAwake") == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    result.success(null)
                }
                "openWebsite" -> { startActivity(Intent(this, SourceWebActivity::class.java).putExtra("sourceId", call.argument<String>("sourceId"))); result.success(null) }
                "preferences" -> {
                    startActivity(Intent(this, SourcePreferencesActivity::class.java).putExtra("sourceId", call.argument<String>("sourceId")))
                    result.success(null)
                }
                else -> dispatch(call.method, call.arguments as? Map<*, *> ?: emptyMap<Any, Any>(), result)
            }
        }
    }
    private fun dispatch(method: String, args: Map<*, *>, result: MethodChannel.Result, attempts: Int = 0) {
        val target = service
        if (target == null) {
            if (attempts >= 20) { result.error("ENGINE_UNAVAILABLE", "Extension engine is starting or unavailable. Please retry.", null); return }
            handler.postDelayed({ dispatch(method, args, result, attempts + 1) }, 150); return
        }
        val id = sequence.incrementAndGet()
        val timeout = Runnable { pending.remove(id)?.first?.error("SOURCE_TIMEOUT", "The source took too long to respond.", null) }
        pending[id] = result to timeout
        handler.postDelayed(timeout, if (method == "install") 190000 else 100000)
        try { target.send(Message.obtain().apply { arg1 = id; replyTo = receiver
            data = Bundle().apply { putString("method", method); putString("arguments", JSONObject(args).toString()) }
        }) } catch (error: RemoteException) { pending.remove(id); handler.removeCallbacks(timeout); result.error("ENGINE_UNAVAILABLE", error.message, null) }
    }
    @Deprecated("Legacy Android result API used for persisted SAF grants")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != 6102) { super.onActivityResult(requestCode, resultCode, data); return }
        val result = directoryResult; directoryResult = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) { result?.success(null); return }
        try {
            contentResolver.takePersistableUriPermission(uri, data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION))
            BackupSchedule.preferences(this).edit().putString("tree", uri.toString()).apply()
            result?.success(uri.toString())
        } catch (error: Exception) { result?.error("FOLDER_ERROR", error.message, null) }
    }
    override fun onKeyDown(keyCode: Int, event: KeyEvent): Boolean {
        if (captureVolume && keyCode in listOf(KeyEvent.KEYCODE_VOLUME_DOWN, KeyEvent.KEYCODE_VOLUME_UP)) {
            channel.invokeMethod("volume", if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) 1 else -1); return true
        }
        return super.onKeyDown(keyCode, event)
    }
    override fun onDestroy() {
        pending.values.forEach { (_, timeout) -> handler.removeCallbacks(timeout) }; pending.clear()
        activityScope.cancel()
        if (bound) unbindService(connection)
        super.onDestroy()
    }
    private fun decode(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> value.keys().asSequence().associateWith { decode(value.get(it)) }
        is JSONArray -> (0 until value.length()).map { decode(value.get(it)) }
        else -> value
    }
}
