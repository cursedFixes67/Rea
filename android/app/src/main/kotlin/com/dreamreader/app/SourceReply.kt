package com.dreamreader.app

import android.content.Context
import android.os.Bundle
import java.io.File

internal object SourceReply {
    private fun files(context: Context) = PayloadFiles(File(context.cacheDir, "source_replies"))
    fun write(context: Context, bundle: Bundle, text: String) {
        val file = files(context).store(text)
        if (file == null) bundle.putString("result", text)
        else bundle.putString("resultFile", file.path)
    }
    fun read(context: Context, bundle: Bundle): String = bundle.getString("resultFile")?.let {
        files(context).consume(it)
    } ?: bundle.getString("result") ?: "null"
    fun discard(context: Context, bundle: Bundle) {
        bundle.getString("resultFile")?.let { runCatching { files(context).discard(it) } }
    }
}
