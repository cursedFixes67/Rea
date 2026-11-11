package com.dreamreader.app

import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import org.junit.Assert.*
import org.junit.Test

class CancellableRequestsTest {
    @Test fun cancelledQueuedRegionNeverReachesDecoder() = runBlocking {
        val pool = CancellableRequests(this)
        val permit = Semaphore(1); val release = CompletableDeferred<Unit>()
        val decoded = mutableListOf<Int>(); val cancelled = mutableListOf<Int>()
        val first = pool.launch(1) { permit.withPermit { decoded += 1; release.await() } }
        yield()
        val queued = pool.launch(2, { cancelled += 2 }) { permit.withPermit { decoded += 2 } }
        yield(); pool.cancel(2); queued.join()
        release.complete(Unit); first.join()
        assertEquals(listOf(1), decoded)
        assertEquals(listOf(2), cancelled)
        assertEquals(0, pool.activeCount)
    }
    @Test fun completionOfCancelledRequestCannotRemoveReplacement() = runBlocking {
        val pool = CancellableRequests(this); val cleanup = CompletableDeferred<Unit>()
        val replacement = CompletableDeferred<Unit>()
        val old = pool.launch(1) { try { awaitCancellation() } finally { withContext(NonCancellable) { cleanup.await() } } }
        yield(); pool.cancel(1); yield()
        val next = pool.launch(1) { replacement.await() }
        yield(); cleanup.complete(Unit); old.join()
        assertEquals(1, pool.activeCount)
        replacement.complete(Unit); next.join()
        assertEquals(0, pool.activeCount)
    }
    @Test fun failureAndDuplicateIdentityDoNotLeakJobs() = runBlocking {
        val errors = mutableListOf<Throwable>()
        val owner = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined + CoroutineExceptionHandler { _, error -> errors += error })
        try {
            val pool = CancellableRequests(owner)
            pool.launch(1) { error("synthetic decoder failure") }.join()
            assertEquals(1, errors.size); assertEquals(0, pool.activeCount)
            val held = pool.launch(2) { awaitCancellation() }
            assertTrue(runCatching { pool.launch(2) {} }.isFailure)
            assertEquals(1, pool.activeCount)
            pool.cancel(2); held.join(); assertEquals(0, pool.activeCount)
        } finally { owner.cancel() }
    }
}
