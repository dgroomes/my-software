// WARNING: Unedited AI output

package dgroomes.cobol_intellij_plugin

import com.intellij.lang.Language

/**
 * A real IntelliJ language so `.cob` / `.cbl` are not left as Plain Text.
 * Coloring is delegated to che4z's TextMate grammar; analysis stays on the LSP server.
 */
object CobolLanguage : Language("COBOL")
