package dgroomes.nushell

import java.io.DataInputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/**
 * One token returned by [NuLex.lex]. Spans are **byte offsets** into the source buffer; use
 * [NuOffsets.byteToChar] to translate to character offsets when bridging into a JVM document
 * model.
 */
data class NuLexToken(val kind: NuLexKind, val byteStart: Int, val byteEnd: Int)

/**
 * The lexer token kinds emitted by the `nu-lex` sidecar. Mirrors the `KIND_*` constants at the
 * top of the sidecar's `src/main.rs`. Do not renumber existing entries.
 *
 * [ITEM] is what `nu_parser::lex` calls everything that isn't an operator, pipe, or comment.
 * The remaining `LBRACE`...`STRING_BACKTICK` entries are sub-emissions the sidecar makes when
 * an `Item`'s first byte signals structure — see the comment at the top of `nu-lex/src/main.rs`
 * for why that decision lives in Rust rather than in this client.
 */
enum class NuLexKind {
    ITEM,            // 0
    COMMENT,         // 1
    PIPE,            // 2
    PIPE_PIPE,       // 3
    ASSIGN,          // 4
    REDIRECT,        // 5
    SEMICOLON,       // 6
    EOL,             // 7
    LBRACE,          // 8
    RBRACE,          // 9
    LBRACKET,        // 10
    RBRACKET,        // 11
    LPAREN,          // 12
    RPAREN,          // 13
    STRING_DOUBLE,   // 14
    STRING_SINGLE,   // 15
    STRING_BACKTICK, // 16
}

/**
 * A long-lived client to the `nu-lex` Rust sidecar. The sidecar wraps Nushell's official
 * `nu_parser::lex` and serves tokens over a length-prefixed binary stdio protocol; this client
 * pools a single subprocess and serializes calls through a [ReentrantLock].
 *
 * The path to the sidecar binary is supplied by the caller. Different consumers locate the
 * binary differently (the IntelliJ plugin extracts it from its plugin jar; a standalone JVM
 * client might pass `Paths.get(System.getenv("NU_LEX") ?: "/usr/local/bin/nu-lex")`); this
 * class is intentionally agnostic about that choice.
 *
 * The cost per [lex] call is essentially a stdin write + stdout read; on a small input the
 * round trip stays in the tens-of-microseconds range.
 */
class NuLex(private val binaryPath: Path) : AutoCloseable {

    private val lock = ReentrantLock()

    @Volatile private var process: Process? = null
    @Volatile private var stdinChannel: java.io.OutputStream? = null
    @Volatile private var stdoutChannel: DataInputStream? = null

    /**
     * Tokenize [text] using the upstream `nu_parser::lex`. Returns the raw token list with
     * byte-offset spans.
     *
     * Throws [IOException] if the sidecar could not be started or if it crashed mid-call. The
     * next call after a crash will respawn it.
     */
    fun lex(text: String): List<NuLexToken> = lock.withLock {
        ensureProcess()
        val payload = text.toByteArray(StandardCharsets.UTF_8)
        val out = stdinChannel ?: throw IOException("nu-lex stdin is closed")
        val inp = stdoutChannel ?: throw IOException("nu-lex stdout is closed")
        try {
            val header = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(payload.size).array()
            out.write(header)
            out.write(payload)
            out.flush()
            readReply(inp)
        } catch (e: IOException) {
            kill()
            throw e
        }
    }

    override fun close() {
        lock.withLock { kill() }
    }

    private fun readReply(inp: DataInputStream): List<NuLexToken> {
        val countBuf = ByteArray(4); inp.readFully(countBuf)
        val count = ByteBuffer.wrap(countBuf).order(ByteOrder.LITTLE_ENDIAN).int
        if (count <= 0) return emptyList()
        val records = ByteArray(count * 9)
        inp.readFully(records)
        val list = ArrayList<NuLexToken>(count)
        val bb = ByteBuffer.wrap(records).order(ByteOrder.LITTLE_ENDIAN)
        repeat(count) {
            val kind = bb.get().toInt() and 0xFF
            val start = bb.int
            val end = bb.int
            list += NuLexToken(KINDS[kind], start, end)
        }
        return list
    }

    private fun ensureProcess() {
        val current = process
        if (current != null && current.isAlive) return
        val started = ProcessBuilder(binaryPath.toString()).redirectErrorStream(false).start()
        process = started
        stdinChannel = started.outputStream
        stdoutChannel = DataInputStream(started.inputStream.buffered())
    }

    private fun kill() {
        try { stdinChannel?.close() } catch (_: Exception) {}
        try { stdoutChannel?.close() } catch (_: Exception) {}
        try { process?.destroy() } catch (_: Exception) {}
        process = null
        stdinChannel = null
        stdoutChannel = null
    }

    private companion object {
        val KINDS = NuLexKind.entries.toTypedArray()
    }
}
