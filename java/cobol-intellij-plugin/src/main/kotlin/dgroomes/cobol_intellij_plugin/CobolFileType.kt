// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.openapi.fileTypes.LanguageFileType
import javax.swing.Icon

object CobolFileType : LanguageFileType(CobolLanguage) {
    override fun getName(): String = "COBOL"
    override fun getDescription(): String = "COBOL source (che4z TextMate + LSP)"
    override fun getDefaultExtension(): String = "cbl"
    override fun getIcon(): Icon = CobolPlugin.ICON
}
