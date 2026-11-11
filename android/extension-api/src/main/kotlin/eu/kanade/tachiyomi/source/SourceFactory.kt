// Adapted from https://github.com/mihonapp/mihon at 134e5de3d672968b91ac426fbea0020290972cff
// Copyright Mihon and Tachiyomi contributors, Apache-2.0.
package eu.kanade.tachiyomi.source

/**
 * A factory for creating sources at runtime.
 */
interface SourceFactory {
    /**
     * Create a new copy of the sources
     * @return The created sources
     */
    fun createSources(): List<Source>
}
