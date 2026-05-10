package dgroomes.nushell_intellij_plugin

import com.intellij.lang.ASTNode
import com.intellij.lang.LanguageParserDefinitions
import com.intellij.lang.ParserDefinition
import com.intellij.lang.PsiBuilder
import com.intellij.lang.PsiParser
import com.intellij.lexer.Lexer
import com.intellij.openapi.project.Project
import com.intellij.psi.FileViewProvider
import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import com.intellij.psi.TokenType
import com.intellij.psi.impl.source.tree.LeafPsiElement
import com.intellij.psi.tree.IFileElementType
import com.intellij.psi.tree.TokenSet

/**
 * A "trivial" parser that flattens the entire token stream into the file root.
 *
 * For our purposes we don't need a real Nushell grammar inside IntelliJ — `nu --ide-ast`
 * and `nu --lsp` already provide the canonical AST and language services. The parser exists
 * solely so that:
 *
 *   1. IntelliJ has a [PsiFile] for `.nu` files (required by lots of platform code).
 *   2. There is a [FileViewProvider] and PSI tree that the Structure View / annotators / LSP
 *      glue can attach to.
 *
 * Each lexer token becomes a [LeafPsiElement] under the file root.
 */
class NushellParserDefinition : ParserDefinition {

    override fun createLexer(project: Project?): Lexer = NushellNativeLexer()

    override fun createParser(project: Project?): PsiParser = PsiParser { root, builder -> doParse(root, builder) }

    override fun getFileNodeType(): IFileElementType = NushellTokenTypes.FILE

    override fun getCommentTokens(): TokenSet = COMMENTS

    override fun getStringLiteralElements(): TokenSet = STRINGS

    override fun createElement(node: ASTNode): PsiElement = LeafPsiElement(node.elementType, node.text)

    override fun createFile(viewProvider: FileViewProvider): PsiFile = NushellPsiFile(viewProvider)

    private fun doParse(root: com.intellij.psi.tree.IElementType, builder: PsiBuilder): ASTNode {
        val rootMarker = builder.mark()
        while (!builder.eof()) {
            builder.advanceLexer()
        }
        rootMarker.done(root)
        return builder.treeBuilt
    }

    companion object {
        val COMMENTS: TokenSet = TokenSet.create(NushellTokenTypes.COMMENT)
        val STRINGS: TokenSet = TokenSet.create(
            NushellTokenTypes.STRING_DOUBLE,
            NushellTokenTypes.STRING_SINGLE,
            NushellTokenTypes.STRING_BACKTICK,
        )
        val WHITESPACE: TokenSet = TokenSet.create(TokenType.WHITE_SPACE, NushellTokenTypes.NEWLINE)

        fun forLanguage(): ParserDefinition = LanguageParserDefinitions.INSTANCE.forLanguage(NushellLanguage)
    }
}
