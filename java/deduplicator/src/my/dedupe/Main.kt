package my.dedupe

import java.time.LocalTime

const val DEBUG = false
const val TRACE = false

private fun log(message: String) {
    if (DEBUG) {
        val time = LocalTime.now().toString()
        System.err.println("$time: $message")
    }
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

    log("Deduplicating document of length ${input.length} with minimum candidate length of $minLength")

    log("Building suffix array")
    val suffixArr = suffixArray(input)
    if (TRACE) {
        log("Suffix array:")
        suffixArr.forEach {
            val s = input.substring(it)
            log("[%3d]:%s".format(it, s))
        }
    }

    log("Building LCP array")
    val lcpArr = lcpArray(input, suffixArr)
    if (TRACE) {
        log("LCP array:")
        for (i in lcpArr.indices) {
            val pos1 = suffixArr[i]
            val pos2 = suffixArr[i + 1]
            val l = lcpArr[i]
            val common = if (l == 0) {
                "(none)"
            } else if (l > 20) {
                input.substring(pos1, pos1 + 20) + "..."
            } else {
                input.substring(pos1, pos1 + l)
            }
            log("comparing suffixes at %3d and %3d - common: %s".format(pos1, pos2, common))
        }
    }

    log("Finding duplicate ranges")
    var rangesToRemove = findDuplicateRanges(suffixArr, minLength, lcpArr)

    log("Consolidating duplicate ranges")
    rangesToRemove = consolidateRanges(rangesToRemove)

    log("Applying removals")
    val result = applyRemovals(input, rangesToRemove)

    log("Deduplication complete. Original length: ${input.length}, new length: ${result.length}")
    println(result)
}

