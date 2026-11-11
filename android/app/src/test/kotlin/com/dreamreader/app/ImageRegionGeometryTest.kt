package com.dreamreader.app

import org.junit.Assert.*
import org.junit.Test

class ImageRegionGeometryTest {
    @Test fun tallPageIsCoveredWithoutGapsOrOverlap() {
        val image = ImageRegionGeometry(1200, 100001)
        assertEquals(1, image.sample)
        var previous = 0
        repeat(image.count) {
            val (top, bottom) = image.bounds(it)
            assertEquals(previous, top)
            assertTrue(bottom > top)
            assertTrue(bottom - top <= 2048)
            previous = bottom
        }
        assertEquals(image.height, previous)
    }
    @Test fun hugeImagesHaveBoundedDecodedRegionsAndNoOverflow() {
        for (width in listOf(1, 1800, 1801, 9000, Int.MAX_VALUE)) {
            val image = ImageRegionGeometry(width, Int.MAX_VALUE)
            assertTrue((width.toLong() + image.sample - 1) / image.sample <= 1800)
            val (top, bottom) = image.bounds(image.count - 1)
            assertTrue(top >= 0)
            assertEquals(Int.MAX_VALUE, bottom)
            assertTrue((bottom.toLong() - top + image.sample - 1) / image.sample <= 2048)
        }
    }
    @Test fun invalidDimensionsAndRegionsAreRejected() {
        assertThrows(IllegalArgumentException::class.java) { ImageRegionGeometry(0, 10) }
        assertThrows(IllegalArgumentException::class.java) { ImageRegionGeometry(10, -1) }
        val image = ImageRegionGeometry(100, 100)
        assertThrows(IllegalArgumentException::class.java) { image.bounds(-1) }
        assertThrows(IllegalArgumentException::class.java) { image.bounds(1) }
    }
}
