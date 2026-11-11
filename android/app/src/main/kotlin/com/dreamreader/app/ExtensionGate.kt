package com.dreamreader.app

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update

/** Concurrent source requests, exclusive installation/removal, writer priority. */
internal class ExtensionGate {
    private data class State(val readers: Int = 0, val writer: Boolean = false, val waitingWriters: Int = 0)
    private val state = MutableStateFlow(State())

    suspend fun <T> read(block: suspend () -> T): T {
        while (true) {
            val observed = state.value
            if (!observed.writer && observed.waitingWriters == 0) {
                if (state.compareAndSet(observed, observed.copy(readers = observed.readers + 1))) break
            } else state.first { it != observed }
        }
        try { return block() }
        finally { state.update { it.copy(readers = it.readers - 1) } }
    }

    suspend fun <T> write(block: suspend () -> T): T {
        state.update { it.copy(waitingWriters = it.waitingWriters + 1) }
        var acquired = false
        try {
            while (true) {
                val observed = state.value
                if (!observed.writer && observed.readers == 0) {
                    if (state.compareAndSet(observed, observed.copy(writer = true, waitingWriters = observed.waitingWriters - 1))) {
                        acquired = true
                        break
                    }
                } else state.first { it != observed }
            }
            return block()
        } finally {
            state.update { if (acquired) it.copy(writer = false) else it.copy(waitingWriters = it.waitingWriters - 1) }
        }
    }
}
