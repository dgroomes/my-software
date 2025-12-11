package my.dedupe

import java.util.TreeMap

/**
 * Find all duplicate ranges that should be removed.
 * This function identifies duplicates and determines which occurrences to remove.
 *
 * Uses a TreeMap to consolidate ranges on-the-fly, which avoids creating millions
 * of IntRange objects and enables processing of large corpora like the Kafka source code.
 */
fun findDuplicateRanges(suffixArray: IntArray, minLength: Int, lcpArr: IntArray): List<IntRange> {
    // Use a TreeMap to consolidate ranges on-the-fly
    // Key: start position, Value: end position (exclusive)
    // This avoids creating millions of IntRange objects
    val rangeMap = TreeMap<Int, Int>()

    fun addRange(start: Int, end: Int) {
        // Find overlapping or adjacent ranges and merge
        var newStart = start
        var newEnd = end

        // Check for range that ends at or after our start
        val floorEntry = rangeMap.floorEntry(start)
        if (floorEntry != null && floorEntry.value >= start) {
            // Overlaps with or adjacent to floor entry - merge
            newStart = floorEntry.key
            newEnd = maxOf(newEnd, floorEntry.value)
            rangeMap.remove(floorEntry.key)
        }

        // Remove all ranges that start within our new range
        while (true) {
            val higherEntry = rangeMap.higherEntry(newStart)
            if (higherEntry != null && higherEntry.key <= newEnd) {
                newEnd = maxOf(newEnd, higherEntry.value)
                rangeMap.remove(higherEntry.key)
            } else {
                break
            }
        }

        rangeMap[newStart] = newEnd
    }

    // Group suffixes by common prefixes
    var i = 0
    while (i < lcpArr.size) {
        val lcp = lcpArr[i]
        if (lcp >= minLength) {
            // Found a duplicate substring of sufficient length
            // Find all consecutive suffixes that share this prefix
            val positions = mutableListOf(suffixArray[i], suffixArray[i + 1])
            var j = i + 1
            while (j < lcpArr.size && lcpArr[j] >= lcp) {
                positions.add(suffixArray[j + 1])
                j++
            }

            // Find the earliest occurrence in the original text
            val earliestPos = positions.minOrNull()!!

            // Mark all but the earliest occurrence for removal (consolidating on-the-fly)
            for (pos in positions) {
                if (pos != earliestPos) {
                    addRange(pos, pos + lcp)
                }
            }

            // Skip all suffixes that were part of this group
            i = j
        } else {
            i++
        }
    }

    // Convert TreeMap to list of IntRange
    return rangeMap.map { (start, end) -> start until end }
}

/**
 * Consolidate overlapping ranges to avoid removing the same text multiple times.
 * Note: With the new findDuplicateRanges implementation, ranges are already consolidated,
 * so this function is now essentially a no-op but kept for API compatibility.
 */
fun consolidateRanges(ranges: List<IntRange>): List<IntRange> {
    if (ranges.isEmpty()) return emptyList()

    // Ranges should already be consolidated, but handle the case where they're not
    val sortedRanges = ranges.sortedBy { it.first }
    val result = mutableListOf<IntRange>()

    var current = sortedRanges[0]
    for (i in 1 until sortedRanges.size) {
        val next = sortedRanges[i]
        if (next.first <= current.last + 1) {
            // Ranges overlap or are adjacent, merge them
            current = current.first..maxOf(current.last, next.last)
        } else {
            // No overlap, add current range and move to next
            result.add(current)
            current = next
        }
    }
    result.add(current)

    return result
}

/**
 * Apply the removals to the original text.
 */
fun applyRemovals(text: String, rangesToRemove: List<IntRange>): String {
    if (rangesToRemove.isEmpty()) return text

    val builder = StringBuilder()
    var lastPos = 0

    for (range in rangesToRemove) {
        // Add text between the last removal and this one
        builder.append(text.substring(lastPos, range.first))
        lastPos = range.last + 1
    }

    // Add remaining text after the last removal
    if (lastPos < text.length) {
        builder.append(text.substring(lastPos))
    }

    return builder.toString()
}

/**
 * Compute the LCP (Longest Common Prefix) array using Kasai's algorithm.
 * LCP\[i] = length of the longest common prefix between the suffix at position i and position i+1 in the suffix array.
 *
 * Note that this LCP array is one element shorter than the suffix array. By contrast, in many implementations, an LCP
 * array is the same length as the suffix array and the first element is -1.
 *
 * Kasai's algorithm runs in O(n) time. The key insight is that if we know LCP[rank[i]] = k, then
 * LCP[rank[i+1]] >= k-1. This is because when we move one character forward in the text, we lose at most
 * one character from the common prefix.
 */
fun lcpArray(text: String, suffixArray: IntArray): IntArray {
    val n = suffixArray.size
    if (n <= 1) return IntArray(0)

    // Build the inverse suffix array (rank array)
    // rank[i] = position of suffix starting at i in the sorted suffix array
    val rank = IntArray(n)
    for (i in 0 until n) {
        rank[suffixArray[i]] = i
    }

    val lcp = IntArray(n - 1)
    var k = 0 // Current LCP length

    // Process suffixes in text order (not suffix array order)
    for (i in 0 until n) {
        val r = rank[i]

        // Skip the first suffix in sorted order (no predecessor to compare with)
        if (r == 0) {
            k = 0
            continue
        }

        // j is the text position of the suffix that comes before suffix i in sorted order
        val j = suffixArray[r - 1]

        // Extend the match as far as possible
        while (i + k < n && j + k < n && text[i + k] == text[j + k]) {
            k++
        }

        lcp[r - 1] = k

        // Key insight: when we move to the next text position, we can only lose at most 1 from the LCP
        if (k > 0) k--
    }

    return lcp
}

fun deduplicate(minLength: Int, input: String): String {
    val suffixArr = suffixArray(input)
    val lcpArr = lcpArray(input, suffixArr)
    var rangesToRemove = findDuplicateRanges(suffixArr, minLength, lcpArr)
    rangesToRemove = consolidateRanges(rangesToRemove)
    return applyRemovals(input, rangesToRemove)
}
