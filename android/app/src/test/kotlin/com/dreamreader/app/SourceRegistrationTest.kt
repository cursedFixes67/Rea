package com.dreamreader.app

import org.junit.Assert.*
import org.junit.Test

class SourceRegistrationTest {
    @Test fun failedMetadataDoesNotPublishPartialSources() {
        val live = linkedMapOf("existing" to "another.package")
        val result = runCatching {
            prepareSources("new.package", listOf("good", "broken"), live, { it }) {
                check(it != "broken") { "source getter failed" }
                "description $it"
            }.forEach { live[it.id] = "new.package" }
        }
        assertTrue(result.isFailure)
        assertEquals(mapOf("existing" to "another.package"), live)
    }
    @Test fun duplicateOrConflictingSourcesRejectTheWholePackage() {
        val owners = mapOf("one" to "original.package")
        assertTrue(runCatching { prepareSources("new.package", listOf("new", "one"), owners, { it }, { it }) }.isFailure)
        assertTrue(runCatching { prepareSources("new.package", listOf("same", "same"), owners, { it }, { it }) }.isFailure)
        assertTrue(runCatching { prepareSources("new.package", emptyList<String>(), owners, { it }, { it }) }.isFailure)
    }
    @Test fun updateMayRetainItsOwnIdentifiersAndAddNewOnes() {
        val prepared = prepareSources("original.package", listOf("one", "two"), mapOf("one" to "original.package"), { it }, { it.uppercase() })
        assertEquals(listOf("one", "two"), prepared.map { it.id })
        assertEquals(listOf("ONE", "TWO"), prepared.map { it.description })
    }
}
