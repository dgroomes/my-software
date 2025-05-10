package my.dedupe

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Assertions.assertArrayEquals
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import java.io.FileOutputStream
import java.io.PrintStream

/**
 * Scratch pad.
 */
class ScratchTest {

    /**
     * This test case is not designed as a regression test but rather it's just a harness to run the deduplication
     * algorithm with debug output.
     */
    @Test
    fun `debug deduplication`() {
        val input = "so moreso moreso"
        val minLength = 3

        FileOutputStream("test.log").use { fos ->
            PrintStream(fos).use { ps ->
                val details = deduplicateDebug(minLength, input, ps)

                assertThat(details.result).isEqualTo("so more")

                val suffixes = details.suffixArray.map { input.substring(it) }
                assertThat(suffixes).isEqualTo(
                    listOf(
                        " moreso",
                        " moreso moreso",
                        "eso",
                        "eso moreso",
                        "moreso",
                        "moreso moreso",
                        "o",
                        "o moreso",
                        "o moreso moreso",
                        "oreso",
                        "oreso moreso",
                        "reso",
                        "reso moreso",
                        "so",
                        "so moreso",
                        "so moreso moreso",
                    )
                )

                val textsToRemove = details.consolidatedRanges
                    .map { input.substring(it) }

                assertThat(textsToRemove).isEqualTo(listOf("so moreso"))
            }
        }
    }

    /**
     * I don't know why this is happening but when there is a repeating sequence that itself is in a zig-zag order, the
     * suffix array is wrong.
     *
     * For example, the sequence "312" is repeated in the corpus. "312" zig-zags up-down (3 to 1 is down, 1 to 2 is up).
     */
    @Test
    fun testSuffixSort() {
        val input = "312312"
        val suffixArray = suffixArray(input)
        assertEquals(input.length, suffixArray.size, "Suffix array size should match input size for '$input'")

        println(prettyPrintSuffixArray(input, suffixArray))

        // Expect that suffix array is a permutation of [0, len)
        val sortedSuffix = suffixArray.clone()
        sortedSuffix.sort()
        val expected = IntArray(input.length) { i -> i }
        assertArrayEquals(expected, sortedSuffix, "Suffix array should be a permutation of indices for '$input'")

        // Expect that all suffixes are strictly ordered
        for (i in 1 until suffixArray.size) {
            val suffixA = input.slice(suffixArray[i - 1] until input.length)
            val suffixB = input.slice(suffixArray[i] until input.length)
            assertThat(suffixA).isLessThan(suffixB)
        }
    }
}
