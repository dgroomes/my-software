// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import org.jetbrains.plugins.textmate.api.TextMateBundleProvider

/**
 * Registers che4z's official TextMate / VS Code grammar bundle (packaged at build time
 * under `che4z/textmate/`) so IntelliJ's TextMate plugin colors `.cbl` / `.cob` / `.cobol`.
 */
internal class CobolTextMateBundleProvider : TextMateBundleProvider {
    override fun getBundles(): List<TextMateBundleProvider.PluginBundle> {
        if (!CobolTextMateSupport.bundlePresent()) return emptyList()
        return listOf(TextMateBundleProvider.PluginBundle("che4z-cobol", CobolTextMateSupport.bundleDir()))
    }
}
