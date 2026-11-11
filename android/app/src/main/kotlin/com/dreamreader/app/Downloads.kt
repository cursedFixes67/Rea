package com.dreamreader.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.ServiceInfo
import android.graphics.BitmapFactory
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.TimeUnit

class DownloadController(private val context: Context) {
    private val manager = WorkManager.getInstance(context)
    private val root = File(context.filesDir, "downloads").apply { mkdirs() }
    fun id(key: String) = MessageDigest.getInstance("SHA-256").digest(key.toByteArray()).joinToString("") { "%02x".format(it) }
    fun enqueue(job: JSONObject): JSONObject {
        require(job.getJSONArray("pages").length() > 0) { "This chapter contains no downloadable pages" }
        val id = id(job.getString("key")); val directory = File(root, id).apply { mkdirs() }
        val file = File(directory, "job.json")
        if (!file.exists()) file.writeText(job.toString())
        val stored = JSONObject(file.readText())
        val request = OneTimeWorkRequestBuilder<ChapterDownloadWorker>()
            .setInputData(workDataOf("id" to id))
            .setConstraints(Constraints.Builder().setRequiredNetworkType(if (stored.optBoolean("wifiOnly", true)) NetworkType.UNMETERED else NetworkType.CONNECTED).build())
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 20, TimeUnit.SECONDS)
            .addTag("dream-downloads").addTag(id).build()
        manager.enqueueUniqueWork("chapter-$id", ExistingWorkPolicy.KEEP, request)
        return JSONObject().put("id", id)
    }
    fun control(args: JSONObject): JSONObject {
        val id = args.getString("id"); require(Regex("[a-f0-9]{64}").matches(id))
        val directory = File(root, id)
        when (args.getString("action")) {
            "pause" -> manager.cancelUniqueWork("chapter-$id").result.get()
            "resume" -> { manager.cancelUniqueWork("chapter-$id").result.get(); enqueue(JSONObject(File(directory, "job.json").readText())) }
            "delete" -> { manager.cancelUniqueWork("chapter-$id").result.get(); directory.deleteRecursively() }
            else -> error("Unknown download action")
        }
        return JSONObject().put("ok", true)
    }
    fun list(): JSONArray = JSONArray(root.listFiles().orEmpty().filter { File(it, "job.json").exists() }.map { dir ->
        val job = JSONObject(File(dir, "job.json").readText())
        val info = manager.getWorkInfosForUniqueWork("chapter-${dir.name}").get().lastOrNull()
        val total = job.getJSONArray("pages").length()
        val completed = (0 until total).count { File(dir, "$it.image").exists() }
        JSONObject().put("id", dir.name).put("key", job.optString("key")).put("mangaKey", job.optString("mangaKey")).put("chapterUrl", job.optString("chapterUrl")).put("bytes", dir.listFiles().orEmpty().filter { it.name.endsWith(".image") }.sumOf { it.length() }).put("title", job.optString("title")).put("chapter", job.optString("chapterName"))
            .put("completed", completed).put("total", total).put("status", if (completed == total && total > 0) "SUCCEEDED" else info?.state?.name ?: "PAUSED")
            .put("error", info?.outputData?.getString("error") ?: "")
    })
    fun pages(key: String): JSONArray {
        val dir = File(root, id(key)); val metadata = File(dir, "job.json")
        if (!metadata.exists()) return JSONArray()
        val count = JSONObject(metadata.readText()).getJSONArray("pages").length()
        if (!(0 until count).all { File(dir, "$it.image").isFile }) return JSONArray()
        return JSONArray((0 until count).map { JSONObject().put("url", File(dir, "$it.image").path).put("headers", JSONObject()) })
    }
}
class ChapterDownloadWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    companion object {
        private val concurrent = Semaphore(3)
        private val client = OkHttpClient.Builder().connectTimeout(20, TimeUnit.SECONDS).readTimeout(45, TimeUnit.SECONDS).build()
    }
    override suspend fun doWork(): Result = concurrent.withPermit { withContext(Dispatchers.IO) {
        val id = inputData.getString("id") ?: return@withContext Result.failure()
        if (!Regex("[a-f0-9]{64}").matches(id)) return@withContext Result.failure()
        val directory = File(applicationContext.filesDir, "downloads/$id")
        val metadata = File(directory, "job.json")
        if (!metadata.exists()) return@withContext Result.failure()
        val job = JSONObject(metadata.readText()); val pages = job.getJSONArray("pages")
        try {
            setForeground(notification(job.optString("title"), 0, pages.length()))
            for (index in 0 until pages.length()) {
                currentCoroutineContext().ensureActive()
                val file = File(directory, "$index.image")
                if (file.isFile && file.length() > 0) continue
                val entry = pages.getJSONObject(index); val url = entry.getString("url")
                require(url.startsWith("https://") || url.startsWith("http://")) { "Invalid page URL" }
                val request = Request.Builder().url(url)
                val headers = entry.optJSONObject("headers") ?: JSONObject()
                headers.keys().forEach { request.header(it, headers.getString(it)) }
                val partial = File(directory, "$index.part")
                try {
                    if (entry.optString("sourceId").isNotEmpty()) {
                        val image = SourceBridge.call(applicationContext, "image", JSONObject().put("sourceId", entry.getString("sourceId")).put("page", entry))
                        currentCoroutineContext().ensureActive()
                        File(image.getString("path")).copyTo(partial, overwrite = true)
                    } else client.newCall(request.build()).execute().use { response ->
                        check(response.isSuccessful) { "Page ${index + 1}: HTTP ${response.code}" }
                        check(response.body.contentType()?.type != "text") { "Page ${index + 1} returned a website instead of an image" }
                        response.body.byteStream().use { input -> partial.outputStream().use { output ->
                            val buffer = ByteArray(65536); var bytes = 0L
                            while (true) { currentCoroutineContext().ensureActive(); val count = input.read(buffer); if (count < 0) break
                                bytes += count; check(bytes <= 128L * 1024 * 1024) { "Page image exceeds 128 MiB" }; output.write(buffer, 0, count)
                            }
                        } }
                    }
                    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeFile(partial.path, bounds)
                    check(bounds.outWidth > 0 && bounds.outHeight > 0) { "Page ${index + 1} is not a supported image" }
                    check(partial.renameTo(file)) { "Could not save page ${index + 1}" }
                } finally { partial.delete() }
                setProgress(workDataOf("completed" to index + 1, "total" to pages.length()))
                setForeground(notification(job.optString("title"), index + 1, pages.length()))
            }
            Result.success()
        } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
        catch (error: Exception) { if (runAttemptCount < 3) Result.retry() else Result.failure(workDataOf("error" to (error.message ?: "Download failed"))) }
    } }
    private fun notification(title: String, completed: Int, total: Int): ForegroundInfo {
        val manager = applicationContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(NotificationChannel("downloads", "Chapter downloads", NotificationManager.IMPORTANCE_LOW))
        val notification = NotificationCompat.Builder(applicationContext, "downloads").setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title).setContentText("$completed / $total pages").setProgress(total, completed, false).setOngoing(true).build()
        return if (Build.VERSION.SDK_INT >= 29) ForegroundInfo(id.hashCode(), notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC) else ForegroundInfo(id.hashCode(), notification)
    }
}
