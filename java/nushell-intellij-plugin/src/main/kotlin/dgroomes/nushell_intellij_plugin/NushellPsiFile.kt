package dgroomes.nushell_intellij_plugin

import com.intellij.extapi.psi.PsiFileBase
import com.intellij.openapi.fileTypes.FileType
import com.intellij.psi.FileViewProvider

class NushellPsiFile(viewProvider: FileViewProvider) : PsiFileBase(viewProvider, NushellLanguage) {
    override fun getFileType(): FileType = NushellFileType
    override fun toString(): String = "Nushell File"
}
