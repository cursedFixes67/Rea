package com.dreamreader.app

import java.io.File
import java.io.ByteArrayOutputStream
import java.util.UUID

/** Large replies cross Binder by private-cache reference, avoiding its transaction limit. */
internal class PayloadFiles(private val directory: File) {
    companion object {
        const val INLINE_BYTES = 128 * 1024
        const val MAX_BYTES = 32 * 1024 * 1024
        private const val RETAIN_MILLIS = 15 * 60 * 1000L
        private val NAME = Regex("reply-[a-f0-9-]+\\.json")
    }

    fun store(text: String): File? {
        val bytes = text.toByteArray(Charsets.UTF_8)
        require(bytes.size <= MAX_BYTES) { "Source response exceeds the 32 MB limit" }
        if (bytes.size <= INLINE_BYTES) return null
        check(directory.isDirectory || directory.mkdirs()) { "Cannot create source response cache" }
        val cutoff = System.currentTimeMillis() - RETAIN_MILLIS
        directory.listFiles().orEmpty().filter { NAME.matches(it.name) && it.lastModified() < cutoff }.forEach { it.delete() }
        val target = File(directory, "reply-${UUID.randomUUID()}.json")
        try {
            target.writeBytes(bytes)
            return target
        } catch (error: Exception) {
            target.delete()
            throw error
        }
    }

    private fun checked(path: String): File {
        val file = File(path)
        require(NAME.matches(file.name) && file.canonicalFile.parentFile == directory.canonicalFile) {
            "Invalid source response cache path"
        }
        return file
    }

    fun consume(path: String): String {
        val file = checked(path)
        try {
            require(file.isFile && file.length() in 1..MAX_BYTES.toLong()) { "Invalid source response size" }
            return file.inputStream().use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(65536)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    require(output.size().toLong() + count <= MAX_BYTES) { "Source response grew beyond the limit" }
                    output.write(buffer, 0, count)
                }
                output.toString(Charsets.UTF_8.name())
            }
        } finally {
            file.delete()
        }
    }

    fun discard(path: String) { checked(path).delete() }
}
