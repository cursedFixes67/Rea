package com.dreamreader.app

import kotlinx.coroutines.*
import org.junit.Assert.*
import org.junit.Test

class ExtensionGateTest {
    @Test fun readersOverlapButInstallWaitsForEveryReader() = runBlocking {
        val gate = ExtensionGate()
        val first = CompletableDeferred<Unit>(); val second = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>(); var wrote = false
        val a = launch { gate.read { first.complete(Unit); release.await() } }
        val b = launch { gate.read { second.complete(Unit); release.await() } }
        withTimeout(1000) { first.await(); second.await() }
        val writer = launch(start = CoroutineStart.UNDISPATCHED) { gate.write { wrote = true } }
        assertFalse(wrote)
        release.complete(Unit)
        withTimeout(1000) { joinAll(a, b, writer) }
        assertTrue(wrote)
    }
    @Test fun waitingInstallerPrecedesNewSourceRequests() = runBlocking {
        val gate = ExtensionGate(); val release = CompletableDeferred<Unit>()
        val order = mutableListOf<String>()
        val a = launch(start = CoroutineStart.UNDISPATCHED) { gate.read { release.await() } }
        val writer = launch(start = CoroutineStart.UNDISPATCHED) { gate.write { order += "install" } }
        val b = launch(start = CoroutineStart.UNDISPATCHED) { gate.read { order += "source" } }
        assertTrue(order.isEmpty())
        release.complete(Unit)
        withTimeout(1000) { joinAll(a, writer, b) }
        assertEquals(listOf("install", "source"), order)
    }
    @Test fun cancelledInstallerDoesNotBlockOtherReaders() = runBlocking {
        val gate = ExtensionGate(); val release = CompletableDeferred<Unit>()
        val a = launch(start = CoroutineStart.UNDISPATCHED) { gate.read { release.await() } }
        val writer = launch(start = CoroutineStart.UNDISPATCHED) { gate.write { fail("Cancelled install entered") } }
        writer.cancelAndJoin()
        assertEquals(42, withTimeout(1000) { gate.read { 42 } })
        release.complete(Unit); a.join()
    }
    @Test fun failuresAndCancelledReadersReleaseTheirLeases() = runBlocking {
        val gate = ExtensionGate()
        runCatching { gate.read { error("source failure") } }
        runCatching { gate.write { error("install failure") } }
        val release = CompletableDeferred<Unit>()
        val writer = launch(start = CoroutineStart.UNDISPATCHED) { gate.write { release.await() } }
        val reader = launch(start = CoroutineStart.UNDISPATCHED) { gate.read { fail("Cancelled reader entered") } }
        reader.cancelAndJoin(); release.complete(Unit); writer.join()
        assertEquals(7, withTimeout(1000) { gate.write { 7 } })
    }
}
