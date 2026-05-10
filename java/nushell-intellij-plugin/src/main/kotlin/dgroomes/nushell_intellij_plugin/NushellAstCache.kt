package dgroomes.nushell_intellij_plugin

import com.intellij.openapi.application.ApplicationManager
import com.intellij.openapi.components.Service
import com.intellij.openapi.editor.Document
import com.intellij.openapi.fileEditor.FileDocumentManager
import com.intellij.openapi.vfs.VirtualFile
import dgroomes.nushell.NuAstEntry
import java.util.concurrent.ConcurrentHashMap

/**
 * Application-level cache of `nu --ide-ast` results, keyed by virtual file URL and document
 * modification stamp.
 *
 * Why a cache exists: spawning `nu` from a read action is forbidden (OSProcessHandler refuses
 * to block under a ReadAction), so the [NushellStructureView] cannot shell out lazily from
 * inside `getChildren()`. Instead, the [NushellSemanticAnnotator] — which runs off-EDT — does
 * the actual work and stores the result here. The structure view (and anyone else) just looks
 * up a cached value, treating "no result yet" as "nothing to show". When the user edits the
 * file the cache entry is invalidated by stamp.
 */
@Service(Service.Level.APP)
class NushellAstCache {

    private data class Entry(val stamp: Long, val entries: List<NuAstEntry>)

    private val cache = ConcurrentHashMap<String, Entry>()

    /** Latest cached AST entries for [document], or null if nothing has been computed yet. */
    fun get(document: Document): List<NuAstEntry>? {
        val key = keyFor(document) ?: return null
        val cached = cache[key] ?: return null
        return if (cached.stamp == document.modificationStamp) cached.entries else null
    }

    /** Latest cached AST entries for the document backing [virtualFile], if any. */
    fun get(virtualFile: VirtualFile): List<NuAstEntry>? {
        val key = virtualFile.url
        val document = FileDocumentManager.getInstance().getDocument(virtualFile) ?: return null
        val cached = cache[key] ?: return null
        return if (cached.stamp == document.modificationStamp) cached.entries else null
    }

    /** Store a freshly-computed AST for [document]. */
    fun put(document: Document, stamp: Long, entries: List<NuAstEntry>) {
        val key = keyFor(document) ?: return
        cache[key] = Entry(stamp, entries)
    }

    private fun keyFor(document: Document): String? =
        FileDocumentManager.getInstance().getFile(document)?.url

    companion object {
        fun getInstance(): NushellAstCache = ApplicationManager.getApplication().getService(NushellAstCache::class.java)
    }
}
