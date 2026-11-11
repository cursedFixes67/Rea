package com.dreamreader.app

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.provider.DocumentsContract
import androidx.work.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.TimeUnit
import io.flutter.plugins.sharedpreferences.*

object BackupSchedule {
    fun preferences(context: Context) = context.getSharedPreferences("dream_backups", Context.MODE_PRIVATE)
    fun configure(context: Context, args: JSONObject): JSONObject {
        val preferences = preferences(context)
        val hours = args.optInt("hours", 24)
        require(hours in listOf(0, 24, 168)) { "Choose daily, weekly or off" }
        if (args.has("databasePath")) {
            val path = File(args.getString("databasePath")).canonicalFile
            require(path.path.startsWith(context.applicationInfo.dataDir + "/") && path.name == "dream_reader.sqlite")
            preferences.edit().putString("databasePath", path.path).apply()
        }
        if (hours > 0) check(!preferences.getString("tree", null).isNullOrBlank()) { "Choose a backup folder first" }
        val manager = WorkManager.getInstance(context)
        if (hours == 0) manager.cancelUniqueWork("dream-scheduled-backup")
        else manager.enqueueUniquePeriodicWork("dream-scheduled-backup", ExistingPeriodicWorkPolicy.UPDATE,
            PeriodicWorkRequestBuilder<BackupWorker>(hours.toLong(), TimeUnit.HOURS).setConstraints(Constraints.Builder().setRequiresBatteryNotLow(true).build()).build())
        preferences.edit().putInt("hours", hours).apply()
        return status(context)
    }
    fun status(context: Context): JSONObject {
        val p = preferences(context)
        return JSONObject().put("hours", p.getInt("hours", 0)).put("folder", p.getString("tree", "")).put("lastSuccess", p.getLong("lastSuccess", 0)).put("error", p.getString("lastError", ""))
    }
}
class BackupWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val preferences = BackupSchedule.preferences(applicationContext)
        try {
            val path = preferences.getString("databasePath", null) ?: error("Database not configured")
            check(File(path).exists()) { "Open Dream Reader to initialize your library" }
            val tree = Uri.parse(preferences.getString("tree", null) ?: error("Backup folder not configured"))
            val payload = JSONObject().put("version", 1).put("createdAt", java.time.Instant.now().toString())
            SQLiteDatabase.openDatabase(path, null, SQLiteDatabase.OPEN_READWRITE).use { db ->
                db.beginTransactionNonExclusive()
                try {
                    for ((table, key) in mapOf("library_entries" to "library", "chapter_entries" to "chapters", "repository_entries" to "repositories", "reading_sessions" to "sessions")) {
                        val rows = JSONArray()
                        db.rawQuery("SELECT * FROM $table", null).use { cursor ->
                            while (cursor.moveToNext()) {
                                val row = JSONObject()
                                cursor.columnNames.forEachIndexed { index, column ->
                                    val name = column.split('_').let { it.first() + it.drop(1).joinToString("") { part -> part.replaceFirstChar(Char::uppercase) } }
                                    val value: Any = when {
                                        cursor.isNull(index) -> JSONObject.NULL
                                        column in listOf("added_at", "last_read", "synced_at", "created_at") -> cursor.getLong(index) * 1000
                                        column in listOf("completed", "enabled") -> cursor.getInt(index) != 0
                                        cursor.getType(index) == android.database.Cursor.FIELD_TYPE_INTEGER -> cursor.getLong(index)
                                        else -> cursor.getString(index)
                                    }
                                    row.put(name, value)
                                }
                                rows.put(row)
                            }
                        }
                        payload.put(key, rows)
                    }
                    db.setTransactionSuccessful()
                } finally { db.endTransaction() }
            }
            val settings = JSONObject()
            applicationContext.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE).all.forEach { (key, raw) ->
                if (!key.startsWith("flutter.") || raw == null) return@forEach
                val value: Any = when {
                    raw is String && raw.startsWith(JSON_LIST_PREFIX) -> JSONArray(raw.substring(JSON_LIST_PREFIX.length))
                    raw is String && raw.startsWith(LIST_PREFIX) -> JSONArray(ListEncoder().decode(raw.substring(LIST_PREFIX.length)))
                    raw is String && raw.startsWith(DOUBLE_PREFIX) -> raw.substring(DOUBLE_PREFIX.length).toDouble()
                    raw is Set<*> -> JSONArray(raw.toList())
                    else -> raw
                }
                settings.put(key.removePrefix("flutter."), value)
            }
            payload.put("settings", settings)
            payload.put("downloads", DownloadController(applicationContext).list())
            val data = payload.toString()
            val checksum = MessageDigest.getInstance("SHA-256").digest(data.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }
            val envelope = JSONObject().put("format", "dream-reader-backup").put("version", 1).put("sha256", checksum).put("payload", data).toString().toByteArray(Charsets.UTF_8)
            check(envelope.size <= 64 * 1024 * 1024) { "Backup exceeds supported 64 MiB import size" }
            val root = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))
            val name = "DreamReader-auto-${System.currentTimeMillis()}.dreambackup"
            val uri = DocumentsContract.createDocument(applicationContext.contentResolver, root, "application/octet-stream", name) ?: error("Could not create backup")
            try {
                applicationContext.contentResolver.openOutputStream(uri, "w")!!.use { it.write(envelope) }
            } catch (error: Exception) { DocumentsContract.deleteDocument(applicationContext.contentResolver, uri); throw error }
            preferences.edit().putLong("lastSuccess", System.currentTimeMillis()).putString("lastError", "").apply()
            Result.success()
        } catch (error: Exception) {
            preferences.edit().putString("lastError", error.message ?: "Backup failed").apply()
            Result.failure(workDataOf("error" to (error.message ?: "Backup failed")))
        }
    }
}
