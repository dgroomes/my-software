import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import fs from "fs/promises";
import path from "path";
import os from "os";
import { z } from "zod";

interface BookmarkFile {
  path: string;
  description: string;
}

interface BookmarkDirectory {
  base_path: string;
  description: string;
  entries: BookmarkFile[];
}

async function loadBookmarks(): Promise<BookmarkDirectory[]> {
  const fbFile = path.join(os.homedir(), ".local", "file-bookmarks.json");

  try {
    await fs.access(fbFile);
  } catch {
    console.error("No bookmarks file found.");
    return [];
  }

  try {
    const raw = await fs.readFile(fbFile, "utf-8");
    const collections = JSON.parse(raw) as BookmarkDirectory[];
    const bookmarks = collections.reduce((sum, col) => sum + col.entries.length, 0);
    console.error(`Loaded ${collections.length} bookmark collections with a total of ${bookmarks} bookmarks`);
    return collections;
  } catch (error) {
    console.error(`Error loading bookmarks: ${error instanceof Error ? error.message : String(error)}`);
    return [];
  }
}

/**
 * Expand tilde (~) to home directory if it's at the start of the path
 */
function expandTilde(filePath: string): string {
  if (filePath.startsWith('~')) {
    return path.join(os.homedir(), filePath.slice(1));
  }
  return filePath;
}

async function readFileContent(fullPath: string, relativePath: string): Promise<string> {
  try {
    return await fs.readFile(fullPath, "utf-8");
  } catch (error) {
    const msg = `Error reading file ${fullPath}: ${error instanceof Error ? error.message : String(error)}`;
    console.error(msg);
    return msg;
  }
}

function findBookmark(collections: BookmarkDirectory[], basePath: string, entryPath: string): {
  collection: BookmarkDirectory;
  entry: BookmarkFile;
} | null {
  const collection = collections.find(c => c.base_path === basePath);
  
  if (!collection) {
    console.error(`Collection with base path "${basePath}" not found`);
    return null;
  }
  
  const entry = collection.entries.find(e => e.path === entryPath);
  
  if (!entry) {
    console.error(`Entry with path "${entryPath}" not found in collection ${basePath}`);
    return null;
  }
  
  return { collection, entry };
}

async function getBookmarkContent(collections: BookmarkDirectory[], basePath: string, entryPath: string): Promise<string> {
  const bookmark = findBookmark(collections, basePath, entryPath);
  
  if (!bookmark) {
    return `Error: Bookmark not found (base_path: ${basePath}, path: ${entryPath})`;
  }
  
  const { collection, entry } = bookmark;
  const expandedBasePath = expandTilde(collection.base_path);
  const fullPath = path.join(expandedBasePath, entry.path);
  console.error(`Getting content for bookmark: ${entry.path} (${fullPath})`);

  try {
    return await readFileContent(fullPath, entry.path);
  } catch (error) {
    const msg = `Error getting content for ${entry.path}: ${error instanceof Error ? error.message : String(error)}`;
    console.error(msg);
    return msg;
  }
}

async function handleList() {
  try {
    console.error("Listing all bookmarks");
    const bookmarks = await loadBookmarks();
    
    if (bookmarks.length === 0) {
      console.error("No bookmarks found in configuration files");
      return {
        content: [{
          type: "text" as const,
          text: "No bookmarks found. Please create ~/.local/file-bookmarks.json"
        }]
      };
    }
    
    const formattedList = JSON.stringify(bookmarks, null, 2);

    return {
      content: [{
        type: "text" as const,
        text: formattedList
      }]
    };
  } catch (error) {
    console.error(`Error in file_bookmarks_list: ${error instanceof Error ? error.message : String(error)}`);
    return {
      content: [{
        type: "text" as const,
        text: `Error listing bookmarks: ${error instanceof Error ? error.message : String(error)}`
      }],
      isError: true
    };
  }
}

async function handleHowto() {
  const howtoText = `# File Bookmarks Usage Workflow

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
`;

  return {
    content: [{
      type: "text" as const,
      text: howtoText
    }]
  };
}

async function handleGet({ base_path: basePath, entry_path: entryPath }: { base_path: string; entry_path: string }) {
  try {
    console.error(`Getting bookmark content (base_path: ${basePath}, path: ${entryPath})`);
    const bookmarks = await loadBookmarks();
    
    if (bookmarks.length === 0) {
      console.error("No bookmarks found in configuration files");
      return {
        content: [{
          type: "text" as const,
          text: "No bookmarks found. Please create ~/.local/file-bookmarks.json"
        }]
      };
    }
    
    const content = await getBookmarkContent(bookmarks, basePath, entryPath);
    
    return {
      content: [{
        type: "text" as const,
        text: content
      }]
    };
  } catch (error) {
    console.error(`Error in file_bookmarks_get: ${error instanceof Error ? error.message : String(error)}`);
    return {
      content: [{
        type: "text" as const,
        text: `Error getting bookmark content: ${error instanceof Error ? error.message : String(error)}`
      }],
      isError: true
    };
  }
}

/**
 * Main entry point for the File Bookmarks MCP server.
 *
 * This server provides tools to access bookmarked files from local repositories.
 */
async function main() {
  const server = new McpServer({
    name: "File Bookmarks",
    version: "0.1.0"
  });

  server.tool("howto", "Call FIRST when user requests file bookmarks (indicated by !fb prefix). Explains how to use file bookmark tools and handle multiple/no matches.", {}, handleHowto);
  server.tool("list", "List all available bookmarked files with descriptions and paths (see 'howto')", {}, handleList);
  server.tool("get", "Get the content of a specific bookmarked file (see 'howto')", {
    base_path: z.string().describe("Base path of the collection containing the bookmark"),
    entry_path: z.string().describe("Path of the entry to retrieve")
  }, handleGet);

  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error("File Bookmarks MCP Server started");
}

// Are these effective?
process.on("uncaughtException", (error) => {
  console.error("Uncaught exception:", error);
  process.exit(1);
});

process.on("unhandledRejection", (reason) => {
  console.error("Unhandled rejection:", reason);
  process.exit(1);
});

main().catch((error) => {
  console.error("Failed to start server:", error);
  process.exit(1);
});