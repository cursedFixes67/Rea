package com.dreamreader.app

import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.*

/** Cancels viewport work, including tasks still waiting for a decode permit. */
internal class CancellableRequests(private val scope: CoroutineScope) {
    private val jobs = ConcurrentHashMap<Int, Job>()
    val activeCount get() = jobs.size
    fun launch(id: Int, onCancelled: () -> Unit = {}, block: suspend () -> Unit): Job {
        val job = scope.launch(start = CoroutineStart.LAZY) { block() }
        if (jobs.putIfAbsent(id, job) != null) {
            job.cancel()
            error("Duplicate image request identity")
        }
        job.invokeOnCompletion { cause ->
            jobs.remove(id, job)
            if (cause is CancellationException) onCancelled()
        }
        job.start()
        return job
    }
    fun cancel(id: Int) { jobs.remove(id)?.cancel() }
}
