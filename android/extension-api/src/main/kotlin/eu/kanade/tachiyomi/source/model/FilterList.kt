// Adapted from https://github.com/mihonapp/mihon at 134e5de3d672968b91ac426fbea0020290972cff
// Copyright Mihon and Tachiyomi contributors, Apache-2.0.
package eu.kanade.tachiyomi.source.model

import androidx.compose.runtime.Stable

@Stable
data class FilterList(val list: List<Filter<*>>) : List<Filter<*>> by list {

    constructor(vararg fs: Filter<*>) : this(if (fs.isNotEmpty()) fs.asList() else emptyList())

    override fun equals(other: Any?): Boolean {
        return false
    }

    override fun hashCode(): Int {
        return list.hashCode()
    }
}
