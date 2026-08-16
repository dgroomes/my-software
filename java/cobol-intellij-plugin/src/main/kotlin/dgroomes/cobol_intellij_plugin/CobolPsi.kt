// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.extapi.psi.PsiFileBase
import com.intellij.lang.ASTNode
import com.intellij.lang.ParserDefinition
import com.intellij.lang.PsiBuilder
import com.intellij.lang.PsiParser
import com.intellij.lexer.EmptyLexer
import com.intellij.lexer.Lexer
import com.intellij.openapi.fileTypes.FileType
import com.intellij.openapi.project.Project
import com.intellij.psi.FileViewProvider
import com.intellij.psi.PsiElement
import com.intellij.psi.PsiFile
import com.intellij.psi.impl.source.tree.LeafPsiElement
import com.intellij.psi.tree.IElementType
import com.intellij.psi.tree.IFileElementType
import com.intellij.psi.tree.TokenSet

/**
 * PSI scaffold only. [EmptyLexer] is the same minimal token stream TextMate uses for its
 * own parser definition. We author no COBOL grammar: TextMate colors the editor and
 * che4z LSP owns analysis.
 */
class CobolParserDefinition : ParserDefinition {
    override fun createLexer(project: Project?): Lexer = EmptyLexer()

    override fun createParser(project: Project?): PsiParser =
        PsiParser { root, builder -> parseFlat(root, builder) }

    override fun getFileNodeType(): IFileElementType = CobolElementTypes.FILE
    override fun getCommentTokens(): TokenSet = TokenSet.EMPTY
    override fun getStringLiteralElements(): TokenSet = TokenSet.EMPTY

    override fun createElement(node: ASTNode): PsiElement =
        LeafPsiElement(node.elementType, node.text)

    override fun createFile(viewProvider: FileViewProvider): PsiFile =
        CobolPsiFile(viewProvider)

    private fun parseFlat(root: IElementType, builder: PsiBuilder): ASTNode {
        val marker = builder.mark()
        while (!builder.eof()) builder.advanceLexer()
        marker.done(root)
        return builder.treeBuilt
    }
}

private object CobolElementTypes {
    val FILE = IFileElementType(CobolLanguage)
}

class CobolPsiFile(viewProvider: FileViewProvider) :
    PsiFileBase(viewProvider, CobolLanguage) {
    override fun getFileType(): FileType = CobolFileType
    override fun toString(): String = "COBOL File"
}
