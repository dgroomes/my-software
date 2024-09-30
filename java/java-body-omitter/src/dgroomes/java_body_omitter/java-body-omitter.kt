package dgroomes.java_body_omitter

/**
 * Please see the README for more information.
 */
fun main() {
    val code = System.`in`.bufferedReader().use { it.readText() }
    val stripped = JavaBodyOmitter().strip(code)
    println(stripped)
}
