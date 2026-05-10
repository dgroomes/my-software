package dgroomes.nushell_intellij_plugin

import com.intellij.icons.AllIcons
import com.intellij.ide.structureView.StructureViewBuilder
import com.intellij.ide.structureView.StructureViewModel
import com.intellij.ide.structureView.StructureViewModelBase
import com.intellij.ide.structureView.StructureViewTreeElement
import com.intellij.ide.structureView.TreeBasedStructureViewBuilder
import com.intellij.ide.util.treeView.smartTree.SortableTreeElement
import com.intellij.ide.util.treeView.smartTree.Sorter
import com.intellij.lang.PsiStructureViewFactory
import com.intellij.navigation.ItemPresentation
import com.intellij.openapi.editor.Editor
import com.intellij.openapi.fileEditor.OpenFileDescriptor
import com.intellij.pom.Navigatable
import com.intellij.psi.PsiFile
import dgroomes.nushell.NuAstEntry
import javax.swing.Icon

/**
 * Structure View for Nushell files. The set of declarations shown comes directly from
 * `nu --ide-ast` so the outline matches Nushell's own understanding of the file.
 *
 * We look for top-level "introducer" tokens (`def`, `def --env`, `extern`, `alias`,
 * `module`, `use`, `let`, `mut`, `const`, `export def`, …) and take the next significant
 * token after each as the symbol's name.
 */
class NushellStructureViewFactory : PsiStructureViewFactory {
    override fun getStructureViewBuilder(psiFile: PsiFile): StructureViewBuilder? {
        if (psiFile !is NushellPsiFile) return null
        return object : TreeBasedStructureViewBuilder() {
            override fun createStructureViewModel(editor: Editor?): StructureViewModel =
                NushellStructureViewModel(editor, psiFile)
        }
    }
}

private class NushellStructureViewModel(editor: Editor?, file: PsiFile) :
    StructureViewModelBase(file, editor, NushellFileStructureElement(file)),
    StructureViewModel.ElementInfoProvider {

    init {
        withSorters(Sorter.ALPHA_SORTER)
    }

    override fun isAlwaysShowsPlus(element: StructureViewTreeElement): Boolean = false
    override fun isAlwaysLeaf(element: StructureViewTreeElement): Boolean = element is NushellSymbolElement
    override fun getSuitableClasses(): Array<Class<*>> = arrayOf(NushellPsiFile::class.java)
}

private class NushellFileStructureElement(private val file: PsiFile) : StructureViewTreeElement, SortableTreeElement {
    override fun getValue(): Any = file
    override fun navigate(requestFocus: Boolean) { (file as? Navigatable)?.navigate(requestFocus) }
    override fun canNavigate(): Boolean = (file as? Navigatable)?.canNavigate() ?: false
    override fun canNavigateToSource(): Boolean = (file as? Navigatable)?.canNavigateToSource() ?: false
    override fun getAlphaSortKey(): String = file.name
    override fun getPresentation(): ItemPresentation = NushellPresentation(file.name, AllIcons.FileTypes.Custom)

    override fun getChildren(): Array<StructureViewTreeElement> {
        // We can't shell out to `nu` here because getChildren is invoked under a read action
        // and OSProcessHandler refuses to block in that context. Instead we read the most
        // recent cache entry produced by NushellSemanticAnnotator. If nothing has been
        // computed yet we return an empty array; the next typing event will trigger the
        // annotator, which will populate the cache, and the structure view will refresh.
        val virtualFile = file.virtualFile ?: return emptyArray()
        val entries = NushellAstCache.getInstance().get(virtualFile) ?: return emptyArray()
        val symbols = NushellOutline.fromAst(entries)
        return symbols.map { NushellSymbolElement(file, it) }.toTypedArray()
    }
}

/** A single declaration shown in the structure view. */
internal data class NushellOutlineSymbol(
    val name: String,
    val kind: SymbolKind,
    val nameStart: Int,
    val nameEnd: Int,
    val signature: String?,
)

internal enum class SymbolKind(val display: String, val icon: Icon) {
    Def("def", AllIcons.Nodes.Function),
    DefEnv("def --env", AllIcons.Nodes.Function),
    Extern("extern", AllIcons.Nodes.AbstractMethod),
    Alias("alias", AllIcons.Nodes.AnonymousClass),
    Module("module", AllIcons.Nodes.Package),
    Use("use", AllIcons.Nodes.PpJar),
    Export("export", AllIcons.Nodes.Plugin),
    Let("let", AllIcons.Nodes.Variable),
    Mut("mut", AllIcons.Nodes.Variable),
    Const("const", AllIcons.Nodes.Constant),
}

private class NushellSymbolElement(
    private val file: PsiFile,
    private val symbol: NushellOutlineSymbol,
) : StructureViewTreeElement, SortableTreeElement {

    override fun getValue(): Any = symbol
    override fun getChildren(): Array<StructureViewTreeElement> = emptyArray()

    override fun getAlphaSortKey(): String = symbol.name

    override fun getPresentation(): ItemPresentation =
        NushellPresentation(symbol.name, symbol.signature ?: symbol.kind.display, symbol.kind.icon)

    override fun navigate(requestFocus: Boolean) {
        val virtualFile = file.virtualFile ?: return
        OpenFileDescriptor(file.project, virtualFile, symbol.nameStart).navigate(requestFocus)
    }

    override fun canNavigate(): Boolean = file.virtualFile != null
    override fun canNavigateToSource(): Boolean = canNavigate()
}

private class NushellPresentation(
    private val text: String,
    private val location: String? = null,
    private val icon: Icon? = null,
) : ItemPresentation {
    constructor(text: String, icon: Icon) : this(text, null, icon)
    override fun getPresentableText(): String = text
    override fun getLocationString(): String? = location
    override fun getIcon(unused: Boolean): Icon? = icon
}

/**
 * Computes a list of top-level declarations from `nu --ide-ast` output for [text].
 *
 * The strategy: walk the AST entries left-to-right. When we see a `shape_internalcall` or
 * `shape_keyword` whose text matches a known introducer (e.g. `def`, `extern`, `alias`,
 * `let`, `mut`, `const`, `module`, `use`, `export`), take the next non-trivial entry as the
 * symbol name. For `def`, also try to capture the parameter signature for the location label.
 *
 * This is intentionally surface-level: we trust Nushell's tokenization of the declarations
 * but don't try to figure out scoping or nested structures (which the LSP server can answer
 * better via Find Usages / Go to Definition).
 */
internal object NushellOutline {

    private val INTRODUCERS = mapOf(
        "def" to SymbolKind.Def,
        "extern" to SymbolKind.Extern,
        "alias" to SymbolKind.Alias,
        "module" to SymbolKind.Module,
        "use" to SymbolKind.Use,
        "let" to SymbolKind.Let,
        "mut" to SymbolKind.Mut,
        "const" to SymbolKind.Const,
        "export" to SymbolKind.Export,
    )

    /** Computes the structure-view outline directly from a parsed AST. */
    fun fromAst(entries: List<NuAstEntry>): List<NushellOutlineSymbol> {
        val out = mutableListOf<NushellOutlineSymbol>()

        var i = 0
        while (i < entries.size) {
            val e = entries[i]
            val introducer: SymbolKind? = if (e.shape == "shape_internalcall" || e.shape == "shape_keyword")
                INTRODUCERS[e.content.trim()]
            else null

            if (introducer == null) { i++; continue }

            // Special case: `def --env name [...]` – the `--env` flag follows the introducer.
            var kind: SymbolKind = introducer
            var j = i + 1
            while (j < entries.size && (entries[j].shape == "shape_flag" || entries[j].shape == "shape_keyword")) {
                if (introducer == SymbolKind.Def && entries[j].content.trim() == "--env") kind = SymbolKind.DefEnv
                j++
            }

            // The next significant entry is the name.
            val nameEntry = entries.getOrNull(j)
            if (nameEntry == null) { i++; continue }
            val nameShape = nameEntry.shape
            val nameOk = nameShape == "shape_string" || nameShape == "shape_vardecl" ||
                    nameShape == "shape_internalcall" || nameShape == "shape_external" ||
                    nameShape == "shape_external_resolved"
            if (!nameOk) { i++; continue }

            val rawName = nameEntry.content.trim().trim('"', '\'')
            if (rawName.isEmpty()) { i++; continue }

            // For `def`/`extern`, capture the next signature only if it comes before the
            // next introducer-style token. (Aliases and let/mut/const don't have signatures.)
            val signature: String? = if (kind == SymbolKind.Def || kind == SymbolKind.DefEnv || kind == SymbolKind.Extern) {
                var sig: String? = null
                var k = j + 1
                while (k < entries.size) {
                    val ek = entries[k]
                    if (ek.shape == "shape_signature") { sig = ek.content.trim(); break }
                    // Stop looking once we hit the next introducer.
                    if ((ek.shape == "shape_internalcall" || ek.shape == "shape_keyword") &&
                        INTRODUCERS.containsKey(ek.content.trim())) break
                    k++
                }
                sig
            } else null

            out += NushellOutlineSymbol(
                name = rawName,
                kind = kind,
                nameStart = nameEntry.start,
                nameEnd = nameEntry.end,
                signature = signature?.takeIf { it.isNotBlank() }?.let { compactSignature(it) },
            )
            i = j + 1
        }
        return out
    }

    private fun compactSignature(s: String): String {
        // Collapse newlines/runs of whitespace for the location label.
        val collapsed = s.replace(Regex("\\s+"), " ").trim()
        return if (collapsed.length > 80) collapsed.take(77) + "…" else collapsed
    }
}
