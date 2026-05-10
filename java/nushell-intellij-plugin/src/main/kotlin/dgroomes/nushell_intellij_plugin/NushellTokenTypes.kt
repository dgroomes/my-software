package dgroomes.nushell_intellij_plugin

import com.intellij.psi.tree.IElementType
import com.intellij.psi.tree.IFileElementType

/**
 * Token types emitted by [NushellNativeLexer]. We intentionally keep this set very small.
 *
 * Nushell's grammar is ambient and contextual (the meaning of a bare word depends on whether
 * it's a known command, a flag value, a path, …). Re-implementing that in IntelliJ would mean
 * drifting from `nu` itself. The lexer pipeline therefore emits only the *structural* tokens
 * that IntelliJ's editor services need (comments, strings, brackets, pipe/semi, whitespace,
 * and a generic "word" bucket for everything else), and lets `nu --ide-ast` be the source of
 * truth for everything semantic.
 */
class NushellTokenType(debugName: String) : IElementType(debugName, NushellLanguage)

object NushellTokenTypes {
    val FILE: IFileElementType = IFileElementType(NushellLanguage)

    val COMMENT = NushellTokenType("COMMENT")
    val STRING_DOUBLE = NushellTokenType("STRING_DOUBLE")
    val STRING_SINGLE = NushellTokenType("STRING_SINGLE")
    val STRING_BACKTICK = NushellTokenType("STRING_BACKTICK")

    val LBRACE = NushellTokenType("LBRACE")
    val RBRACE = NushellTokenType("RBRACE")
    val LBRACKET = NushellTokenType("LBRACKET")
    val RBRACKET = NushellTokenType("RBRACKET")
    val LPAREN = NushellTokenType("LPAREN")
    val RPAREN = NushellTokenType("RPAREN")

    val PIPE = NushellTokenType("PIPE")
    val SEMI = NushellTokenType("SEMI")

    val WORD = NushellTokenType("WORD")
    val OTHER = NushellTokenType("OTHER")
    val NEWLINE = NushellTokenType("NEWLINE")
}
