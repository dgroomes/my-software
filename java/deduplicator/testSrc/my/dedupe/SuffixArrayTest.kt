package my.dedupe

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.Test

/**
 * Tests for the SA-IS (Suffix Array Induced Sorting) algorithm implementation.
 *
 * Many of the test strings and test cases in this file are adapted from:
 * https://github.com/oguzbilgener/sa-is/blob/main/src/lib.rs
 *
 * See LICENSES/SA-IS.txt for license information.
 */
class SuffixArrayTest {

    companion object {
        // Test strings adapted from TEST_STRS_1 in https://github.com/oguzbilgener/sa-is/blob/main/src/lib.rs
        // Original test strings are byte arrays; we use String equivalents here.
        // The binary test string (b"\xFF\xFE...") is omitted as it's not representable as a valid UTF-16 String.
        private val TEST_STRINGS = arrayOf(
            "a",
            "aa",
            "za",
            "CACAO",
            "aaaaa",
            "banana",
            "tobeornottobe",
            "The quick brown fox jumps over the lazy dog.",
            "elephantelephantelephantelephantelephant",
            "walawalawashington",
            "-------------------------",
            "011010011001011010010110011010010",
            "3141592653589793238462643383279502884197169399375105",
            "abccbaabccbaabccbaabccbaabccbaabccbaabccbaabccba",
            "0123456789876543210",
            "9876543210123456789",
            "aababcabcdabcdeabcdefabcdefg",
            "asdhklgalksdjghalksdjghalksdjgh",
            // Additional test string (not from sa-is)
            """
# deduplicator

Deduplicate repeated blocks of text.


## Overview

I want to deduplicate text so that I can have smaller LLM prompts. Consider the use-case of copying a whole codebase,
or large swaths of a huge codebase. There is often a license block that appears in block comments in every file of the
source code:
            """.trimIndent()
        )

        // Verification approach adapted from run_test_suffix_sort in
        // https://github.com/oguzbilgener/sa-is/blob/main/src/lib.rs
        private fun verifySuffixArray(input: String, suffixArray: IntArray): Boolean {
            if (input.length != suffixArray.size) return false

            // Verify it's a permutation
            val sorted = suffixArray.clone()
            sorted.sort()
            for (i in sorted.indices) {
                if (sorted[i] != i) return false
            }

            // Verify suffixes are in order
            for (i in 1 until suffixArray.size) {
                val suffixA = input.substring(suffixArray[i - 1])
                val suffixB = input.substring(suffixArray[i])
                if (suffixA >= suffixB) return false
            }
            return true
        }
    }

    // Test approach adapted from test_suffix_sort_1 in
    // https://github.com/oguzbilgener/sa-is/blob/main/src/lib.rs
    @Test
    fun `SA-IS produces correct suffix arrays for various inputs`() {
        for (input in TEST_STRINGS) {
            val sa = suffixArray(input)
            assertEquals(input.length, sa.size, "Suffix array size should match input size")

            // Expect that suffix array is a permutation of [0, len)
            val sortedSuffix = sa.clone()
            sortedSuffix.sort()
            val expected = IntArray(input.length) { i -> i }
            assertArrayEquals(expected, sortedSuffix, "Suffix array should be a permutation of indices")

            // Expect that all suffixes are strictly ordered
            for (i in 1 until sa.size) {
                val suffixA = input.slice(sa[i - 1] until input.length)
                val suffixB = input.slice(sa[i] until input.length)
                assertThat(suffixA).isLessThan(suffixB)
            }
        }
    }

    @Test
    fun `classic banana example`() {
        val input = "banana"
        val sa = suffixArray(input)

        // Expected suffix array for "banana":
        // Suffixes sorted: a(5), ana(3), anana(1), banana(0), na(4), nana(2)
        assertThat(sa.toList()).isEqualTo(listOf(5, 3, 1, 0, 4, 2))
    }

    @Test
    fun `correctness verification for all test strings`() {
        for (input in TEST_STRINGS) {
            assertTrue(
                verifySuffixArray(input, suffixArray(input)),
                "Suffix array should be correct for: ${input.take(30)}..."
            )
        }
    }

    // Test cases adapted from test_induced_sort_substring in
    // https://github.com/oguzbilgener/sa-is/blob/main/src/lib.rs
    // Comments like "L; a$" are from the original Rust source.
    @Test
    fun `induced sort basic cases`() {
        // L; a$
        assertArrayEquals(intArrayOf(0), suffixArray("a"))
        // SL; ab$, b$
        assertArrayEquals(intArrayOf(0, 1), suffixArray("ab"))
        // LL; a$, ba$
        assertArrayEquals(intArrayOf(1, 0), suffixArray("ba"))
        // SLL; a$, aba$, ba$
        assertArrayEquals(intArrayOf(2, 0, 1), suffixArray("aba"))
        // LSL; ab$, b$, bab
        assertArrayEquals(intArrayOf(1, 2, 0), suffixArray("bab"))
        // SSL; aab$, ab$, b$
        assertArrayEquals(intArrayOf(0, 1, 2), suffixArray("aab"))
        // LSSL; aab$, ab$, b$, baab
        assertArrayEquals(intArrayOf(1, 2, 3, 0), suffixArray("baab"))
    }

    @Test
    fun `handles repeating characters`() {
        val input = "aaaaa"
        val sa = suffixArray(input)

        // For "aaaaa", suffixes sorted alphabetically are:
        // a(4), aa(3), aaa(2), aaaa(1), aaaaa(0)
        assertThat(sa.toList()).isEqualTo(listOf(4, 3, 2, 1, 0))
    }

    @Test
    fun `handles worst case - single repeated character`() {
        val sizes = listOf(100, 500, 1000)
        for (size in sizes) {
            val input = "a".repeat(size)
            val sa = suffixArray(input)

            // Should be [size-1, size-2, ..., 1, 0]
            val expected = IntArray(size) { size - 1 - it }
            assertArrayEquals(expected, sa, "Failed for size $size")
        }
    }
}
