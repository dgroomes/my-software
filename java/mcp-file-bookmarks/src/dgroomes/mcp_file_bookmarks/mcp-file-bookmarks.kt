package dgroomes.mcp_file_bookmarks

import io.modelcontextprotocol.kotlin.sdk.*
import io.modelcontextprotocol.kotlin.sdk.server.Server
import io.modelcontextprotocol.kotlin.sdk.server.ServerOptions
import io.modelcontextprotocol.kotlin.sdk.server.StdioServerTransport
import kotlinx.coroutines.Job
import kotlinx.coroutines.runBlocking
import kotlinx.io.asSink
import kotlinx.io.asSource
import kotlinx.io.buffered
import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.*
import org.slf4j.LoggerFactory
import java.nio.file.Files
import java.nio.file.Paths

private val log = LoggerFactory.getLogger("MCP-FileBookmarks")

/**
 * File bookmark entry within a bookmark directory
 */
@Serializable
data class BookmarkFile(
    val path: String,
    val description: String
)

/**
 * Directory containing bookmarked files
 */
@Serializable
data class BookmarkDirectory(
    val base_path: String,
    val description: String,
    val entries: List<BookmarkFile>
)

/**
 * Load bookmarks from the user's config file
 */
fun loadBookmarks(): List<BookmarkDirectory> {
    val fbFile = Paths.get(System.getProperty("user.home"), ".local", "file-bookmarks.json")

    if (!Files.exists(fbFile)) {
        log.warn("No bookmarks file found at: {}", fbFile)
        return emptyList()
    }

    return try {
        val raw = Files.readString(fbFile)
        val json = Json { ignoreUnknownKeys = true }
        val collections = json.decodeFromString<List<BookmarkDirectory>>(raw)
        val bookmarks = collections.sumOf { it.entries.size }
        log.info("Loaded {} bookmark collections with a total of {} bookmarks", collections.size, bookmarks)
        collections
    } catch (e: Exception) {
        log.error("Error loading bookmarks", e)
        emptyList()
    }
}

/**
 * Expand tilde (~) to home directory if it's at the start of the path
 */
fun expandTilde(filePath: String): String {
    return if (filePath.startsWith("~")) {
        System.getProperty("user.home") + filePath.substring(1)
    } else {
        filePath
    }
}

/**
 * Find a bookmark by base path and entry path
 */
fun findBookmark(
    collections: List<BookmarkDirectory>,
    basePath: String,
    entryPath: String
): Pair<BookmarkDirectory, BookmarkFile>? {
    val collection = collections.find { it.base_path == basePath }

    if (collection == null) {
        log.debug("Collection with base path \"{}\" not found", basePath)
        return null
    }

    val entry = collection.entries.find { it.path == entryPath }

    if (entry == null) {
        log.debug("Entry with path \"{}\" not found in collection {}", entryPath, basePath)
        return null
    }

    return collection to entry
}

/**
 * Get the content of a bookmarked file
 */
fun getBookmarkContent(
    collections: List<BookmarkDirectory>,
    basePath: String,
    entryPath: String
): String {
    val bookmark = findBookmark(collections, basePath, entryPath)

    if (bookmark == null) {
        return "Error: Bookmark not found (base_path: $basePath, path: $entryPath)"
    }

    val (collection, entry) = bookmark
    val expandedBasePath = expandTilde(collection.base_path)
    val fullPath = Paths.get(expandedBasePath, entry.path).toString()
    log.debug("Getting content for bookmark: {} ({})", entry.path, fullPath)

    return try {
        Files.readString(Paths.get(fullPath))
    } catch (e: kotlinx.io.IOException) {
        val msg = "Error getting content for ${entry.path}: ${e.message}"
        log.error(msg, e)
        msg
    }
}

/**
 * Handle the list command
 */
fun handleList(): CallToolResult {
    return try {
        log.debug("Listing all bookmarks")
        val bookmarks = loadBookmarks()

        if (bookmarks.isEmpty()) {
            log.debug("No bookmarks found in configuration files")
            CallToolResult(
                content = listOf(
                    TextContent("No bookmarks found. Please create ~/.local/file-bookmarks.json")
                )
            )
        } else {
            val json = Json { prettyPrint = true }
            val formattedList = json.encodeToString(bookmarks)

            CallToolResult(
                content = listOf(TextContent(formattedList))
            )
        }
    } catch (e: Exception) {
        log.error("Error in file_bookmarks_list", e)
        CallToolResult(
            content = listOf(
                TextContent("Error listing bookmarks: ${e.message}")
            ),
            isError = true
        )
    }
}

/**
 * Handle the howto command
 */
fun handleHowto(): CallToolResult {
    val howtoText = """# File Bookmarks Usage Workflow

## Standard Process

1. **Call list()** to see all available bookmarks and their descriptions
2. **Cross-reference** user search terms with bookmark descriptions
3. **Handle matches appropriately:**
   - **One clear match**: Call get() with the matching base_path and entry_path
   - **Multiple matches**: Ask user to clarify which specific bookmark they want
   - **No matches**: Inform user no matching bookmarks found, suggest reviewing the list

## Example Workflow

User: "!fb bash trick for curr dir"

1. Call list() → see bookmark: "Among other things, contains a 'Bash trick for getting current dir'"
2. Match found → call get() with appropriate parameters
3. Return file contents to user

## Key Guidelines

- Match based on bookmark descriptions, not just keywords
- Use semantic understanding rather than string matching
- When uncertain between multiple options, always ask the user to choose
- Focus on what the user needs (the "why") rather than exact terms

## Tool Parameters

- **get(base_path, entry_path)**: Both parameters come from the list() output
  - base_path: Collection's base path (e.g., "~/repos/personal/my-software")  
  - entry_path: Relative path within collection (e.g., "go/README.md")
"""

    return CallToolResult(
        content = listOf(TextContent(howtoText))
    )
}

fun handleGet(request: CallToolRequest): CallToolResult {
    val basePath = request.arguments["base_path"]?.jsonPrimitive?.content
    val entryPath = request.arguments["entry_path"]?.jsonPrimitive?.content

    if (basePath == null || entryPath == null) {
        return CallToolResult(
            content = listOf(
                TextContent("The 'base_path' and 'entry_path' parameters are required.")
            ),
            isError = true
        )
    }

    return try {
        log.debug("Getting bookmark content (base_path: {}, path: {})", basePath, entryPath)
        val bookmarks = loadBookmarks()

        if (bookmarks.isEmpty()) {
            log.debug("No bookmarks found in configuration files")
            CallToolResult(
                content = listOf(
                    TextContent("No bookmarks found. Please create ~/.local/file-bookmarks.json")
                )
            )
        } else {
            val content = getBookmarkContent(bookmarks, basePath, entryPath)
            CallToolResult(
                content = listOf(TextContent(content))
            )
        }
    } catch (e: Exception) {
        log.error("Error in file_bookmarks_get", e)
        CallToolResult(
            content = listOf(
                TextContent("Error getting bookmark content: ${e.message}")
            ),
            isError = true
        )
    }
}

/**
 * Main entry point for the File Bookmarks MCP server.
 *
 * This server provides tools to access bookmarked files from local repositories.
 */
fun main() {
    // Create the MCP Server instance
    val server = Server(
        Implementation(
            name = "File Bookmarks",
            version = "0.1.0"
        ),
        ServerOptions(
            capabilities = ServerCapabilities(
                tools = ServerCapabilities.Tools(listChanged = true)
            )
        )
    )

    server.addTool(
        name = "howto",
        description = "Call FIRST when user requests file bookmarks (indicated by !fb prefix). Explains how to use file bookmark tools and handle multiple/no matches.",
        inputSchema = Tool.Input(
            properties = buildJsonObject {},
            required = emptyList()
        )
    ) {
        handleHowto()
    }

    server.addTool(
        name = "list",
        description = "List all available bookmarked files with descriptions and paths (see 'howto')",
        inputSchema = Tool.Input(
            properties = buildJsonObject {},
            required = emptyList()
        )
    ) {
        handleList()
    }

    server.addTool(
        name = "get",
        description = "Get the content of a specific bookmarked file (see 'howto')",
        inputSchema = Tool.Input(
            properties = buildJsonObject {
                putJsonObject("base_path") {
                    put("type", "string")
                    put("description", "Base path of the collection containing the bookmark")
                }
                putJsonObject("entry_path") {
                    put("type", "string")
                    put("description", "Path of the entry to retrieve")
                }
            },
            required = listOf("base_path", "entry_path")
        )
    ) { request ->
        handleGet(request)
    }

    val transport = StdioServerTransport(
        System.`in`.asSource().buffered(),
        System.out.asSink().buffered()
    )

    runBlocking {
        server.connect(transport)
        val done = Job()
        server.onClose {
            done.complete()
        }
        log.info("File Bookmarks MCP Server started")
        done.join()
    }
}
