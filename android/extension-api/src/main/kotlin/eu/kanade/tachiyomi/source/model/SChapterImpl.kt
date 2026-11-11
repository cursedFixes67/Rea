// Adapted from https://github.com/mihonapp/mihon at 134e5de3d672968b91ac426fbea0020290972cff
// Copyright Mihon and Tachiyomi contributors, Apache-2.0.
@file:Suppress("PropertyName")

package eu.kanade.tachiyomi.source.model

import kotlinx.serialization.json.JsonObject


class SChapterImpl : SChapter {

    override lateinit var url: String

    override lateinit var name: String

    override var chapter_number: Float = -1f

    override var scanlator: String? = null

    override var date_upload: Long = 0

    override var memo: JsonObject = JsonObject(emptyMap())
}
