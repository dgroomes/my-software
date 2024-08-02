package dgroomes.markdown_code_fence_reader

import com.fasterxml.jackson.databind.ObjectMapper
import org.intellij.markdown.MarkdownElementTypes
import org.intellij.markdown.MarkdownTokenTypes
import org.intellij.markdown.ast.ASTNode
import org.intellij.markdown.flavours.gfm.GFMFlavourDescriptor
import org.intellij.markdown.parser.MarkdownParser
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Paths
import java.util.*
import kotlin.system.exitProcess

/**
 * Please see the README for more information.
 */
fun main(args: Array<String>) {
    if (args.isEmpty()) {
        System.err.println("Found no arguments. Please provide the path to a Markdown file as the first argument.")
        exitProcess(1)
    }

    if (args.size > 1) {
        System.err.println("Too many arguments. Please provide the path to a Markdown file as the first and only argument.")
        exitProcess(1)
    }

    val pathStr = args[0]
    val path = Paths.get(pathStr).toAbsolutePath().normalize()
    if (!Files.exists(path)) {
        System.err.printf("File not found: '%s'%n", path)
        exitProcess(1)
    }

    val markdownContent: String
    try {
        markdownContent = Files.readString(path)
    } catch (e: IOException) {
        System.err.printf("Something went wrong while reading the file '%s': %s%n", path, e.message)
        exitProcess(1)
    }

    val snippets = findSnippets(markdownContent)
    val objectMapper = ObjectMapper().findAndRegisterModules()
    val json = objectMapper.writeValueAsString(snippets)
    println(json)
}

/**
 * A shell code snippet extracted from a Markdown document.
 *
 * For example, a Markdown document might contain the following snippet:
 *
 * ~~~
 * ```bash
 * echo 'Hello World'
 * ```
 * ~~~
 *
 * This class would encode the "bash" language descriptor in the [language] field and the "echo 'Hello World'"
 * content in the [content] field.
 */
data class ShellSnippet(val language: String?, val content: String)

/**
 * Given a Markdown document, extract "fenced" code snippets that are for shell languages like "shell", "bash", "sh",
 * and "nushell".
 */
fun findSnippets(markdownContent: String): List<ShellSnippet> {

    val flavor = GFMFlavourDescriptor()
    val tree = MarkdownParser(flavor).buildMarkdownTreeFromString(markdownContent)

    val snippets = mutableListOf<ShellSnippet>()
    val nodeStack: Deque<ASTNode> = ArrayDeque(tree.children)

    while (nodeStack.isNotEmpty()) {
        val node = nodeStack.pop()
        if (node.type === MarkdownElementTypes.CODE_FENCE) snippets.add(extractSnippet(markdownContent, node))
        // Add all elements to the front of the stack (which is a little awkward to accomplish with a Deque)
        node.children.reversed().forEach { nodeStack.push(it) }
    }

    return snippets
}

/**
 * From a code fence element, extract a [ShellSnippet].
 */
fun extractSnippet(markdownContent: String, node: ASTNode): ShellSnippet {
    var language: String? = null
    val content = StringBuilder()
    var struckContent = false
    for (child in node.children) {
        // At first, we chomp through sections to find the language descriptor (if present) and then the first
        // code fence "content" section.
        if (!struckContent) {
            if (child.type === MarkdownTokenTypes.FENCE_LANG) {
                language = markdownContent.substring(child.startOffset, child.endOffset)
            } else if (child.type === MarkdownTokenTypes.CODE_FENCE_CONTENT) {
                struckContent = true
                content.append(markdownContent.substring(child.startOffset, child.endOffset))
            }

            continue
        }

        if (child.type === MarkdownTokenTypes.CODE_FENCE_CONTENT) {
            content.append(markdownContent.substring(child.startOffset, child.endOffset))
        } else if (child.type === MarkdownTokenTypes.EOL) {
            content.append(System.lineSeparator())
        } else if (child.type === MarkdownTokenTypes.CODE_FENCE_END) {
            // Remove the trailing newline character
            if (content.endsWith(System.lineSeparator())) {
                content.delete(content.length - System.lineSeparator().length, content.length)
            }
            break
        }
    }

    return ShellSnippet(language, content.toString())
}

@Suppress("unused")
fun describe(node: ASTNode): String {
    return String.format("type=%s children=%s", node.type, node.children.size)
}
