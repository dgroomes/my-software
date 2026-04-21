package dgroomes.nushell_intellij_plugin

import com.intellij.lexer.Lexer
import com.intellij.openapi.editor.DefaultLanguageHighlighterColors
import com.intellij.openapi.editor.colors.TextAttributesKey
import com.intellij.openapi.fileTypes.SyntaxHighlighter
import com.intellij.openapi.fileTypes.SyntaxHighlighterBase
import com.intellij.openapi.fileTypes.SyntaxHighlighterFactory
import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.psi.tree.IElementType

/**
 * Lexer-driven syntax highlighting for the structural pieces of a Nushell file: comments,
 * string literals, and brackets/punctuation.
 *
 * The semantic colors (commands, variables, flags, keywords, …) are layered on top by
 * [NushellSemanticAnnotator], which delegates to `nu --ide-ast`.
 */
class NushellSyntaxHighlighter : SyntaxHighlighterBase() {

    override fun getHighlightingLexer(): Lexer = NushellNativeLexer()

    override fun getTokenHighlights(tokenType: IElementType?): Array<TextAttributesKey> = when (tokenType) {
        NushellTokenTypes.COMMENT -> arrayOf(NushellColors.COMMENT)
        NushellTokenTypes.STRING_DOUBLE,
        NushellTokenTypes.STRING_SINGLE,
        NushellTokenTypes.STRING_BACKTICK -> arrayOf(NushellColors.STRING)
        NushellTokenTypes.LBRACE, NushellTokenTypes.RBRACE -> arrayOf(NushellColors.BRACES)
        NushellTokenTypes.LBRACKET, NushellTokenTypes.RBRACKET -> arrayOf(NushellColors.BRACKETS)
        NushellTokenTypes.LPAREN, NushellTokenTypes.RPAREN -> arrayOf(NushellColors.PARENTHESES)
        NushellTokenTypes.PIPE -> arrayOf(NushellColors.PIPE)
        NushellTokenTypes.SEMI -> arrayOf(NushellColors.SEMICOLON)
        else -> emptyArray()
    }
}

class NushellSyntaxHighlighterFactory : SyntaxHighlighterFactory() {
    override fun getSyntaxHighlighter(project: Project?, virtualFile: VirtualFile?): SyntaxHighlighter =
        NushellSyntaxHighlighter()
}

/**
 * Color keys exposed by this plugin. Users can override colors via
 * Settings → Editor → Color Scheme → Nushell. We map each key to a sensible default from
 * IntelliJ's shared color palette so that out of the box the file looks right under both the
 * default light and dark schemes.
 */
object NushellColors {
    val COMMENT = TextAttributesKey.createTextAttributesKey("NUSHELL_COMMENT", DefaultLanguageHighlighterColors.LINE_COMMENT)
    val STRING = TextAttributesKey.createTextAttributesKey("NUSHELL_STRING", DefaultLanguageHighlighterColors.STRING)
    val STRING_INTERPOLATION = TextAttributesKey.createTextAttributesKey("NUSHELL_STRING_INTERPOLATION", DefaultLanguageHighlighterColors.STRING)
    val NUMBER = TextAttributesKey.createTextAttributesKey("NUSHELL_NUMBER", DefaultLanguageHighlighterColors.NUMBER)
    val BOOL = TextAttributesKey.createTextAttributesKey("NUSHELL_BOOL", DefaultLanguageHighlighterColors.KEYWORD)
    val KEYWORD = TextAttributesKey.createTextAttributesKey("NUSHELL_KEYWORD", DefaultLanguageHighlighterColors.KEYWORD)
    val OPERATOR = TextAttributesKey.createTextAttributesKey("NUSHELL_OPERATOR", DefaultLanguageHighlighterColors.OPERATION_SIGN)
    val PIPE = TextAttributesKey.createTextAttributesKey("NUSHELL_PIPE", DefaultLanguageHighlighterColors.OPERATION_SIGN)
    val SEMICOLON = TextAttributesKey.createTextAttributesKey("NUSHELL_SEMICOLON", DefaultLanguageHighlighterColors.SEMICOLON)
    val BRACES = TextAttributesKey.createTextAttributesKey("NUSHELL_BRACES", DefaultLanguageHighlighterColors.BRACES)
    val BRACKETS = TextAttributesKey.createTextAttributesKey("NUSHELL_BRACKETS", DefaultLanguageHighlighterColors.BRACKETS)
    val PARENTHESES = TextAttributesKey.createTextAttributesKey("NUSHELL_PARENTHESES", DefaultLanguageHighlighterColors.PARENTHESES)

    val INTERNAL_CALL = TextAttributesKey.createTextAttributesKey("NUSHELL_INTERNAL_CALL", DefaultLanguageHighlighterColors.FUNCTION_CALL)
    val EXTERNAL_CALL = TextAttributesKey.createTextAttributesKey("NUSHELL_EXTERNAL_CALL", DefaultLanguageHighlighterColors.FUNCTION_CALL)
    val FLAG = TextAttributesKey.createTextAttributesKey("NUSHELL_FLAG", DefaultLanguageHighlighterColors.METADATA)
    val VARIABLE = TextAttributesKey.createTextAttributesKey("NUSHELL_VARIABLE", DefaultLanguageHighlighterColors.LOCAL_VARIABLE)
    val VAR_DECL = TextAttributesKey.createTextAttributesKey("NUSHELL_VAR_DECL", DefaultLanguageHighlighterColors.LOCAL_VARIABLE)
    val SIGNATURE = TextAttributesKey.createTextAttributesKey("NUSHELL_SIGNATURE", DefaultLanguageHighlighterColors.PARAMETER)
    val MATCH_PATTERN = TextAttributesKey.createTextAttributesKey("NUSHELL_MATCH_PATTERN", DefaultLanguageHighlighterColors.STATIC_FIELD)
    val FILEPATH = TextAttributesKey.createTextAttributesKey("NUSHELL_FILEPATH", DefaultLanguageHighlighterColors.STRING)
    val DIRECTORY = TextAttributesKey.createTextAttributesKey("NUSHELL_DIRECTORY", DefaultLanguageHighlighterColors.STRING)
    val GLOB_PATTERN = TextAttributesKey.createTextAttributesKey("NUSHELL_GLOB_PATTERN", DefaultLanguageHighlighterColors.STRING)
    val DATETIME = TextAttributesKey.createTextAttributesKey("NUSHELL_DATETIME", DefaultLanguageHighlighterColors.NUMBER)
    val GARBAGE = TextAttributesKey.createTextAttributesKey("NUSHELL_GARBAGE", DefaultLanguageHighlighterColors.INVALID_STRING_ESCAPE)
}
