// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.lang.Commenter

class CobolCommenter : Commenter {
    override fun getLineCommentPrefix(): String = "*> "
    override fun getBlockCommentPrefix(): String? = null
    override fun getBlockCommentSuffix(): String? = null
    override fun getCommentedBlockCommentPrefix(): String? = null
    override fun getCommentedBlockCommentSuffix(): String? = null
}
