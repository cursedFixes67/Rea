package com.dreamreader.app

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapRegionDecoder
import android.graphics.Rect
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import java.io.ByteArrayOutputStream
import java.io.File

/** Geometry stays independent of Android so bounds and memory limits can be tested. */
internal data class ImageRegionGeometry(val width: Int, val height: Int) {
    init { require(width > 0 && height > 0) { "Invalid image dimensions" } }
    val sample: Int = run {
        var value = 1
        while ((width.toLong() + value - 1) / value > 1800) value *= 2
        value
    }
    val regionHeight: Int = minOf(2048L * sample, Int.MAX_VALUE.toLong()).toInt()
    val count: Int = ((height.toLong() + regionHeight - 1) / regionHeight).toInt()
    fun bounds(index: Int): Pair<Int, Int> {
        require(index in 0 until count) { "Invalid image region" }
        val top = index.toLong() * regionHeight
        return top.toInt() to minOf(top + regionHeight, height.toLong()).toInt()
    }
}

internal class ImageRegions(private val context: Context) {
    companion object { private val decodes = Semaphore(2) }
    private fun file(path: String): File {
        val target = File(path).canonicalFile
        val roots = listOf(File(context.cacheDir, "reader_images"), File(context.filesDir, "downloads"))
        require(roots.any { target.path.startsWith(it.canonicalPath + File.separator) }) { "Image is outside reader storage" }
        require(target.isFile) { "The image is no longer available. Download it again." }
        return target
    }
    @Suppress("DEPRECATION")
    private fun decoder(file: File): BitmapRegionDecoder =
        BitmapRegionDecoder.newInstance(file.path, false) ?: error("This image cannot be read in regions")

    suspend fun info(path: String): Map<String, Any> = decodes.withPermit {
        val target = file(path)
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(target.path, bounds)
        val geometry = ImageRegionGeometry(bounds.outWidth, bounds.outHeight)
        // Probe the actual decoder: support for newer formats depends on Android version.
        val tiled = geometry.height > 8192 && runCatching { decoder(target).recycle() }.isSuccess
        mapOf("width" to geometry.width, "height" to geometry.height,
            "regionHeight" to geometry.regionHeight, "count" to geometry.count, "tiled" to tiled)
    }
    suspend fun decode(path: String, index: Int): ByteArray = decodes.withPermit {
        val reader = decoder(file(path))
        try {
            val geometry = ImageRegionGeometry(reader.width, reader.height)
            val (top, bottom) = geometry.bounds(index)
            val bitmap = reader.decodeRegion(Rect(0, top, geometry.width, bottom), BitmapFactory.Options().apply {
                inSampleSize = geometry.sample
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }) ?: error("Could not decode this part of the image")
            try {
                ByteArrayOutputStream().use { output ->
                    check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)) { "Could not transfer image region" }
                    output.toByteArray()
                }
            } finally { bitmap.recycle() }
        } finally { reader.recycle() }
    }
}
