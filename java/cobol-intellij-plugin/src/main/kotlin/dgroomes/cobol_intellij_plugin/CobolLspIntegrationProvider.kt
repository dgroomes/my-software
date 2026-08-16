// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.execution.configurations.GeneralCommandLine
import com.intellij.openapi.application.runReadActionBlocking
import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.project.Project
import com.intellij.openapi.project.guessProjectDir
import com.intellij.openapi.vfs.VfsUtilCore
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.openapi.vfs.VirtualFileManager
import com.intellij.platform.lsp.api.Lsp4jClient
import com.intellij.platform.lsp.api.LspClient
import com.intellij.platform.lsp.api.LspIntegrationProvider
import com.intellij.platform.lsp.api.LspServerNotificationsHandler
import com.intellij.platform.lsp.api.ProjectWideLspClientDescriptor
import com.intellij.platform.lsp.api.lsWidget.LspClientWidgetItem
import org.eclipse.lsp4j.ConfigurationItem
import org.eclipse.lsp4j.jsonrpc.services.JsonRequest
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CompletableFuture

/**
 * Starts the che4z COBOL language server (`java -jar server.jar`) for COBOL files.
 * Matches the VS Code extension's JAVA runtime path (stdio / pipeEnabled).
 */
internal class CobolLspIntegrationProvider : LspIntegrationProvider {

    override fun fileOpened(
        project: Project,
        file: VirtualFile,
        clientStarter: LspIntegrationProvider.LspClientStarter,
    ) {
        if (!CobolPlugin.isCobolFile(file)) return
        clientStarter.ensureClientStarted(CobolLspClientDescriptor(project))
    }

    override fun createWidgetItem(lspClient: LspClient, currentFile: VirtualFile?): LspClientWidgetItem =
        LspClientWidgetItem(lspClient, currentFile, CobolPlugin.ICON, settingsPageClass = null)
}

private class CobolLspClientDescriptor(project: Project) : ProjectWideLspClientDescriptor(project, "COBOL") {
    private val log = logger<CobolLspClientDescriptor>()

    override fun isSupportedFile(file: VirtualFile): Boolean =
        CobolPlugin.isCobolFile(file)

    /** che4z maps language ids via CobolLanguageId.MAPPER; it expects `cobol`, not the file extension. */
    override fun getLanguageId(file: VirtualFile): String = "cobol"

    override fun createLsp4jClient(handler: LspServerNotificationsHandler): Lsp4jClient =
        CobolLsp4jClient(handler, project)

    /**
     * Minimal defaults for che4z `workspace/configuration` sections
     * (`cobol-lsp.<label>` from SettingsParametersEnum).
     *
     * Copybook search mirrors the VS Code extension defaults for extensions and uses a
     * small set of relative folders under each project root (che4z itself does not search
     * the disk — the client resolves `copybook/resolve`).
     */
    override fun getWorkspaceConfiguration(item: ConfigurationItem): Any? =
        when (item.section) {
            "cobol-lsp.dialects" -> emptyList<String>()
            "cobol-lsp.subroutine-manager.paths-local" -> emptyList<String>()
            "cobol-lsp.cpy-manager.paths-local" -> COPYBOOK_LOCAL_PATHS
            "cobol-lsp.cpy-manager.copybook-extensions" -> COPYBOOK_EXTENSIONS
            "cobol-lsp.cics.translator" -> true
            "cobol-lsp.target-sql-backend-enable-processing" -> true
            "cobol-lsp.target-sql-backend" -> "NONE"
            "cobol-lsp.sql-decimal-comma-allowed" -> false
            "cobol-lsp.compiler.options" -> emptyList<String>()
            "cobol-lsp.unused-variable-severity" -> "NONE"
            else -> null
        }

    override fun createCommandLine(): GeneralCommandLine {
        val jar = serverJar()
        val java = findJavaExecutable()
        log.info("Starting che4z COBOL LSP: $java -jar $jar")
        return GeneralCommandLine(
            java,
            "-Dline.separator=\r\n",
            "-Xmx768M",
            "-jar",
            jar.toAbsolutePath().toString(),
            "pipeEnabled",
        )
    }

    /** The build places che4z's `server.jar` in the plugin distribution, next to `lib/`. */
    private fun serverJar(): Path {
        val jar = CobolPlugin.installationDir().resolve("che4z").resolve("server.jar")
        check(Files.isRegularFile(jar)) {
            "che4z server.jar missing at $jar. It is bundled at build time; rebuild with :cobol-intellij-plugin:buildPlugin."
        }
        return jar
    }

    private fun findJavaExecutable(): String {
        val javaHome = System.getProperty("java.home")
        if (!javaHome.isNullOrBlank()) {
            val java = Path.of(javaHome, "bin", "java")
            if (Files.isRegularFile(java)) return java.toAbsolutePath().toString()
        }
        return "java"
    }

    companion object {
        /** Relative to each project root; same idea as VS Code `cobol-lsp.cpy-manager.paths-local`. */
        val COPYBOOK_LOCAL_PATHS: List<String> = listOf(".", "copybooks", "cpy", "copy")

        /** Same default list as the che4z VS Code package.json. */
        val COPYBOOK_EXTENSIONS: List<String> =
            listOf(".CPY", ".COPY", ".cpy", ".copy", "")
    }
}

/**
 * che4z extends LSP with client requests (see CobolLanguageClient). The IntelliJ default
 * Lsp4jClient does not implement them; without these stubs analysis / copybook expansion
 * aborts or silently skips COPY members.
 */
private class CobolLsp4jClient(
    handler: LspServerNotificationsHandler,
    private val project: Project,
) : Lsp4jClient(handler) {
    private val log = logger<CobolLsp4jClient>()

    @JsonRequest("availableDialects")
    fun availableDialects(): CompletableFuture<List<Any>> =
        CompletableFuture.completedFuture(emptyList())

    /**
     * VS Code registers this as `copybook/resolve`. Parameters are the open program URI,
     * the COPY name, and the dialect type (e.g. `COBOL`).
     */
    @JsonRequest("copybook/resolve")
    fun resolveCopybookUri(
        cobolFileUri: String,
        copybookName: String,
        @Suppress("UNUSED_PARAMETER") dialectType: String,
    ): CompletableFuture<String?> =
        CompletableFuture.supplyAsync {
            try {
                CobolCopybookResolver.resolve(project, cobolFileUri, copybookName)
            } catch (t: Throwable) {
                log.warn("copybook/resolve failed for $copybookName from $cobolFileUri", t)
                null
            }
        }

    /** VS Code registers this as `file/content`. che4z uses the client to read copybook text. */
    @JsonRequest("file/content")
    fun getFileContent(uri: String): CompletableFuture<String?> =
        CompletableFuture.supplyAsync {
            try {
                CobolCopybookResolver.readContent(uri)
            } catch (t: Throwable) {
                log.warn("file/content failed for $uri", t)
                null
            }
        }
}

/**
 * Local-folder copybook lookup modeled on che4z's VS Code client:
 * search each configured relative folder under the project root (and the program's
 * directory) for a file whose basename matches the COPY name (case-insensitive) and
 * whose extension is in the allowed list.
 */
internal object CobolCopybookResolver {
    private val log = logger<CobolCopybookResolver>()

    fun resolve(project: Project, cobolFileUri: String, copybookName: String): String? {
        val needle = copybookName.uppercase()
        val extensions = CobolLspClientDescriptor.COPYBOOK_EXTENSIONS
            .map { normalizeExtension(it) }
            .toSet()

        return runReadActionBlocking {
            for (dir in searchDirectories(project, cobolFileUri)) {
                for (child in dir.children.orEmpty()) {
                    if (child.isDirectory) continue
                    val (base, ext) = splitName(child.name)
                    if (base.uppercase() != needle) continue
                    if (normalizeExtension(ext) !in extensions) continue
                    log.info("Resolved copybook $copybookName -> ${child.url}")
                    return@runReadActionBlocking child.url
                }
            }
            log.info("Unable to resolve copybook $copybookName (program=$cobolFileUri)")
            null
        }
    }

    fun readContent(uri: String): String? =
        runReadActionBlocking {
            val file = VirtualFileManager.getInstance().findFileByUrl(uri) ?: return@runReadActionBlocking null
            VfsUtilCore.loadText(file)
        }

    private fun searchDirectories(project: Project, cobolFileUri: String): List<VirtualFile> {
        val dirs = LinkedHashSet<VirtualFile>()
        val roots = mutableListOf<VirtualFile>()
        project.guessProjectDir()?.let(roots::add)
        VirtualFileManager.getInstance().findFileByUrl(cobolFileUri)?.parent?.let(roots::add)

        for (root in roots) {
            for (relative in CobolLspClientDescriptor.COPYBOOK_LOCAL_PATHS) {
                val dir = if (relative == "." || relative.isEmpty()) {
                    root
                } else {
                    root.findFileByRelativePath(relative)
                }
                if (dir != null && dir.isDirectory) dirs.add(dir)
            }
        }
        return dirs.toList()
    }

    /** Match che4z's `p3`: ensure a leading dot (unless empty) and uppercase. */
    private fun normalizeExtension(extension: String): String =
        when {
            extension.isEmpty() -> ""
            extension.startsWith(".") -> extension.uppercase()
            else -> ".${extension.uppercase()}"
        }

    private fun splitName(filename: String): Pair<String, String> {
        val dot = filename.lastIndexOf('.')
        return if (dot > 0) {
            filename.substring(0, dot) to filename.substring(dot)
        } else {
            filename to ""
        }
    }
}
