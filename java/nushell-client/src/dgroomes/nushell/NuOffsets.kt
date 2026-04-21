package dgroomes.nushell

/**
 * Both `nu_parser::lex` and `nu --ide-ast` report spans as **byte offsets** into the source
 * file. JVM consumers (the IntelliJ document model in particular) address text by **character
 * offsets** (UTF-16 code units). The two coincide for ASCII-only sources but diverge by N
 * whenever the source contains N extra UTF-8 bytes from multi-byte characters earlier in the
 * file.
 *
 * This object converts a sorted list of byte offsets to character offsets in a single linear
 * pass. Callers should batch offsets per source rather than translating one at a time.
 */
object NuOffsets {

    /**
     * Returns a map from each requested byte offset to the corresponding character offset in
     * [text]. Offsets at or past EOF clamp to `text.length`.
     *
     * Fast path: if [text] is ASCII-only (the common case), every byte offset equals the
     * character offset and a self-mapping is returned without scanning.
     */
    fun byteToChar(text: String, byteOffsets: Collection<Int>): Map<Int, Int> {
        if (byteOffsets.isEmpty()) return emptyMap()
        if (isAscii(text)) return byteOffsets.associateWith { it }

        val sorted = byteOffsets.toSortedSet()
        val out = HashMap<Int, Int>(sorted.size)
        val targets = sorted.iterator()
        var nextTarget: Int? = if (targets.hasNext()) targets.next() else null

        var charIdx = 0
        var byteIdx = 0
        while (nextTarget != null && charIdx < text.length) {
            while (nextTarget != null && byteIdx >= nextTarget) {
                out[nextTarget] = charIdx
                nextTarget = if (targets.hasNext()) targets.next() else null
            }
            if (nextTarget == null) break
            val cp = text.codePointAt(charIdx)
            charIdx += Character.charCount(cp)
            byteIdx += utf8ByteLength(cp)
        }
        while (nextTarget != null) {
            out[nextTarget] = text.length
            nextTarget = if (targets.hasNext()) targets.next() else null
        }
        return out
    }

    private fun isAscii(text: String): Boolean {
        for (i in 0 until text.length) {
            if (text[i].code >= 0x80) return false
        }
        return true
    }

    private fun utf8ByteLength(codePoint: Int): Int = when {
        codePoint < 0x80 -> 1
        codePoint < 0x800 -> 2
        codePoint < 0x10000 -> 3
        else -> 4
    }
}
