package dgroomes.nushell_intellij_plugin

import com.intellij.openapi.fileTypes.LanguageFileType
import com.intellij.openapi.util.IconLoader
import javax.swing.Icon

object NushellFileType : LanguageFileType(NushellLanguage) {
    val ICON: Icon = IconLoader.getIcon("/icons/nushell.svg", NushellFileType::class.java)
    override fun getName(): String = "Nushell"
    override fun getDescription(): String = "Nushell shell script"
    override fun getDefaultExtension(): String = "nu"
    override fun getIcon(): Icon = ICON
}
