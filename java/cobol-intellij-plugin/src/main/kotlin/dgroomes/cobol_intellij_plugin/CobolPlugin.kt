// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.ide.plugins.PluginManagerCore
import com.intellij.openapi.extensions.PluginId
import com.intellij.openapi.util.IconLoader
import com.intellij.openapi.vfs.VirtualFile
import java.nio.file.Path
import javax.swing.Icon

/** Shared paths and file checks for the locally-built COBOL plugin. */
internal object CobolPlugin {
    const val PLUGIN_ID = "dgroomes.cobolPlugin"
    val ICON: Icon = IconLoader.getIcon("/icons/cobol.svg", CobolPlugin::class.java)

    /** Keep in sync with the `fileType` extensions in plugin.xml and the TextMate `package.json` written by the build. */
    val EXTENSIONS = setOf("cbl", "cob", "cobol", "cpy", "copy")

    fun isCobolFile(file: VirtualFile): Boolean =
        file.extension?.lowercase() in EXTENSIONS

    fun installationDir(): Path {
        val plugin = PluginManagerCore.getPlugin(PluginId.getId(PLUGIN_ID))
            ?: error("COBOL plugin descriptor not found ($PLUGIN_ID)")
        return plugin.pluginPath
    }
}
