package com.dreamreader.app

import android.graphics.BitmapFactory
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import com.android.apksig.ApkVerifier
import dalvik.system.PathClassLoader
import eu.kanade.tachiyomi.network.NetworkHelper
import eu.kanade.tachiyomi.network.JavaScriptEngine
import eu.kanade.tachiyomi.source.Source
import eu.kanade.tachiyomi.source.SourceFactory
import eu.kanade.tachiyomi.source.ConfigurableSource
import eu.kanade.tachiyomi.source.model.*
import eu.kanade.tachiyomi.source.online.HttpSource
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.Json
import kotlinx.serialization.protobuf.ProtoBuf
import okhttp3.Request
import okhttp3.HttpUrl.Companion.toHttpUrl
import org.json.JSONArray
import org.json.JSONObject
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.addSingleton
import java.io.File
import java.security.MessageDigest

/** Extensions run under the app UID in a dedicated process, not a security sandbox. */
class ExtensionRuntime private constructor(private val context: Context) {
    private val directory = File(context.filesDir, "extensions").apply { mkdirs() }
    private val registryFile = File(directory, "registry.json")
    private val network = NetworkHelper(context)
    private val sources = linkedMapOf<String, Source>()
    private val sourcePackages = mutableMapOf<String, String>()
    private val mutex = Mutex()
    private val imageLocks = Array(64) { Mutex() }
    private var loaded = false
    private var errors = JSONArray()
    init {
        Injekt.addSingleton<Context>(context.applicationContext)
        Injekt.addSingleton(network)
        Injekt.addSingleton(JavaScriptEngine(context))
        Injekt.addSingleton(Json { ignoreUnknownKeys = true; explicitNulls = false })
        Injekt.addSingleton(ProtoBuf { encodeDefaults = true })
    }
    companion object {
        @Volatile private var instance: ExtensionRuntime? = null
        fun get(context: Context): ExtensionRuntime = instance ?: synchronized(this) {
            instance ?: ExtensionRuntime(context.applicationContext).also { instance = it }
        }
    }
    private fun registry(): JSONObject = if (registryFile.exists()) JSONObject(registryFile.readText()) else JSONObject()
    private fun saveRegistry(value: JSONObject) {
        val stage = File(directory, "registry.part")
        stage.writeText(value.toString())
        check(stage.renameTo(registryFile)) { "Could not save extension registry" }
    }
    private fun digest(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
    private fun packageFile(pkg: String): File {
        require(Regex("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+").matches(pkg)) { "Invalid package name" }
        return File(directory, "$pkg.apk")
    }
    private fun verify(file: File, expected: JSONObject) {
        val verification = ApkVerifier.Builder(file).setMinCheckedPlatformVersion(Build.VERSION.SDK_INT).build().verify()
        check(verification.isVerified) { "APK signature verification failed: ${verification.errors}" }
        val signers = verification.signerCertificates.map { digest(it.encoded) }
        check(signers.size == 1 && signers.single().equals(expected.getString("signer"), true)) { "APK signer does not match the trusted repository" }
        val info = context.packageManager.getPackageArchiveInfo(file.path, PackageManager.GET_META_DATA or PackageManager.GET_CONFIGURATIONS)
            ?: error("Android cannot parse this extension")
        check(info.packageName == expected.getString("packageName")) { "Extension package identity mismatch" }
        @Suppress("DEPRECATION") val code = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
        check(code == expected.getLong("code")) { "Extension version does not match the catalogue" }
        check(info.reqFeatures.orEmpty().any { it.name == "tachiyomi.extension" }) { "Package is not a manga source extension" }
        check((info.applicationInfo?.minSdkVersion ?: 0) <= Build.VERSION.SDK_INT) { "This extension requires a newer Android version" }
        check(expected.getString("api") in listOf("1.4", "1.6")) { "Unsupported extension API ${expected.getString("api")}" }
    }
    private fun load(file: File, expected: JSONObject): List<Source> {
        verify(file, expected)
        check(file.setReadOnly()) { "Unable to protect extension code from writes" }
        val info = context.packageManager.getPackageArchiveInfo(file.path, PackageManager.GET_META_DATA) ?: error("Missing package metadata")
        val metadata = info.applicationInfo?.metaData ?: error("Extension has no source metadata")
        val classes = metadata.getString("tachiyomi.extension.class") ?: error("Extension has no source classes")
        val api = metadata.getFloat("tachiyomix.extensionLib").takeUnless { it == 0f }?.toString() ?: info.versionName?.substringBeforeLast('.')
        check(api == expected.getString("api")) { "Extension API metadata does not match catalogue" }
        val loader = PathClassLoader(file.path, context.classLoader)
        return classes.split(';').flatMap { name ->
            val resolved = name.trim().let { if (it.startsWith('.')) info.packageName + it else it }
            when (val source = Class.forName(resolved, true, loader).getDeclaredConstructor().newInstance()) {
                is Source -> listOf(source)
                is SourceFactory -> source.createSources()
                else -> error("Unsupported source entry point $resolved")
            }
        }
    }
    private fun ensureLoaded() {
        if (loaded) return
        sources.clear(); sourcePackages.clear(); errors = JSONArray()
        val entries = registry()
        entries.keys().forEach { pkg ->
            try {
                load(packageFile(pkg), entries.getJSONObject(pkg)).forEach { source ->
                    val id = source.id.toString()
                    check(!sources.containsKey(id)) { "Duplicate source identifier $id" }
                    sources[id] = source; sourcePackages[id] = pkg
                }
            } catch (error: Throwable) {
                errors.put(JSONObject().put("packageName", pkg).put("message", SourceErrors.describe(error)))
            }
        }
        loaded = true
    }
    suspend fun execute(method: String, args: JSONObject): Any {
        if (method == "image") return withContext(Dispatchers.IO) {
            val source = mutex.withLock { ensureLoaded(); sources[args.getString("sourceId")] ?: error("Source is not loaded") }
            val page = args.getJSONObject("page")
            val key = "${source.id}:${page.getString("url")}".hashCode() and 63
            imageLocks[key].withLock { image(source, page) }
        }
        return mutex.withLock { withContext(Dispatchers.IO) {
            when (method) {
                "install" -> install(args)
                "uninstall" -> {
                    val pkg = args.getString("packageName"); val entries = registry()
                    check(packageFile(pkg).delete() || !packageFile(pkg).exists()) { "Could not remove extension" }
                    entries.remove(pkg); saveRegistry(entries); loaded = false; JSONObject().put("removed", true)
                }
                "sources" -> { ensureLoaded(); JSONObject().put("sources", JSONArray(sources.values.map { sourceJson(it) })).put("errors", errors).put("installed", registry()) }
                else -> {
                    ensureLoaded()
                    val source = sources[args.getString("sourceId")] ?: error("Source is not loaded. Install its extension or review its compatibility error.")
                    when (method) {
                        "image" -> image(source, args.getJSONObject("page"))
                        "filters" -> FilterCodec.describe(source.getFilterList())
                        "browse" -> {
                            val page = args.optInt("page", 1).coerceAtLeast(1)
                            val result = when (args.optString("mode", "popular")) {
                                "latest" -> source.getLatestUpdates(page)
                                "search" -> source.getSearchManga(page, args.optString("query"), source.getFilterList().also { FilterCodec.apply(it, args.optJSONObject("filters") ?: JSONObject()) })
                                else -> source.getPopularManga(page)
                            }
                            JSONObject().put("items", JSONArray(result.mangas.map { mangaJson(source.id.toString(), it) })).put("hasNext", result.hasNextPage)
                        }
                        "details" -> {
                            val manga = manga(args.getJSONObject("manga"))
                            val result = source.getMangaUpdate(manga, emptyList(), true, true)
                            // Legacy sources may return details without the original identity fields.
                            if (runCatching { result.manga.url }.getOrNull().isNullOrBlank()) result.manga.url = manga.url
                            if (runCatching { result.manga.title }.getOrNull().isNullOrBlank()) result.manga.title = manga.title
                            JSONObject().put("manga", mangaJson(source.id.toString(), result.manga)).put("chapters", JSONArray(result.chapters.map { chapterJson(it) }))
                        }
                        "pages" -> {
                            val chapter = chapter(args.getJSONObject("chapter"))
                            val pages = source.getPageList(chapter)
                            JSONArray(pages.map { page ->
                                val url = page.imageUrl ?: (source as? HttpSource)?.getImageUrl(page) ?: error("Source returned no image URL")
                                val headers = JSONObject()
                                (source as? HttpSource)?.headers?.forEach { (key, value) -> headers.put(key, value) }
                                (source as? HttpSource)?.let { http ->
                                    val cookies = http.client.cookieJar.loadForRequest(url.toHttpUrl())
                                    if (cookies.isNotEmpty()) headers.put("Cookie", cookies.joinToString("; ") { "${it.name}=${it.value}" })
                                }
                                JSONObject().put("url", url).put("headers", headers).put("sourceId", source.id.toString()).put("pageUrl", page.url).put("index", page.index)
                            })
                        }
                        else -> error("Unknown extension operation $method")
                    }
                }
            }
        }
    }
    }
    private suspend fun image(source: Source, json: JSONObject): JSONObject {
        val cache = File(context.cacheDir, "reader_images").apply { mkdirs() }
        val url = json.getString("url")
        val target = File(cache, digest("${source.id}:$url".toByteArray()) + ".image")
        if (target.isFile && target.length() > 0) { target.setLastModified(System.currentTimeMillis()); return JSONObject().put("path", target.path) }
        val stage = File(cache, target.name + ".part")
        try {
            val page = Page(json.optInt("index"), json.optString("pageUrl"), url)
            val response = (source as? HttpSource)?.getImage(page)
                ?: network.client.newCall(Request.Builder().url(url).build()).execute()
            response.use {
                check(it.isSuccessful) { "Image returned HTTP ${it.code}" }
                it.body.byteStream().use { input -> stage.outputStream().use { output ->
                    val buffer = ByteArray(65536); var total = 0L
                    while (true) { val count = input.read(buffer); if (count < 0) break
                        total += count; check(total <= 128L * 1024 * 1024) { "Image exceeds safe decoding limit" }; output.write(buffer, 0, count)
                    }
                } }
            }
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(stage.path, bounds)
            check(bounds.outWidth > 0 && bounds.outHeight > 0) { "Source did not return a supported image" }
            check(stage.renameTo(target)) { "Could not cache source image" }
            var size = cache.listFiles().orEmpty().sumOf { it.length() }
            if (size > 1024L * 1024 * 1024) {
                for (file in cache.listFiles().orEmpty().sortedBy { it.lastModified() }) {
                    if (file == target || !file.name.endsWith(".image")) continue
                    val length = file.length(); if (file.delete()) size -= length
                    if (size <= 768L * 1024 * 1024) break
                }
            }
            return JSONObject().put("path", target.path)
        } finally { stage.delete() }
    }

    private fun install(args: JSONObject): JSONObject {
        check(args.optBoolean("consent")) { "Explicit extension installation consent is required" }
        val entry = args.getJSONObject("extension")
        val pkg = entry.getString("packageName"); val target = packageFile(pkg)
        val url = entry.getString("apkUrl")
        check(url.startsWith("https://")) { "Extension downloads require HTTPS" }
        val entries = registry()
        if (entries.has(pkg)) {
            val previous = entries.getJSONObject(pkg)
            check(previous.getString("signer") == entry.getString("signer")) { "Extension signing key changed" }
            check(previous.getLong("code") <= entry.getLong("code")) { "Extension downgrades are blocked" }
        }
        val stage = File.createTempFile("extension-", ".apk", directory)
        val backup = File(directory, "$pkg.previous")
        try {
            network.client.newBuilder().followSslRedirects(false).build().newCall(Request.Builder().url(url).build()).execute().use { response ->
                check(response.isSuccessful) { "Extension download failed: HTTP ${response.code}" }
                response.body.byteStream().use { input -> stage.outputStream().use { output ->
                    val buffer = ByteArray(32768); var total = 0L
                    while (true) { val count = input.read(buffer); if (count < 0) break
                        total += count; check(total <= 128L * 1024 * 1024) { "Extension exceeds 128 MiB limit" }; output.write(buffer, 0, count)
                    }
                } }
            }
            verify(stage, entry)
            stage.setReadOnly()
            // Instantiate before replacing an existing file so ordinary linkage failures retain the old build.
            val candidates = load(stage, entry)
            check(candidates.isNotEmpty()) { "Extension contains no sources" }
            if (target.exists()) check(target.renameTo(backup)) { "Could not retain previous version" }
            try {
                check(stage.renameTo(target)) { "Could not install extension" }
                entries.put(pkg, entry); saveRegistry(entries)
            }
            catch (error: Exception) { target.delete(); if (backup.exists()) backup.renameTo(target); throw error }
            backup.delete(); loaded = false
            return JSONObject().put("installed", true).put("sources", JSONArray(candidates.map { sourceJson(it) }))
        } finally { stage.delete() }
    }
    fun userAgent(): String = network.defaultUserAgentProvider()
    fun homeUrl(id: String): String { ensureLoaded(); return (sources[id] as? HttpSource)?.getHomeUrl() ?: error("Source has no website") }
    fun configurableSource(id: String): ConfigurableSource {
        ensureLoaded(); return sources[id] as? ConfigurableSource ?: error("This source has no preferences")
    }
    private fun sourceJson(source: Source) = JSONObject().put("id", source.id.toString()).put("name", source.name)
        .put("language", source.lang).put("homeUrl", (source as? HttpSource)?.getHomeUrl() ?: "")
        .put("preferences", source is ConfigurableSource).put("latest", source.supportsLatest).put("packageName", sourcePackages[source.id.toString()] ?: "")
    private fun manga(j: JSONObject) = SManga.create().apply {
        url = j.getString("url"); title = j.optString("title"); thumbnail_url = j.optString("cover"); author = j.optString("author"); artist = j.optString("artist")
        description = j.optString("description"); genre = j.optString("genre"); status = j.optInt("status"); initialized = j.optBoolean("initialized")
        update_strategy = runCatching { UpdateStrategy.valueOf(j.optString("updateStrategy", "ALWAYS_UPDATE")) }.getOrDefault(UpdateStrategy.ALWAYS_UPDATE)
        memo = Json.parseToJsonElement((j.optJSONObject("memo") ?: JSONObject()).toString()).jsonObject
    }
    private fun chapter(j: JSONObject) = SChapter.create().apply {
        url = j.getString("url"); name = j.optString("name"); chapter_number = j.optDouble("number", -1.0).toFloat()
        date_upload = j.optLong("date"); scanlator = j.optString("scanlator")
        memo = Json.parseToJsonElement((j.optJSONObject("memo") ?: JSONObject()).toString()).jsonObject
    }
    private fun mangaJson(sourceId: String, m: SManga) = JSONObject().put("sourceId", sourceId).put("url", m.url).put("title", m.title)
        .put("cover", m.thumbnail_url ?: "").put("description", m.description ?: "").put("author", m.author ?: "").put("genre", m.genre ?: "").put("status", m.status).put("artist", m.artist ?: "").put("memo", JSONObject(m.memo.toString())).put("initialized", m.initialized).put("updateStrategy", m.update_strategy.name)
    private fun chapterJson(c: SChapter) = JSONObject().put("url", c.url).put("name", c.name).put("number", c.chapter_number.toDouble()).put("date", c.date_upload).put("scanlator", c.scanlator ?: "").put("memo", JSONObject(c.memo.toString()))
}
