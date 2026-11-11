package com.dreamreader.app

import org.junit.Assert.*
import org.junit.Test
import java.nio.file.Files

class PayloadFilesTest {
    @Test fun smallRepliesRemainInline() = withDirectory { directory ->
        assertNull(PayloadFiles(directory).store("{\"chapters\":[]}"))
        assertEquals(0, directory.listFiles().orEmpty().size)
    }
    @Test fun largeUnicodeChapterReplyRoundTripsAndIsRemoved() = withDirectory { directory ->
        val payloads = PayloadFiles(directory)
        val text = "{\"chapters\":[" + List(10000) { "{\"title\":\"第${it}話 · capítulo\",\"url\":\"/chapter/$it\"}" }.joinToString(",") + "]}"
        val file = requireNotNull(payloads.store(text))
        assertEquals(text, payloads.consume(file.path))
        assertFalse(file.exists())
    }
    @Test fun externalPathsAndSymlinksCannotBeConsumed() = withDirectory { directory ->
        val outside = Files.createTempFile("dream-outside-", ".json").toFile()
        try {
            outside.writeText("preserve")
            assertThrows(IllegalArgumentException::class.java) { PayloadFiles(directory).consume(outside.path) }
            val link = directory.resolve("reply-abcd.json")
            Files.createSymbolicLink(link.toPath(), outside.toPath())
            assertThrows(IllegalArgumentException::class.java) { PayloadFiles(directory).consume(link.path) }
            assertEquals("preserve", outside.readText())
        } finally { outside.delete() }
    }
    @Test fun abandonedRepliesExpireWithoutDeletingFreshReplies() = withDirectory { directory ->
        val payloads = PayloadFiles(directory)
        val text = "x".repeat(PayloadFiles.INLINE_BYTES + 1)
        val old = requireNotNull(payloads.store(text))
        assertTrue(old.setLastModified(1))
        val fresh = requireNotNull(payloads.store(text))
        assertFalse(old.exists())
        assertTrue(fresh.exists())
        payloads.discard(fresh.path)
        assertFalse(fresh.exists())
    }
    private fun withDirectory(block: (java.io.File) -> Unit) {
        val directory = Files.createTempDirectory("dream-replies-").toFile()
        try { block(directory) } finally { directory.deleteRecursively() }
    }
}
