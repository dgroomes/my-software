package my.dedupe

import org.junit.jupiter.api.Test
import kotlin.random.Random
import kotlin.system.measureNanoTime

/**
 * Performance test demonstrating that SA-IS runs in linear O(n) time.
 *
 * When doubling the input size, execution time should approximately double (not quadruple).
 * A ratio close to 2.0x indicates linear time complexity.
 */
class PerfTest {

    companion object {
        // Test sizes: doubling each time to observe scaling behavior
        private val SIZES = listOf(10_000, 20_000, 40_000, 80_000, 160_000)

        private const val WARMUP_ITERATIONS = 2
        private const val MEASURE_ITERATIONS = 3

        private fun generateRandomString(size: Int, seed: Long = 42): String {
            val random = Random(seed)
            val chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 \n"
            return buildString(size) {
                repeat(size) {
                    append(chars[random.nextInt(chars.length)])
                }
            }
        }

        private fun measureTime(input: String): Double {
            // Warmup
            repeat(WARMUP_ITERATIONS) {
                suffixArray(input)
            }

            // Measure
            var totalNanos = 0L
            repeat(MEASURE_ITERATIONS) {
                totalNanos += measureNanoTime {
                    suffixArray(input)
                }
            }

            return (totalNanos / MEASURE_ITERATIONS) / 1_000_000.0
        }
    }

    @Test
    fun `SA-IS demonstrates linear time scaling`() {
        // Pre-generate all inputs
        val inputs = SIZES.map { size -> generateRandomString(size) }

        // Global warmup
        inputs.forEach { suffixArray(it) }

        println("\n=== SA-IS Linear Time Demonstration ===")
        println("Size      | Time (ms) | Ratio | ns/char | Verdict")
        println("----------|-----------|-------|---------|--------")

        var previousTime = 0.0
        for ((index, size) in SIZES.withIndex()) {
            val input = inputs[index]
            val time = measureTime(input)

            val ratio = if (previousTime > 0) time / previousTime else 0.0
            val ratioStr = if (previousTime > 0) String.format("%.2fx", ratio) else "-"
            val nsPerChar = String.format("%.1f", time * 1_000_000.0 / size)
            val verdict = when {
                previousTime == 0.0 -> "-"
                ratio < 2.5 -> "linear"
                ratio < 3.5 -> "~O(n log n)"
                else -> "super-linear"
            }
            println("${size.toString().padEnd(9)} | ${String.format("%.1f", time).padEnd(9)} | ${ratioStr.padEnd(5)} | ${nsPerChar.padEnd(7)} | $verdict")

            previousTime = time
        }

        println("\nLinear O(n): ratio ≈ 2x when size doubles")
        println("O(n log n):  ratio ≈ 2.2-2.5x when size doubles")
        println("Quadratic:   ratio ≈ 4x when size doubles")
    }

    @Test
    fun `full deduplication pipeline demonstrates linear time`() {
        val inputs = SIZES.map { size -> generateRandomString(size) }

        // Global warmup
        inputs.forEach { deduplicate(10, it) }

        println("\n=== Full Deduplication Pipeline Linear Time ===")
        println("Size      | Time (ms) | Ratio | ns/char")
        println("----------|-----------|-------|--------")

        var previousTime = 0.0
        for ((index, size) in SIZES.withIndex()) {
            val input = inputs[index]

            // Warmup for this size
            repeat(WARMUP_ITERATIONS) { deduplicate(10, input) }

            // Measure
            var totalNanos = 0L
            repeat(MEASURE_ITERATIONS) {
                totalNanos += measureNanoTime {
                    deduplicate(10, input)
                }
            }
            val time = (totalNanos / MEASURE_ITERATIONS) / 1_000_000.0

            val ratioStr = if (previousTime > 0) String.format("%.2fx", time / previousTime) else "-"
            val nsPerChar = String.format("%.1f", time * 1_000_000.0 / size)
            println("${size.toString().padEnd(9)} | ${String.format("%.1f", time).padEnd(9)} | ${ratioStr.padEnd(5)} | $nsPerChar")

            previousTime = time
        }
    }
}
