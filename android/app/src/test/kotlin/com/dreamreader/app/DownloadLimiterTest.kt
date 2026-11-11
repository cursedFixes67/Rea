package com.dreamreader.app

import kotlinx.coroutines.*
import org.junit.Assert.*
import org.junit.Test

class DownloadLimiterTest {
    @Test fun raisingLimitWakesAnAlreadyQueuedChapter() = runBlocking {
        val limiter = DownloadLimiter(1)
        val entered = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()
        val first = launch { limiter.withSlot { entered.complete(Unit); release.await() } }
        entered.await()
        val attempted = CompletableDeferred<Unit>()
        val nextEntered = CompletableDeferred<Unit>()
        val second = launch { attempted.complete(Unit); limiter.withSlot { nextEntered.complete(Unit) } }
        attempted.await(); yield()
        assertFalse(nextEntered.isCompleted)
        limiter.configure(2)
        withTimeout(2000) { nextEntered.await() }
        release.complete(Unit)
        joinAll(first, second)
    }
    @Test fun shrinkingLimitDoesNotInterruptActiveWorkOrStartExtraWork() = runBlocking {
        val limiter = DownloadLimiter(2)
        val started = List(2) { CompletableDeferred<Unit>() }
        val release = List(2) { CompletableDeferred<Unit>() }
        val workers = List(2) { i -> launch { limiter.withSlot { started[i].complete(Unit); release[i].await() } } }
        started.forEach { it.await() }
        limiter.configure(1)
        val entered = CompletableDeferred<Unit>()
        val queued = launch { limiter.withSlot { entered.complete(Unit) } }
        yield(); assertFalse(entered.isCompleted)
        release[0].complete(Unit); workers[0].join(); yield()
        assertFalse(entered.isCompleted)
        release[1].complete(Unit)
        withTimeout(2000) { entered.await() }
        workers.forEach { it.join() }; queued.join()
    }
    @Test fun cancelledAndFailedJobsDoNotLeakPermits() = runBlocking {
        val limiter = DownloadLimiter(1)
        val started = CompletableDeferred<Unit>()
        val running = launch { limiter.withSlot { started.complete(Unit); awaitCancellation() } }
        started.await()
        val queued = launch { limiter.withSlot { fail("Cancelled job must not start") } }
        yield(); queued.cancelAndJoin(); running.cancelAndJoin()
        try { limiter.withSlot { throw IllegalStateException("synthetic failure") } }
        catch (_: IllegalStateException) { }
        assertEquals("next", withTimeout(2000) { limiter.withSlot { "next" } })
    }
    @Test fun invalidLimitsAreRejected() {
        val limiter = DownloadLimiter()
        assertThrows(IllegalArgumentException::class.java) { limiter.configure(0) }
        assertThrows(IllegalArgumentException::class.java) { limiter.configure(7) }
    }
}
