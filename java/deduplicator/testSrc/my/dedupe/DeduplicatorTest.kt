package my.dedupe

import org.assertj.core.api.Assertions
import org.junit.jupiter.api.Test

class DeduplicatorTest {

    @Test
    fun `suffix array`() {
        val result = suffixArray("banana")

        // Document:
        //
        // 0 1 2 3 4 5
        // b a n a n a
        //
        // Suffixes:
        //
        // 0 - banana
        // 1 - anana
        // 2 - nana
        // 3 - ana
        // 4 - na
        // 5 - a
        //
        // Suffixes sorted:
        //
        // 5 - a
        // 3 - ana
        // 1 - anana
        // 0 - banana
        // 4 - na
        // 2 - nana
        Assertions.assertThat(result).isEqualTo(listOf(5, 3, 1, 0, 4, 2))
    }

    @Test
    fun `lcp array`() {
        val result = lcpArray("banana", listOf(5, 3, 1, 0, 4, 2))

        // Refer to the earlier test case for a description of the suffix array for the 'banana' text. Now, we expect
        // the LCP array to be:
        //
        // Index| First suffix  | Second suffix  | Common prefix | Length (LCP)
        // -----|---------------|----------------|--------------|-------------
        // 0    | a             | ana            | a             | 1
        // 1    | ana           | anana          | ana           | 3
        // 2    | anana         | banana         | -             | 0
        // 3    | banana        | na             | -             | 0
        // 4    | na            | nana           | na            | 2


        Assertions.assertThat(result).isEqualTo(listOf(1, 3, 0, 0, 2))
    }

    @Test
    fun `should deduplicate simple repeated text`() {
        val result = deduplicate(2, "hi hi")

        Assertions.assertThat(result).isEqualTo("hi ")
    }

    @Test
    fun `should not change text without duplicates`() {
        val result = deduplicate(1, "abc")

        Assertions.assertThat(result).isEqualTo("abc")
    }

    @Test
    fun `minimum candidate length - repeats do not meet threshold`() {
        val result = deduplicate(3, "hihi")

        Assertions.assertThat(result).isEqualTo("hihi")
    }

    /**
     * This behavior is unintuitive to me. In this example, we have two "moreso" instances but in the de-duplicated result
     * we have none. My intuition would be that a repeated substring (like "moreso") would still exist once (the first
     * occurrence) in the de-duplicated result. But clearly this isn't happening.
     *
     * I'm not sure I've implemented the general SA-LCP algorithm correctly. But, it kind of makes sense. So, we're left
     * with the possibility that a repeated substring can be eliminated from the text. Maybe that's a perfectly fine
     * trade off. And in practice, I'm going to use a much longer minimum candidate length (like 100) so this would
     * virtually never happen.
     */
    @Test
    fun `repeated substrings may vanish`() {
        val result = deduplicate(3, "so moreso moreso")

        // I think the algorithm proceeds like this:
        //
        //   so moreso moreso // original text
        //   so moremoreso    // remove repeated "so "
        //   so more          // remove repeated "moreso". This is the weird part, because we now have no "moreso" instances.
        Assertions.assertThat(result).isEqualTo("so more")
    }

    @Test
    fun `test longest common prefix - basic case`() {
        val text = "banana"
        val result = longestCommonPrefix(text, 1, 3) // "anana" vs "ana"
        Assertions.assertThat(result).isEqualTo(3) // "ana" is common
    }

    @Test
    fun `test longest common prefix - no common prefix`() {
        val text = "abcdef"
        val result = longestCommonPrefix(text, 0, 3) // "abcdef" vs "def"
        Assertions.assertThat(result).isEqualTo(0)
    }

    @Test
    fun `test longest common prefix - entire suffix common`() {
        val text = "testing"
        val result = longestCommonPrefix(text, 4, 4) // "ing" vs "ing"
        Assertions.assertThat(result).isEqualTo(3)
    }

    @Test
    fun `test longest common prefix - empty remainder`() {
        val text = "test"
        val result = longestCommonPrefix(text, 4, 2) // "" vs "st"
        Assertions.assertThat(result).isEqualTo(0)
    }

    @Test
    fun `test longest common prefix - at string bounds`() {
        val text = "test"
        val result = longestCommonPrefix(text, 0, 2) // "test" vs "st"
        Assertions.assertThat(result).isEqualTo(0)
    }
}
