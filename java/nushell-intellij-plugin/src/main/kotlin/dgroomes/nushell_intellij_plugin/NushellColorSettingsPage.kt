package dgroomes.nushell_intellij_plugin

import com.intellij.openapi.fileTypes.SyntaxHighlighter
import com.intellij.openapi.options.colors.AttributesDescriptor
import com.intellij.openapi.options.colors.ColorDescriptor
import com.intellij.openapi.options.colors.ColorSettingsPage
import javax.swing.Icon

/**
 * Adds a "Nushell" entry under Settings → Editor → Color Scheme so users can override the
 * colors we assign to each Nushell shape. The preview snippet uses inline tags that map to
 * [NushellColors] keys via [getAdditionalHighlightingTagToDescriptorMap].
 */
class NushellColorSettingsPage : ColorSettingsPage {

    override fun getDisplayName(): String = "Nushell"
    override fun getIcon(): Icon = NushellFileType.ICON
    override fun getHighlighter(): SyntaxHighlighter = NushellSyntaxHighlighter()

    override fun getAttributeDescriptors(): Array<AttributesDescriptor> = ATTRS
    override fun getColorDescriptors(): Array<ColorDescriptor> = ColorDescriptor.EMPTY_ARRAY

    override fun getAdditionalHighlightingTagToDescriptorMap(): Map<String, com.intellij.openapi.editor.colors.TextAttributesKey> =
        mapOf(
            "kw" to NushellColors.KEYWORD,
            "call" to NushellColors.INTERNAL_CALL,
            "ext" to NushellColors.EXTERNAL_CALL,
            "var" to NushellColors.VARIABLE,
            "vd" to NushellColors.VAR_DECL,
            "fl" to NushellColors.FLAG,
            "sig" to NushellColors.SIGNATURE,
            "op" to NushellColors.OPERATOR,
            "pi" to NushellColors.PIPE,
            "si" to NushellColors.STRING_INTERPOLATION,
        )

    override fun getDemoText(): String = """
        # A Nushell function with a parameter signature
        <kw>def</kw> <call>greet</call> <sig>[name: string, --enthusiastic (-e)]</sig> {
            <kw>let</kw> <vd>punctuation</vd> = <kw>if</kw> <var>${'$'}enthusiastic</var> { "!" } <kw>else</kw> { "." }
            <call>print</call> <si>${'$'}"Hello, (${'$'}name)(${'$'}punctuation)"</si>
        }

        <kw>let</kw> <vd>people</vd> = ["world", "Nushell", "IntelliJ"]
        <call>ls</call> <pi>|</pi> <call>where</call> size <op>></op> 1kb <pi>|</pi> <call>first</call> 5
        <call>greet</call> "world" <fl>--enthusiastic</fl>
    """.trimIndent()

    private companion object {
        val ATTRS = arrayOf(
            AttributesDescriptor("Keyword", NushellColors.KEYWORD),
            AttributesDescriptor("Comment", NushellColors.COMMENT),
            AttributesDescriptor("String", NushellColors.STRING),
            AttributesDescriptor("String interpolation", NushellColors.STRING_INTERPOLATION),
            AttributesDescriptor("Number", NushellColors.NUMBER),
            AttributesDescriptor("Boolean / nothing", NushellColors.BOOL),
            AttributesDescriptor("Operator", NushellColors.OPERATOR),
            AttributesDescriptor("Pipe", NushellColors.PIPE),
            AttributesDescriptor("Semicolon", NushellColors.SEMICOLON),
            AttributesDescriptor("Braces", NushellColors.BRACES),
            AttributesDescriptor("Brackets", NushellColors.BRACKETS),
            AttributesDescriptor("Parentheses", NushellColors.PARENTHESES),
            AttributesDescriptor("Internal command call", NushellColors.INTERNAL_CALL),
            AttributesDescriptor("External command call", NushellColors.EXTERNAL_CALL),
            AttributesDescriptor("Flag", NushellColors.FLAG),
            AttributesDescriptor("Variable", NushellColors.VARIABLE),
            AttributesDescriptor("Variable declaration", NushellColors.VAR_DECL),
            AttributesDescriptor("Signature", NushellColors.SIGNATURE),
            AttributesDescriptor("Match pattern", NushellColors.MATCH_PATTERN),
            AttributesDescriptor("Filepath", NushellColors.FILEPATH),
            AttributesDescriptor("Directory", NushellColors.DIRECTORY),
            AttributesDescriptor("Glob pattern", NushellColors.GLOB_PATTERN),
            AttributesDescriptor("Datetime", NushellColors.DATETIME),
            AttributesDescriptor("Garbage / parse error", NushellColors.GARBAGE),
        )
    }
}
