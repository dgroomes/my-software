package my.dedupe

/**
 * Data class that holds all intermediate results from the deduplication process.
 */
@Suppress("ArrayInDataClass")
data class DeduplicationDetails(
    val input: String,
    val minLength: Int,
    val suffixArray: IntArray,
    val lcpArray: IntArray,
    val duplicateRanges: List<IntRange>,
    val consolidatedRanges: List<IntRange>,
    val result: String
)

private const val MAX_WIDTH = 50

/**
 * Pretty prints a suffix array showing each suffix's position and content.
 * @param text The original text
 * @param suffixArray The suffix array to print
 * @return A formatted string representation of the suffix array
 */
fun prettyPrintSuffixArray(text: String, suffixArray: IntArray): String {
    val builder = StringBuilder()
    val posWidth = text.length.toString().length.coerceAtLeast(3)
    val idxWidth = suffixArray.size.toString().length.coerceAtLeast(3)

    builder.appendLine("${"Index".padEnd(idxWidth)} | ${"Pos".padEnd(posWidth)} | Suffix")
    builder.appendLine("-".repeat(idxWidth) + "-+-" + "-".repeat(posWidth) + "-+-" + "-".repeat(MAX_WIDTH))

    for (i in suffixArray.indices) {
        val position = suffixArray[i]
        val suffix = text.substring(position)
        val truncatedSuffix = if (suffix.length > MAX_WIDTH - 3 && suffix.length > 3) {
            suffix.substring(0, MAX_WIDTH - 3) + "..."
        } else {
            suffix
        }

        builder.appendLine("${i.toString().padEnd(idxWidth)} | ${position.toString().padEnd(posWidth)} | $truncatedSuffix")
    }

    return builder.toString()
}

/**
 * Pretty prints an LCP array with the corresponding suffixes.
 * @param text The original text
 * @param suffixArray The suffix array
 * @param lcpArray The LCP array to print
 * @param maxWidth Maximum width for the suffix text (will be truncated if longer)
 * @return A formatted string representation of the LCP array
 */
fun prettyPrintLcpArray(text: String, suffixArray: IntArray, lcpArray: IntArray, maxWidth: Int = MAX_WIDTH): String {
    val builder = StringBuilder()
    val posWidth = text.length.toString().length.coerceAtLeast(3)
    val idxWidth = lcpArray.size.toString().length.coerceAtLeast(3)
    val lcpWidth = lcpArray.maxOrNull()?.toString()?.length?.coerceAtLeast(3) ?: 3

    builder.appendLine("${"Index".padEnd(idxWidth)} | ${"LCP".padEnd(lcpWidth)} | ${"Pos1".padEnd(posWidth)} | ${"Pos2".padEnd(posWidth)} | Common Prefix")
    builder.appendLine("-".repeat(idxWidth) + "-+-" + "-".repeat(lcpWidth) + "-+-" + "-".repeat(posWidth) + "-+-" + "-".repeat(posWidth) + "-+-" + "-".repeat(maxWidth))

    for (i in lcpArray.indices) {
        val lcp = lcpArray[i]
        val pos1 = suffixArray[i]
        val pos2 = suffixArray[i + 1]

        val commonPrefix = if (lcp == 0) {
            "(none)"
        } else {
            val prefix = text.substring(pos1, (pos1 + lcp).coerceAtMost(text.length))
            if (prefix.length > maxWidth - 3 && prefix.length > 3) {
                prefix.substring(0, maxWidth - 3) + "..."
            } else {
                prefix
            }
        }

        builder.appendLine("${i.toString().padEnd(idxWidth)} | ${lcp.toString().padEnd(lcpWidth)} | ${pos1.toString().padEnd(posWidth)} | ${pos2.toString().padEnd(posWidth)} | $commonPrefix")
    }

    return builder.toString()
}

/**
 * Pretty prints ranges that will be removed from the text.
 * @param text The original text
 * @param ranges The ranges to remove
 * @param maxWidth Maximum width for the text content (will be truncated if longer)
 * @return A formatted string representation of the ranges
 */
fun prettyPrintRanges(text: String, ranges: List<IntRange>, maxWidth: Int = MAX_WIDTH): String {
    val builder = StringBuilder()
    val startWidth = text.length.toString().length.coerceAtLeast(5)
    val endWidth = text.length.toString().length.coerceAtLeast(3)
    val lengthWidth = ranges.maxOfOrNull { it.last - it.first + 1 }?.toString()?.length?.coerceAtLeast(3) ?: 3

    builder.appendLine("${"Start".padEnd(startWidth)} | ${"End".padEnd(endWidth)} | ${"Length".padEnd(lengthWidth)} | Content")
    builder.appendLine("-".repeat(startWidth) + "-+-" + "-".repeat(endWidth) + "-+-" + "-".repeat(lengthWidth) + "-+-" + "-".repeat(maxWidth))

    for (range in ranges) {
        val content = text.substring(range)
        val truncatedContent = if (content.length > maxWidth - 3 && content.length > 3) {
            content.substring(0, maxWidth - 3) + "..."
        } else {
            content
        }

        val start = range.first
        val end = range.last
        val length = end - start + 1

        builder.appendLine("${start.toString().padEnd(startWidth)} | ${end.toString().padEnd(endWidth)} | ${length.toString().padEnd(lengthWidth)} | $truncatedContent")
    }

    return builder.toString()
}

/**
 * Pretty prints before and after comparison of the deduplication.
 * @param original The original text
 * @param deduplicated The deduplicated text
 * @param maxWidth Maximum width for the text content
 * @return A formatted string showing the before/after comparison
 */
fun prettyPrintComparison(original: String, deduplicated: String, maxWidth: Int = MAX_WIDTH): String {
    val builder = StringBuilder()
    val originalLines = original.lines()
    val deduplicatedLines = deduplicated.lines()

    builder.appendLine("Before/After Comparison:")
    builder.appendLine("Original Length: ${original.length}, Deduplicated Length: ${deduplicated.length}")
    builder.appendLine("Bytes Removed: ${original.length - deduplicated.length} (${
        String.format("%.2f", (original.length - deduplicated.length).toDouble() / original.length * 100)
    }%)")
    builder.appendLine()

    val maxLineCount = maxOf(originalLines.size, deduplicatedLines.size)
    val lineNumberWidth = maxLineCount.toString().length.coerceAtLeast(3)

    builder.appendLine("${"Line".padEnd(lineNumberWidth)} | Original${" ".repeat(maxWidth - 8)} | Deduplicated")
    builder.appendLine("-".repeat(lineNumberWidth) + "-+-" + "-".repeat(maxWidth) + "-+-" + "-".repeat(maxWidth))

    for (i in 0 until maxLineCount) {
        val originalLine = if (i < originalLines.size) {
            val line = originalLines[i]
            if (line.length > maxWidth - 3 && line.length > 3) {
                line.substring(0, maxWidth - 3) + "..."
            } else {
                line.padEnd(maxWidth)
            }
        } else {
            " ".repeat(maxWidth)
        }

        val deduplicatedLine = if (i < deduplicatedLines.size) {
            val line = deduplicatedLines[i]
            if (line.length > maxWidth - 3 && line.length > 3) {
                line.substring(0, maxWidth - 3) + "..."
            } else {
                line
            }
        } else {
            ""
        }

        builder.appendLine("${(i + 1).toString().padEnd(lineNumberWidth)} | $originalLine | $deduplicatedLine")
    }

    return builder.toString()
}
