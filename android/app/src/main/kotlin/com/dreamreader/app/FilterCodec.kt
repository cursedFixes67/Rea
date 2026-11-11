package com.dreamreader.app

import eu.kanade.tachiyomi.source.model.Filter
import org.json.JSONArray
import org.json.JSONObject

/** Serialize source-owned filters without transferring extension objects across IPC. */
object FilterCodec {
    fun describe(filters: List<*>, prefix: String = ""): JSONArray = JSONArray(filters.mapIndexedNotNull { index, value ->
        val filter = value as? Filter<*> ?: return@mapIndexedNotNull null
        val path = "$prefix$index"
        val json = JSONObject().put("id", path).put("name", filter.name)
        when (filter) {
            is Filter.Header -> json.put("type", "header")
            is Filter.Separator -> json.put("type", "separator")
            is Filter.Select<*> -> json.put("type", "select").put("values", JSONArray(filter.values.map { it.toString() })).put("value", filter.state)
            is Filter.Text -> json.put("type", "text").put("value", filter.state)
            is Filter.CheckBox -> json.put("type", "check").put("value", filter.state)
            is Filter.TriState -> json.put("type", "tri").put("value", filter.state)
            is Filter.Sort -> json.put("type", "sort").put("values", JSONArray(filter.values.toList()))
                .put("value", filter.state?.let { JSONObject().put("index", it.index).put("ascending", it.ascending) } ?: JSONObject.NULL)
            is Filter.Group<*> -> json.put("type", "group").put("children", describe(filter.state, "$path."))
        }
        json
    })
    fun apply(filters: List<*>, values: JSONObject, prefix: String = "") {
        filters.forEachIndexed { index, item ->
            val path = "$prefix$index"
            val filter = item as? Filter<*> ?: return@forEachIndexed
            if (filter is Filter.Group<*>) { apply(filter.state, values, "$path."); return@forEachIndexed }
            if (!values.has(path)) return@forEachIndexed
            when (filter) {
                is Filter.Select<*> -> { val value = values.getInt(path); require(value in filter.values.indices); filter.state = value }
                is Filter.Text -> { val value = values.getString(path); require(value.length <= 4096); filter.state = value }
                is Filter.CheckBox -> filter.state = values.getBoolean(path)
                is Filter.TriState -> { val value = values.getInt(path); require(value in 0..2); filter.state = value }
                is Filter.Sort -> { val value = values.optJSONObject(path)
                    filter.state = value?.let { require(it.getInt("index") in filter.values.indices); Filter.Sort.Selection(it.getInt("index"), it.getBoolean("ascending")) }
                }
                else -> Unit
            }
        }
    }
}
