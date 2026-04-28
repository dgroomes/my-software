package dgroomes.nushell

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * One AST entry returned by `nu --ide-ast`.
 *
 * `nu` reports each token with a `shape` (e.g. `shape_internalcall`, `shape_string`, …) and a
 * `(start, end)` byte span. JVM consumers should translate the spans through [NuOffsets].
 */
data class NuAstEntry(val type: String, val shape: String, val start: Int, val end: Int, val content: String)

/**
 * One inferred-type hint or diagnostic returned by `nu --ide-check`.
 */
data class NuCheckEntry(
    val type: String,
    val severity: String?,
    val typename: String?,
    val message: String?,
    val start: Int,
    val end: Int,
)

/**
 * Result of running a `nu` subcommand for the IDE.
 */
data class NuRunResult(val exitCode: Int, val stdout: String, val stderr: String) {
    val ok: Boolean get() = exitCode == 0
}

/**
 * Client for the IDE-flavored `nu` subcommands: `nu --ide-ast` and `nu --ide-check`.
 *
 * Both commands take a path to a source file and emit JSON on stdout. This client writes the
 * caller's text to a tempfile, invokes `nu`, parses the result with Jackson, and translates
 * Nushell's byte offsets to JVM character offsets.
 *
 * The `nu` executable path is supplied by the caller — usually the result of looking up `nu`
 * on `$PATH` — so this class does not assume any particular install layout.
 */
class NuIde(private val nuExecutable: String, private val timeoutMs: Long = 5_000) {

    private val mapper = ObjectMapper()
    private val ioDrainer = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "nu-ide-io").apply { isDaemon = true }
    }

    /**
     * Runs `nu --ide-ast` against [text] and returns the entries with byte offsets translated
     * to JVM character offsets.
     */
    fun ideAst(text: String): List<NuAstEntry> {
        val result = run(text, listOf("--ide-ast"))
        if (!result.ok || result.stdout.isBlank()) return emptyList()
        val raw = parseAstJson(result.stdout)
        return translateOffsets(text, raw)
    }

    /**
     * Runs `nu --ide-check` against [text] and returns the entries with byte offsets
     * translated to JVM character offsets.
     */
    fun ideCheck(text: String, maxErrors: Int = 100): List<NuCheckEntry> {
        val result = run(text, listOf("--ide-check", maxErrors.toString()))
        if (!result.ok || result.stdout.isBlank()) return emptyList()
        val raw = parseCheckJson(result.stdout)
        return translateCheckOffsets(text, raw)
    }

    private fun parseAstJson(stdout: String): List<NuAstEntry> {
        val root = mapper.readTree(stdout)
        if (!root.isArray) return emptyList()
        return root.mapNotNull { node ->
            val span = node["span"] ?: return@mapNotNull null
            NuAstEntry(
                type = node["type"]?.asText().orEmpty(),
                shape = node["shape"]?.asText().orEmpty(),
                start = span["start"]?.asInt() ?: return@mapNotNull null,
                end = span["end"]?.asInt() ?: return@mapNotNull null,
                content = node["content"]?.asText().orEmpty(),
            )
        }
    }

    private fun parseCheckJson(stdout: String): List<NuCheckEntry> {
        val out = ArrayList<NuCheckEntry>()
        for (line in stdout.lineSequence()) {
            if (line.isBlank()) continue
            val node: JsonNode = mapper.readTree(line)
            // `--ide-check` emits hints with `position` and diagnostics with `span`.
            val pos = node["position"] ?: node["span"] ?: continue
            out += NuCheckEntry(
                type = node["type"]?.asText().orEmpty(),
                severity = node["severity"]?.asText(),
                typename = node["typename"]?.asText(),
                message = node["message"]?.asText(),
                start = pos["start"]?.asInt() ?: continue,
                end = pos["end"]?.asInt() ?: continue,
            )
        }
        return out
    }

    private fun translateOffsets(text: String, entries: List<NuAstEntry>): List<NuAstEntry> {
        if (entries.isEmpty()) return entries
        val needed = HashSet<Int>(entries.size * 2)
        for (e in entries) { needed += e.start; needed += e.end }
        val map = NuOffsets.byteToChar(text, needed)
        return entries.map { e -> e.copy(start = map[e.start] ?: e.start, end = map[e.end] ?: e.end) }
    }

    private fun translateCheckOffsets(text: String, entries: List<NuCheckEntry>): List<NuCheckEntry> {
        if (entries.isEmpty()) return entries
        val needed = HashSet<Int>(entries.size * 2)
        for (e in entries) { needed += e.start; needed += e.end }
        val map = NuOffsets.byteToChar(text, needed)
        return entries.map { e -> e.copy(start = map[e.start] ?: e.start, end = map[e.end] ?: e.end) }
    }

    private fun run(text: String, flags: List<String>): NuRunResult {
        val tmp = Files.createTempFile("nushell-client-", ".nu")
        return try {
            Files.writeString(tmp, text, StandardCharsets.UTF_8)
            val cmd = mutableListOf(nuExecutable)
            cmd.addAll(flags)
            cmd.add(tmp.toString())
            val process = ProcessBuilder(cmd).redirectErrorStream(false).start()
            process.outputStream.close()
            val stdout = ioDrainer.submit(Callable {
                process.inputStream.bufferedReader(StandardCharsets.UTF_8).use { it.readText() }
            })
            val stderr = ioDrainer.submit(Callable {
                process.errorStream.bufferedReader(StandardCharsets.UTF_8).use { it.readText() }
            })
            val finished = process.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
            if (!finished) {
                process.destroyForcibly()
                stdout.cancel(true)
                stderr.cancel(true)
                NuRunResult(-1, "", "Timed out waiting for `nu ${flags.joinToString(" ")}` after ${timeoutMs}ms")
            } else {
                NuRunResult(
                    exitCode = process.exitValue(),
                    stdout = stdout.get(),
                    stderr = stderr.get(),
                )
            }
        } catch (e: Exception) {
            NuRunResult(-1, "", e.message ?: "unknown error")
        } finally {
            try { Files.deleteIfExists(tmp) } catch (_: Exception) {}
        }
    }

    companion object {
        /** Look up `nu` on `$PATH`; returns `null` if not found. */
        fun findNuOnPath(): String? {
            val path = System.getenv("PATH") ?: return null
            for (entry in path.split(File.pathSeparator)) {
                val candidate = File(entry, "nu")
                if (candidate.canExecute()) return candidate.absolutePath
            }
            return null
        }
    }
}
