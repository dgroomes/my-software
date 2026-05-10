package dgroomes.nushell_intellij_plugin

import com.intellij.lang.annotation.AnnotationHolder
import com.intellij.lang.annotation.ExternalAnnotator
import com.intellij.lang.annotation.HighlightSeverity
import com.intellij.openapi.editor.Document
import com.intellij.openapi.editor.colors.TextAttributesKey
import com.intellij.openapi.util.TextRange
import com.intellij.psi.PsiDocumentManager
import com.intellij.psi.PsiFile
import dgroomes.nushell.NuAstEntry
import dgroomes.nushell.NuIde

/**
 * Semantic highlighting for Nushell, sourced directly from `nu --ide-ast`.
 *
 * The shelling-out and JSON parsing live in `nushell-client`'s [NuIde]; this annotator just
 * maps each entry's `shape` to a [NushellColors] key and paints the range. Because
 * [ExternalAnnotator] runs `doAnnotate` off the EDT, this is the right place to invoke `nu`.
 *
 * Side effect: each successful run updates [NushellAstCache] so the structure view (which
 * runs inside a read action and can't shell out itself) can render from the latest AST.
 */
class NushellSemanticAnnotator : ExternalAnnotator<NushellSemanticAnnotator.Input, List<NushellSemanticAnnotator.Annotation>>() {

    data class Annotation(val range: TextRange, val key: TextAttributesKey)
    data class Input(val text: String, val length: Int, val stamp: Long, val document: Document?)

    override fun collectInformation(file: PsiFile): Input? {
        if (file !is NushellPsiFile) return null
        val text = file.text
        if (text.isBlank()) return null
        val document = PsiDocumentManager.getInstance(file.project).getDocument(file)
        return Input(text, text.length, document?.modificationStamp ?: 0, document)
    }

    override fun doAnnotate(collectedInfo: Input?): List<Annotation> {
        if (collectedInfo == null) return emptyList()
        val nu = NuIde.findNuOnPath() ?: return emptyList()
        val entries: List<NuAstEntry> = NuIde(nu).ideAst(collectedInfo.text)
        if (entries.isEmpty()) return emptyList()

        if (collectedInfo.document != null) {
            NushellAstCache.getInstance().put(collectedInfo.document, collectedInfo.stamp, entries)
        }

        val docLen = collectedInfo.length
        val out = ArrayList<Annotation>(entries.size)
        for (entry in entries) {
            val key = colorForShape(entry.shape) ?: continue
            val s = entry.start.coerceIn(0, docLen)
            val e = entry.end.coerceIn(s, docLen)
            if (e > s) out += Annotation(TextRange(s, e), key)
        }
        return out
    }

    override fun apply(file: PsiFile, annotationResult: List<Annotation>, holder: AnnotationHolder) {
        for (a in annotationResult) {
            holder.newSilentAnnotation(HighlightSeverity.INFORMATION)
                .range(a.range)
                .textAttributes(a.key)
                .create()
        }
    }

    private fun colorForShape(shape: String): TextAttributesKey? = when (shape) {
        "shape_internalcall" -> NushellColors.INTERNAL_CALL
        "shape_external", "shape_external_resolved", "shape_externalarg" -> NushellColors.EXTERNAL_CALL
        "shape_keyword" -> NushellColors.KEYWORD
        "shape_string", "shape_raw_string" -> NushellColors.STRING
        "shape_string_interpolation", "shape_glob_interpolation" -> NushellColors.STRING_INTERPOLATION
        "shape_int", "shape_float", "shape_range", "shape_binary" -> NushellColors.NUMBER
        "shape_bool", "shape_nothing" -> NushellColors.BOOL
        "shape_operator" -> NushellColors.OPERATOR
        "shape_pipe" -> NushellColors.PIPE
        "shape_redirection" -> NushellColors.OPERATOR
        "shape_flag" -> NushellColors.FLAG
        "shape_variable" -> NushellColors.VARIABLE
        "shape_vardecl" -> NushellColors.VAR_DECL
        "shape_signature" -> NushellColors.SIGNATURE
        "shape_match_pattern" -> NushellColors.MATCH_PATTERN
        "shape_filepath" -> NushellColors.FILEPATH
        "shape_directory" -> NushellColors.DIRECTORY
        "shape_globpattern" -> NushellColors.GLOB_PATTERN
        "shape_datetime" -> NushellColors.DATETIME
        "shape_garbage" -> NushellColors.GARBAGE
        // Structural shapes are already painted by the lexer-based highlighter; skipping
        // here avoids double-paint and lets bracket-pair-highlighting plugins behave normally.
        "shape_block", "shape_closure", "shape_list", "shape_record", "shape_table" -> null
        else -> null
    }
}
