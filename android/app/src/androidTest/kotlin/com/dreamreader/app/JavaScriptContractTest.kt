package com.dreamreader.app

import androidx.test.platform.app.InstrumentationRegistry
import eu.kanade.tachiyomi.network.JavaScriptEngine
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test

/** Optional device acceptance for the actual ARM64/JNI adapter, not a mock engine. */
class JavaScriptContractTest {
    private fun engine() = JavaScriptEngine(InstrumentationRegistry.getInstrumentation().targetContext)

    @Test fun preservesPrimitiveResults() = runBlocking {
        val engine = engine()
        assertNull(engine.evaluate<Any?>("null"))
        assertNull(engine.evaluate<Any?>("undefined"))
        assertEquals(42, engine.evaluate<Int>("6 * 7"))
        assertEquals(1.25, engine.evaluate<Double>("5 / 4"), 0.0)
        assertTrue(engine.evaluate<Boolean>("1 < 2"))
        assertEquals("漫画 🌙", engine.evaluate<String>("'漫画 🌙'"))
        assertTrue(engine.evaluate<Double>("NaN").isNaN())
        assertEquals(Double.POSITIVE_INFINITY, engine.evaluate<Double>("Infinity"), 0.0)
    }
    @Test fun reportsErrorsAndDoesNotShareGlobalsAcrossConcurrentRequests() = runBlocking {
        val engine = engine()
        assertTrue(runCatching { engine.evaluate<Any?>("throw new Error('synthetic failure')") }.isFailure)
        val values = (0 until 12).map { i -> async { engine.evaluate<Int>("let local = $i; local * 2") } }.awaitAll()
        assertEquals((0 until 12).map { it * 2 }, values)
        assertEquals("undefined", engine.evaluate<String>("typeof local"))
    }
}
