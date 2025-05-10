package my.dedupe

/**
 * Find all duplicate ranges that should be removed.
 * This function identifies duplicates and determines which occurrences to remove.
 */
fun findDuplicateRanges(suffixArray: IntArray, minLength: Int, lcpArr: IntArray): List<IntRange> {
    val rangesToRemove = mutableListOf<IntRange>()

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

            // Mark all but the earliest occurrence for removal
            for (pos in positions) {
                if (pos != earliestPos) {
                    rangesToRemove.add(pos until pos + lcp)
                }
            }

            // Skip all suffixes that were part of this group. I dont' understand why this is ok. Aren't we missing even
            // longer matches among those?
            i = j
        } else {
            i++
        }
    }

    return rangesToRemove
}

/**
 * Consolidate overlapping ranges to avoid removing the same text multiple times.
 */
fun consolidateRanges(ranges: List<IntRange>): List<IntRange> {
    if (ranges.isEmpty()) return emptyList()

    // Sort ranges by start position
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
 * Compute the LCP (Longest Common Prefix) array.
 * LCP\[i] = length of the longest common prefix between the suffix at position i and position i+1 in the suffix array.
 *
 * Note that this LCP array is one element shorter than the suffix array. By contrast, in many implementations, an LCP
 * array is the same length as the suffix array and the first element is -1.
 *
 * This implementation is naive. There are more efficient algorithms. But in practice, it should be fast because there
 * aren't tons of duplicates so it shouldn't have to "compute deep" into neighboring suffixes very often.
 */
fun lcpArray(text: String, suffixArray: IntArray): IntArray {
    val lcp = IntArray(suffixArray.size - 1)

    for (i in 0 until suffixArray.size - 1) {
        val pos1 = suffixArray[i]
        val pos2 = suffixArray[i + 1]
        lcp[i] = longestCommonPrefix(text, pos1, pos2)
    }

    return lcp
}

/**
 * Find the length of the longest common prefix between two suffixes.
 */
fun longestCommonPrefix(text: String, start1: Int, start2: Int): Int {
    var length = 0
    val maxLength = minOf(text.length - start1, text.length - start2)

    while (length < maxLength && text[start1 + length] == text[start2 + length]) {
        length++
    }

    return length
}

fun suffixArray(text: String): IntArray {
    return text.indices.sortedWith { a, b ->
        var i = a
        var j = b
        while (i < text.length && j < text.length) {
            val charComp = text[i].compareTo(text[j])
            if (charComp != 0) return@sortedWith charComp
            i++
            j++
        }
        // If we get here, one is a prefix of the other
        // The shorter one should come first
        when {
            i == text.length && j < text.length -> -1
            j == text.length && i < text.length -> 1
            else -> 0
        }
    }.toIntArray()
}

fun deduplicate(minLength: Int, input: String): String {
    val suffixArr = suffixArray(input)
    val lcpArr = lcpArray(input, suffixArr)
    var rangesToRemove = findDuplicateRanges(suffixArr, minLength, lcpArr)
    rangesToRemove = consolidateRanges(rangesToRemove)
    return applyRemovals(input, rangesToRemove)
}
