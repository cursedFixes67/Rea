// Adapted from https://github.com/mihonapp/mihon at 134e5de3d672968b91ac426fbea0020290972cff
// Copyright Mihon and Tachiyomi contributors, Apache-2.0.
package eu.kanade.tachiyomi.source.model

class MangasPage(val mangas: List<SManga>, val hasNextPage: Boolean) {

    @Deprecated("MangasPage is now a regular class")
    operator fun component1(): List<SManga> = mangas

    @Deprecated("MangasPage is now a regular class")
    operator fun component2(): Boolean = hasNextPage

    @Deprecated("MangasPage is now a regular class")
    fun copy(
        mangas: List<SManga> = this.mangas,
        hasNextPage: Boolean = this.hasNextPage,
    ): MangasPage = MangasPage(
        mangas = mangas,
        hasNextPage = hasNextPage,
    )
}
