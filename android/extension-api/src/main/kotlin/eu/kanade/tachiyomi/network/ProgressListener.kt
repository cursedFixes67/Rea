// Adapted from https://github.com/mihonapp/mihon at 134e5de3d672968b91ac426fbea0020290972cff
// Copyright Mihon and Tachiyomi contributors, Apache-2.0.
package eu.kanade.tachiyomi.network

interface ProgressListener {
    fun update(bytesRead: Long, contentLength: Long, done: Boolean)
}
