package dgroomes.nushell_intellij_plugin

import com.intellij.lang.BracePair
import com.intellij.lang.Commenter
import com.intellij.lang.PairedBraceMatcher
import com.intellij.psi.PsiFile
import com.intellij.psi.tree.IElementType

/** Provides the standard `Ctrl+/` line-comment toggle for `.nu` files. */
class NushellCommenter : Commenter {
    override fun getLineCommentPrefix(): String = "#"
    override fun getBlockCommentPrefix(): String? = null
    override fun getBlockCommentSuffix(): String? = null
    override fun getCommentedBlockCommentPrefix(): String? = null
    override fun getCommentedBlockCommentSuffix(): String? = null
}

/** Brace, bracket, and paren pairing for typed-handler highlighting. */
class NushellBraceMatcher : PairedBraceMatcher {
    private val pairs = arrayOf(
        BracePair(NushellTokenTypes.LBRACE, NushellTokenTypes.RBRACE, true),
        BracePair(NushellTokenTypes.LBRACKET, NushellTokenTypes.RBRACKET, false),
        BracePair(NushellTokenTypes.LPAREN, NushellTokenTypes.RPAREN, false),
    )
    override fun getPairs(): Array<BracePair> = pairs
    override fun isPairedBracesAllowedBeforeType(lbraceType: IElementType, contextType: IElementType?): Boolean = true
    override fun getCodeConstructStart(file: PsiFile?, openingBraceOffset: Int): Int = openingBraceOffset
}
