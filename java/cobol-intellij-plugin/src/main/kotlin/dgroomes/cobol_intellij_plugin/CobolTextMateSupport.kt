// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.openapi.diagnostic.logger
import com.intellij.openapi.fileTypes.SyntaxHighlighter
import com.intellij.openapi.fileTypes.SyntaxHighlighterFactory
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.registry.Registry
import com.intellij.openapi.vfs.VirtualFile
import org.jetbrains.plugins.textmate.TextMateService
import org.jetbrains.plugins.textmate.language.TextMateLanguageDescriptor
import org.jetbrains.plugins.textmate.language.syntax.highlighting.TextMateHighlighter
import org.jetbrains.plugins.textmate.language.syntax.lexer.TextMateHighlightingLexer
import java.nio.file.Files
import java.nio.file.Path

/**
 * Colors our claimed COBOL FileType with che4z's TextMate grammar.
 *
 * The stock [org.jetbrains.plugins.textmate.language.syntax.highlighting.TextMateSyntaxHighlighterFactory]
 * looks up `source.cobol` by filename only and returns a plain highlighter when
 * that miss happens — which is the uncolored `.cob` editor. We also try the
 * extension, then any COBOL extension the slim `package.json` declared.
 *
 * The editor highlighter must be TextMate's (not a regular LexerEditorHighlighter)
 * or IntelliJ rejects `source.cobol` as an unregistered token type.
 */
internal object CobolTextMateSupport {

    fun bundleDir(): Path = CobolPlugin.installationDir().resolve("che4z").resolve("textmate")

    fun bundlePresent(): Boolean = Files.isRegularFile(bundleDir().resolve("package.json"))

    fun descriptorFor(file: VirtualFile?): TextMateLanguageDescriptor? {
        val service = TextMateService.getInstance()
        val byName = file?.let { service.getLanguageDescriptorByFileName(it.name) }
        if (byName != null) return byName
        val byExt = file?.extension?.let { service.getLanguageDescriptorByExtension(it) }
        if (byExt != null) return byExt
        for (ext in CobolPlugin.EXTENSIONS) {
            service.getLanguageDescriptorByExtension(ext)?.let { return it }
        }
        return null
    }
}

internal class CobolTextMateHighlighterFactory : SyntaxHighlighterFactory() {
    private val log = logger<CobolTextMateHighlighterFactory>()

    override fun getSyntaxHighlighter(project: Project?, file: VirtualFile?): SyntaxHighlighter {
        val descriptor = CobolTextMateSupport.descriptorFor(file)
        if (descriptor == null) {
            log.warn("No TextMate descriptor for ${file?.name}; COBOL editor will be uncolored")
            return TextMateHighlighter(null)
        }
        val limit = Registry.get("textmate.line.highlighting.limit").asInteger()
        return TextMateHighlighter(TextMateHighlightingLexer(descriptor, limit))
    }
}
