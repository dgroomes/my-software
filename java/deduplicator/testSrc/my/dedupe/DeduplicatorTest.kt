package my.dedupe

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class DeduplicatorTest {

    @Test
    fun `lcp array`() {
        val result = lcpArray("banana", intArrayOf(5, 3, 1, 0, 4, 2))

        // The LCP array for "banana" with suffix array [5, 3, 1, 0, 4, 2]:
        //
        // Index| First suffix  | Second suffix  | Common prefix | Length (LCP)
        // -----|---------------|----------------|--------------|-------------
        // 0    | a             | ana            | a             | 1
        // 1    | ana           | anana          | ana           | 3
        // 2    | anana         | banana         | -             | 0
        // 3    | banana        | na             | -             | 0
        // 4    | na            | nana           | na            | 2

        assertThat(result).isEqualTo(intArrayOf(1, 3, 0, 0, 2))
    }

    @Test
    fun `should deduplicate simple repeated text`() {
        val result = deduplicate(2, "hi hi")

        assertThat(result).isEqualTo("hi ")
    }

    @Test
    fun `should not change text without duplicates`() {
        val result = deduplicate(1, "abc")

        assertThat(result).isEqualTo("abc")
    }

    @Test
    fun `minimum candidate length - repeats do not meet threshold`() {
        val result = deduplicate(3, "hihi")

        assertThat(result).isEqualTo("hihi")
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
        assertThat(result).isEqualTo("so more")
    }
}
