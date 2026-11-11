package com.dreamreader.app

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update

/** A resizable concurrency gate. Reducing the limit lets active work finish. */
internal class DownloadLimiter(initialLimit: Int = 3) {
    private data class State(val active: Int, val limit: Int)
    private val state = MutableStateFlow(State(0, initialLimit.coerceIn(1, 6)))
    fun configure(limit: Int) {
        require(limit in 1..6) { "Choose between 1 and 6 concurrent chapters" }
        state.update { it.copy(limit = limit) }
    }
    suspend fun <T> withSlot(block: suspend () -> T): T {
        while (true) {
            val observed = state.value
            if (observed.active < observed.limit) {
                if (state.compareAndSet(observed, observed.copy(active = observed.active + 1))) break
            } else {
                state.first { it != observed }
            }
        }
        try { return block() }
        finally { state.update { it.copy(active = it.active - 1) } }
    }
}
