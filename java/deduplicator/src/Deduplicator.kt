const val DEBUG = false

private fun log(message: String) {
    if (DEBUG) System.err.println(message)
}

/**
 * Deduplicate repeated blocks of text.
 *
 * See the README for details.
 */
fun main() {
    val minLengthStr = System.getenv("MIN_CANDIDATE_LENGTH")
        ?: throw IllegalStateException("Required environment variable 'MIN_CANDIDATE_LENGTH' is not set")

    val minLength = minLengthStr.toIntOrNull()
        ?: throw IllegalStateException("Environment variable 'MIN_CANDIDATE_LENGTH' must be a valid integer but was: '$minLengthStr'")

    val input = System.`in`.bufferedReader().use { it.readText() }
    val deduped = deduplicate(minLength, input)
    println(deduped)
}

fun deduplicate(minLength: Int, input: String): String {
    log("Deduplicating document of length ${input.length} with minimum candidate length of $minLength")

    log("Building suffix array")
    val suffixArray = suffixArray(input)

    log("Finding duplicate ranges")
    val rangesToRemove = findDuplicateRanges(input, suffixArray, minLength)

    log("Applying removals")
    val result = applyRemovals(input, rangesToRemove)

    log("Deduplication complete. Original length: ${input.length}, new length: ${result.length}")
    return result
}

/**
 * Find all duplicate ranges that should be removed.
 * This function identifies duplicates and determines which occurrences to remove.
 */
fun findDuplicateRanges(text: String, suffixArray: List<Int>, minLength: Int): List<IntRange> {
    val rangesToRemove = mutableListOf<IntRange>()
    val lcpArray = computeLcpArray(text, suffixArray)

    // Group suffixes by common prefixes
    var i = 0
    while (i < lcpArray.size) {
        val lcp = lcpArray[i]
        if (lcp >= minLength) {
            // Found a duplicate substring of sufficient length
            // Find all consecutive suffixes that share this prefix
            val positions = mutableListOf(suffixArray[i], suffixArray[i + 1])
            var j = i + 1
            while (j < lcpArray.size && lcpArray[j] >= lcp) {
                positions.add(suffixArray[j + 1])
                j++
            }

            // Find the earliest occurrence in the original text
            val earliestPos = positions.minOrNull()!!

            // Mark all but the earliest occurrence for removal
            val dupLength = lcp
            for (pos in positions) {
                if (pos != earliestPos) {
                    rangesToRemove.add(pos until pos + dupLength)
                }
            }

            // Skip all suffixes that were part of this group
            i = j
        } else {
            i++
        }
    }

    // Sort ranges and remove overlaps
    return consolidateRanges(rangesToRemove)
}

/**
 * Consolidate overlapping ranges to avoid removing the same text multiple times.
 */
fun consolidateRanges(ranges: List<IntRange>): List<IntRange> {
    log("Consolidating ranges")
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
 * LCP\[i] = length of the longest common prefix between
 * the suffix at position i and position i+1 in the suffix array.
 */
fun computeLcpArray(text: String, suffixArray: List<Int>): List<Int> {
    val lcp = MutableList(suffixArray.size - 1) { 0 }

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

fun suffixArray(text: String): List<Int> {
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
    }
}
