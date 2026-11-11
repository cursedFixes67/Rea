package com.dreamreader.app

/** Prepare every source before mutating a live catalogue or replacing an APK. */
internal data class RegisteredSource<T, D>(val id: String, val source: T, val description: D)

internal fun <T, D> prepareSources(
    packageName: String,
    candidates: List<T>,
    owners: Map<String, String>,
    identifier: (T) -> String,
    describe: (T) -> D,
): List<RegisteredSource<T, D>> {
    require(candidates.isNotEmpty()) { "Extension contains no sources" }
    val seen = HashSet<String>()
    return candidates.map { source ->
        val id = identifier(source)
        check(seen.add(id)) { "Extension repeats source identifier $id" }
        val owner = owners[id]
        check(owner == null || owner == packageName) { "Source identifier $id belongs to another installed extension" }
        RegisteredSource(id, source, describe(source))
    }
}
