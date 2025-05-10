package my.dedupe

import java.io.File
import java.io.FileOutputStream
import java.io.PrintStream
import java.time.LocalTime
import java.time.format.DateTimeFormatter

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

    val debug = System.getenv("DEDUPE_DEBUG") == "TRUE"

    val input = System.`in`.bufferedReader().use { it.readText() }
    val deduped: String
    if (debug) {
        val file = File("dedupe.log")
        System.err.println("Writing debug output to ${file.absolutePath}")
        PrintStream(FileOutputStream(file)).use { ps ->
            deduped = deduplicateDebug(minLength, input, ps).result
        }
    } else {
        deduped = deduplicate(minLength, input)
    }
    println(deduped)
}

/**
 * This is a debug version of the deduplication algorithm that returns all intermediate results and prints progress.
 *
 * This should be used in tests and for debugging.
 */
fun deduplicateDebug(minLength: Int, input: String, ps: PrintStream): DeduplicationDetails {
    val fmt = DateTimeFormatter.ofPattern("HH:mm:ss.SS")

    fun log(message: String) {
        val time = LocalTime.now().format(fmt)
        ps.println("$time: $message")
    }

    log("Deduplicating document of length ${input.length} with minimum candidate length of $minLength.")
    log("Input: $input")

    val suffixArr = suffixArray(input)
    log("Suffix Array:")
    ps.println(prettyPrintSuffixArray(input, suffixArr))

    val lcpArr = lcpArray(input, suffixArr)
    log("LCP array")
    ps.println(prettyPrintLcpArray(input, suffixArr, lcpArr))

    val rangesToRemove = findDuplicateRanges(suffixArr, minLength, lcpArr)
    log("Duplicate ranges:")
    ps.println(prettyPrintRanges(input, rangesToRemove))

    val consolidatedRanges = consolidateRanges(rangesToRemove)
    log("Consolidated duplicate ranges:")
    ps.println(prettyPrintRanges(input, consolidatedRanges))

    val result = applyRemovals(input, consolidatedRanges)

    log("Deduplication complete")
    ps.println(prettyPrintComparison(input, result))

    return DeduplicationDetails(
        input = input,
        minLength = minLength,
        suffixArray = suffixArr,
        lcpArray = lcpArr,
        duplicateRanges = rangesToRemove,
        consolidatedRanges = consolidatedRanges,
        result = result
    )
}
