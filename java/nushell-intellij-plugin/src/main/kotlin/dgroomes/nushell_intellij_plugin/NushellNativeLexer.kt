package dgroomes.nushell_intellij_plugin

import com.intellij.lexer.LexerBase
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.diagnostic.logger
import com.intellij.psi.TokenType
import com.intellij.psi.tree.IElementType
import dgroomes.nushell.NuLex
import dgroomes.nushell.NuLexKind
import dgroomes.nushell.NuLexToken
import dgroomes.nushell.NuOffsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * The IntelliJ-side lexer for Nushell.
 *
 * This class deliberately contains **no** Nushell-grammar logic of its own. Every tokenization
 * decision happens in the `nu-lex` sidecar (which itself wraps Nushell's official
 * `nu_parser::lex`). The sidecar even handles the bracket / quote sub-emissions that IntelliJ's
 * brace matcher and string services need — see the comment at the top of `nu-lex/src/main.rs`.
 *
 * What this class *does* do:
 *   1. Forward the buffer to the sidecar via [NushellLexService].
 *   2. Translate the byte-offset spans the sidecar returns into character offsets, since
 *      IntelliJ's PSI is character-indexed and Nushell sources contain multi-byte UTF-8.
 *   3. Map each [NuLexKind] to an [IElementType] via a lookup table.
 *   4. Synthesize whitespace tokens for the gaps between adjacent sidecar tokens, since
 *      `nu_parser::lex` doesn't emit whitespace and IntelliJ's PSI requires it.
 */
class NushellNativeLexer : LexerBase() {

    private var buffer: CharSequence = ""
    private var startOffset: Int = 0
    private var endOffset: Int = 0
    private var tokens: List<Token> = emptyList()
    private var index: Int = 0

    private data class Token(val type: IElementType, val start: Int, val end: Int)

    override fun start(buffer: CharSequence, startOffset: Int, endOffset: Int, initialState: Int) {
        this.buffer = buffer
        this.startOffset = startOffset
        this.endOffset = endOffset
        this.index = 0

        val text = buffer.subSequence(startOffset, endOffset).toString()
        this.tokens = if (text.isEmpty()) emptyList() else tokenize(text, startOffset)
    }

    override fun getState(): Int = 0
    override fun getTokenStart(): Int = if (index < tokens.size) tokens[index].start else endOffset
    override fun getTokenEnd(): Int = if (index < tokens.size) tokens[index].end else endOffset
    override fun getTokenType(): IElementType? = if (index < tokens.size) tokens[index].type else null
    override fun getBufferSequence(): CharSequence = buffer
    override fun getBufferEnd(): Int = endOffset
    override fun advance() { if (index < tokens.size) index++ }

    private fun tokenize(text: String, startOffset: Int): List<Token> {
        val raw: List<NuLexToken> = NushellLexService.getInstance().lex(text)

        val needed = HashSet<Int>(raw.size * 2)
        for (t in raw) { needed += t.byteStart; needed += t.byteEnd }
        val byteToChar = NuOffsets.byteToChar(text, needed)

        val out = ArrayList<Token>(raw.size + 4)
        var prevCharEnd = 0
        for (token in raw) {
            val charStart = byteToChar[token.byteStart] ?: continue
            val charEnd = byteToChar[token.byteEnd] ?: continue
            if (charStart > prevCharEnd) emitWhitespace(text, prevCharEnd, charStart, startOffset, out)
            val type = ELEMENT_TYPES[token.kind] ?: continue
            out += Token(type, startOffset + charStart, startOffset + charEnd)
            prevCharEnd = charEnd
        }
        if (prevCharEnd < text.length) emitWhitespace(text, prevCharEnd, text.length, startOffset, out)
        return out
    }

    private fun emitWhitespace(text: String, fromChar: Int, toChar: Int, baseOffset: Int, out: MutableList<Token>) {
        var i = fromChar
        while (i < toChar) {
            val c = text[i]
            if (c == '\n') {
                out += Token(NushellTokenTypes.NEWLINE, baseOffset + i, baseOffset + i + 1)
                i++
            } else {
                var j = i
                while (j < toChar && text[j] != '\n') j++
                out += Token(TokenType.WHITE_SPACE, baseOffset + i, baseOffset + j)
                i = j
            }
        }
    }

    companion object {
        @Suppress("unused")
        private val log = logger<NushellNativeLexer>()

        // Pure dispatch table from sidecar wire kinds to IntelliJ token types. Every
        // tokenization decision worth making was already made in the sidecar.
        private val ELEMENT_TYPES: Map<NuLexKind, IElementType> = mapOf(
            NuLexKind.ITEM             to NushellTokenTypes.WORD,
            NuLexKind.COMMENT          to NushellTokenTypes.COMMENT,
            NuLexKind.PIPE             to NushellTokenTypes.PIPE,
            NuLexKind.PIPE_PIPE        to NushellTokenTypes.PIPE,
            NuLexKind.ASSIGN           to NushellTokenTypes.OTHER,
            NuLexKind.REDIRECT         to NushellTokenTypes.OTHER,
            NuLexKind.SEMICOLON        to NushellTokenTypes.SEMI,
            NuLexKind.EOL              to NushellTokenTypes.NEWLINE,
            NuLexKind.LBRACE           to NushellTokenTypes.LBRACE,
            NuLexKind.RBRACE           to NushellTokenTypes.RBRACE,
            NuLexKind.LBRACKET         to NushellTokenTypes.LBRACKET,
            NuLexKind.RBRACKET         to NushellTokenTypes.RBRACKET,
            NuLexKind.LPAREN           to NushellTokenTypes.LPAREN,
            NuLexKind.RPAREN           to NushellTokenTypes.RPAREN,
            NuLexKind.STRING_DOUBLE    to NushellTokenTypes.STRING_DOUBLE,
            NuLexKind.STRING_SINGLE    to NushellTokenTypes.STRING_SINGLE,
            NuLexKind.STRING_BACKTICK  to NushellTokenTypes.STRING_BACKTICK,
        )
    }
}

/**
 * Application-singleton that owns the long-lived [NuLex] client.
 *
 * The plugin ships the sidecar binary at `native/nu-lex` inside its own jar; on first use we
 * extract it to the IDE's system path manager directory (so it has the executable bit) and
 * hand the path to a single shared [NuLex] instance for the lifetime of the IDE.
 */
internal object NushellLexService {

    @Volatile private var client: NuLex? = null
    private val lock = Any()

    fun getInstance(): NuLex {
        client?.let { return it }
        synchronized(lock) {
            client?.let { return it }
            val path = extractBinary()
            val fresh = NuLex(path)
            client = fresh
            return fresh
        }
    }

    private fun extractBinary(): Path {
        val resourcePath = "native/nu-lex"
        val targetDir = PathManager.getSystemDir().resolve("nushell-plugin").resolve("native")
        Files.createDirectories(targetDir)
        val target = targetDir.resolve("nu-lex")
        val cls = NushellLexService::class.java
        cls.classLoader.getResourceAsStream(resourcePath).use { stream ->
            checkNotNull(stream) {
                "nu-lex sidecar binary missing from plugin classpath at '$resourcePath'. " +
                "Rebuild with `./gradlew :nushell-intellij-plugin:buildPlugin` after building " +
                "the rust/nu-lex sidecar."
            }
            Files.copy(stream, target, StandardCopyOption.REPLACE_EXISTING)
        }
        target.toFile().setExecutable(true)
        return target
    }
}
