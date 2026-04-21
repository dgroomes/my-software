package dgroomes.nushell_intellij_plugin

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.Project
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.platform.lsp.api.LspServer
import com.intellij.platform.lsp.api.LspServerSupportProvider
import com.intellij.platform.lsp.api.ProjectWideLspServerDescriptor
import com.intellij.platform.lsp.api.lsWidget.LspServerWidgetItem
import dgroomes.nushell.NuIde

/**
 * Spawns Nushell's official `nu --lsp` language server for `.nu` files. This is what powers
 * hover, completion, go-to-definition, find usages, and diagnostics in this plugin — i.e.
 * every "smart" feature that requires real Nushell name resolution. We do not duplicate any
 * of those features in IntelliJ-side Kotlin.
 */
internal class NushellLspServerSupportProvider : LspServerSupportProvider {

    override fun fileOpened(
        project: Project,
        file: VirtualFile,
        serverStarter: LspServerSupportProvider.LspServerStarter,
    ) {
        if (file.fileType !is NushellFileType && file.extension != "nu") return
        if (NuIde.findNuOnPath() == null) {
            log.warn("`nu` executable not found on PATH; skipping Nushell LSP server start.")
            return
        }
        serverStarter.ensureServerStarted(NushellLspServerDescriptor(project))
    }

    override fun createLspServerWidgetItem(lspServer: LspServer, currentFile: VirtualFile?): LspServerWidgetItem =
        LspServerWidgetItem(lspServer, currentFile, NushellFileType.ICON, settingsPageClass = null)

    companion object {
        private val log = logger<NushellLspServerSupportProvider>()
    }
}

private class NushellLspServerDescriptor(project: Project) : ProjectWideLspServerDescriptor(project, "Nushell") {

    override fun isSupportedFile(file: VirtualFile): Boolean =
        file.fileType is NushellFileType || file.extension == "nu"

    override fun createCommandLine(): GeneralCommandLine {
        val nu = NuIde.findNuOnPath() ?: error("Could not find the `nu` executable on PATH.")
        return GeneralCommandLine(nu, "--lsp")
    }
}
