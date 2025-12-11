package my.dedupe

/**
 * The SA-IS (Suffix Array Induced Sorting) algorithm for suffix array construction.
 *
 * This implementation is derived from:
 * - The Chromium project's SA-IS implementation (BSD-3-Clause license)
 * - Oguz Bilgener's Rust port (MIT license): https://github.com/oguzbilgener/sa-is
 * - Google Research's deduplicate-text-datasets (Apache 2.0): https://github.com/google-research/deduplicate-text-datasets
 *
 * SA-IS runs in O(n) time and O(n) space, making it optimal for suffix array construction.
 *
 * This implementation uses IntArray throughout to avoid boxing overhead.
 */

const val S_TYPE = false
const val L_TYPE = true

fun suffixArray(input: String): IntArray {
    // Convert string to IntArray of character codes (no boxing!)
    val chars = IntArray(input.length) { input[it].code }
    // keyBound must be large enough for the initial char values (0-65535)
    val keyBound = 65536
    val suffixArray = IntArray(chars.size)
    suffixSortRec(chars, keyBound, suffixArray)
    return suffixArray
}

/**
 * Recursive SA-IS implementation using IntArray to avoid boxing.
 */
private fun suffixSortRec(input: IntArray, keyBound: Int, suffixArray: IntArray) {
    if (input.size == 1) {
        suffixArray[0] = 0
    }
    if (input.size < 2) {
        return
    }

    val (slPartition, lmsCount) = buildSlPartition(input)
    val lmsIndices = findLmsSuffixes(slPartition, lmsCount)
    val buckets = makeBucketCount(input, keyBound)

    if (lmsIndices.size > 1) {
        // Given |lms_indices| in the same order they appear in |str|, induce
        // LMS substrings relative order and write result to |suffix_array|.
        inducedSort(input, slPartition, lmsIndices, buckets, suffixArray)

        // Given LMS substrings in relative order found in |suffix_array|,
        // map LMS substrings to unique labels to form a new string, |lms_str|.
        val (lmsStr, labelCount) =
            labelLmsSubstrings(input, slPartition, suffixArray, lmsIndices)

        if (labelCount < lmsIndices.size) {
            // Reorder |lms_str| to have LMS suffixes in the same order they
            // appear in |str|.
            for (i in lmsIndices.indices) {
                suffixArray[lmsIndices[i]] = lmsStr[i]
            }

            var previousType = S_TYPE
            var j = 0
            for (i in 0 until slPartition.size) {
                val currentType = slPartition[i]
                if (currentType == S_TYPE && previousType == L_TYPE) {
                    lmsStr[j] = suffixArray[i]
                    lmsIndices[j] = i
                    j += 1
                }
                previousType = currentType
            }

            // Recursively apply SuffixSort on |lms_str|.
            // IMPORTANT: Use labelCount as keyBound for recursion.
            suffixSortRec(lmsStr, labelCount, suffixArray)

            // Map LMS labels back to indices in |str| and write result to
            // |lms_indices|. We're using |suffix_array| as a temporary buffer.
            for (i in 0 until lmsIndices.size) {
                suffixArray[i] = lmsIndices[suffixArray[i]]
            }

            val length = lmsIndices.size
            for (i in 0 until length) {
                lmsIndices[i] = suffixArray[i]
            }
        }
    }
    // Given |lms_indices| where LMS suffixes are sorted, induce the full
    // order of suffixes in |str|.
    inducedSort(input, slPartition, lmsIndices, buckets, suffixArray)
}

private fun inducedSort(
    input: IntArray,
    slPartition: BitSlice,
    lmsIndices: IntArray,
    buckets: IntArray,
    suffixArray: IntArray
) {
    val length = input.size
    // All indices are first marked as unset with the illegal value |length|.
    suffixArray.fill(length, 0, length)

    // Used to mark bucket boundaries (head or end) as indices in str.
    val bucketBounds = IntArray(buckets.size)

    // Step 1: Assign indices for LMS suffixes, populating the end of
    // respective buckets but keeping relative order.

    partialSum(buckets, bucketBounds)

    // Process each `lms_indices` in reverse and assign them to the end of their
    // respective buckets, so relative order is preserved.
    for (i in lmsIndices.size - 1 downTo 0) {
        val lmsIndex = lmsIndices[i]
        val key = input[lmsIndex]
        bucketBounds[key] -= 1
        suffixArray[bucketBounds[key]] = lmsIndex
    }

    // Step 2: Scan forward and place L-type suffixes

    // Find the head of each bucket
    bucketBounds[0] = 0
    var sum = 0
    for (i in 0 until buckets.size - 1) {
        sum += buckets[i]
        bucketBounds[i + 1] = sum
    }

    // Deal with the last suffix (sentinel)
    if (slPartition[length - 1] == L_TYPE) {
        val key = input[length - 1]
        suffixArray[bucketBounds[key]] = length - 1
        bucketBounds[key] += 1
    }

    for (i in 0 until length) {
        val suffixIndex = suffixArray[i]
        if (suffixIndex != length && suffixIndex > 0) {
            val prevIndex = suffixIndex - 1
            if (slPartition[prevIndex] == L_TYPE) {
                val key = input[prevIndex]
                suffixArray[bucketBounds[key]] = prevIndex
                bucketBounds[key] += 1
            }
        }
    }

    // Step 3: Scan backward and place S-type suffixes

    // Find the end of each bucket
    partialSum(buckets, bucketBounds)

    for (i in length - 1 downTo 0) {
        val suffixIndex = suffixArray[i]
        if (suffixIndex != length && suffixIndex > 0) {
            val prevIndex = suffixIndex - 1
            if (slPartition[prevIndex] == S_TYPE) {
                val key = input[prevIndex]
                bucketBounds[key] -= 1
                suffixArray[bucketBounds[key]] = prevIndex
            }
        }
    }

    // Deals with the last suffix (sentinel)
    if (slPartition[length - 1] == S_TYPE) {
        val key = input[length - 1]
        bucketBounds[key] -= 1
        suffixArray[bucketBounds[key]] = length - 1
    }
}

/**
 * Partition every suffix based on the SL-type. Return the number of LMS suffixes.
 */
private fun buildSlPartition(input: IntArray): Pair<BitSlice, Int> {
    val length = input.size
    var lmsCount = 0
    val bits = BooleanArray(length)
    var previousType = L_TYPE
    var previousKey = -1

    for (i in length - 1 downTo 0) {
        val currentKey = input[i]

        if (previousKey == -1 || currentKey > previousKey) {
            if (previousType == S_TYPE) {
                lmsCount += 1
            }
            previousType = L_TYPE
        } else if (currentKey < previousKey) {
            previousType = S_TYPE
        }
        bits[i] = previousType
        previousKey = currentKey
    }

    return Pair(BitSlice(bits, 0, length), lmsCount)
}

private fun labelLmsSubstrings(
    input: IntArray,
    slPartition: BitSlice,
    suffixArray: IntArray,
    lmsIndices: IntArray
): Pair<IntArray, Int> {
    val length = input.size
    val lmsStr = IntArray(lmsIndices.size)
    var label = 0
    var previousLms = 0
    var j = 0

    for (idx in 0 until length) {
        val currentLms = suffixArray[idx]
        // Skip sentinel values
        if (currentLms >= length) continue

        if (currentLms > 0
            && slPartition[currentLms] == S_TYPE
            && slPartition[currentLms - 1] == L_TYPE
        ) {
            if (previousLms != 0) {
                var currentLmsType = S_TYPE
                var previousLmsType = S_TYPE
                var k = 0
                while (true) {
                    var currentLmsEnd = false
                    var previousLmsEnd = false

                    if (currentLms + k >= length
                        || (currentLmsType == L_TYPE && slPartition[currentLms + k] == S_TYPE)
                    ) {
                        currentLmsEnd = true
                    }
                    if (previousLms + k >= length
                        || (previousLmsType == L_TYPE && slPartition[previousLms + k] == S_TYPE)
                    ) {
                        previousLmsEnd = true
                    }

                    if (currentLmsEnd && previousLmsEnd) {
                        break
                    }
                    if (currentLmsEnd != previousLmsEnd
                        || input[currentLms + k] != input[previousLms + k]
                    ) {
                        label += 1
                        break
                    }

                    currentLmsType = slPartition[currentLms + k]
                    previousLmsType = slPartition[previousLms + k]
                    k += 1
                }
            }

            lmsIndices[j] = currentLms
            lmsStr[j] = label
            j += 1
            previousLms = currentLms
        }
    }

    return Pair(lmsStr, label + 1)
}

private fun findLmsSuffixes(slPartition: BitSlice, lmsCount: Int): IntArray {
    var previousType = S_TYPE
    val lmsIndices = IntArray(lmsCount)
    var j = 0

    for (i in 0 until slPartition.size) {
        val currentType = slPartition[i]
        if (currentType == S_TYPE && previousType == L_TYPE) {
            lmsIndices[j++] = i
        }
        previousType = currentType
    }

    return lmsIndices
}

private fun makeBucketCount(input: IntArray, keyBound: Int): IntArray {
    val buckets = IntArray(keyBound)
    for (c in input) {
        buckets[c] += 1
    }
    return buckets
}

private fun partialSum(from: IntArray, to: IntArray) {
    var sum = 0
    for (i in from.indices) {
        if (i < to.size) {
            sum += from[i]
            to[i] = sum
        }
    }
}

/**
 * BitSlice class represents a view into a boolean array.
 */
class BitSlice(private val bits: BooleanArray, private val offset: Int, val size: Int) {
    operator fun get(index: Int): Boolean {
        return bits[offset + index]
    }
}
