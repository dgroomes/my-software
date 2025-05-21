import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { listEntries, fetchEntryContent } from "./lib/entries.js";

/**
 * Main entry point for the MCP Context Library server.
 *
 * This server provides tools to access a curated list of reference files
 * and directories from local git repositories.
 */
async function main() {
  // Create an MCP server
  const server = new McpServer({
    name: "Context Library",
    version: "0.1.0"
  });

  // Register the list_entries tool
  server.tool(
    "list_entries",
    {
      pattern: z.string().optional().describe("Optional glob pattern to filter entries"),
      exclude_patterns: z.array(z.string()).optional().describe("Optional glob patterns to exclude")
    },
    async ({ pattern, exclude_patterns }) => {
      try {
        const entries = await listEntries(pattern, exclude_patterns);

        return {
          content: [{
            type: "text",
            text: JSON.stringify(entries, null, 2)
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: `Error listing entries: ${error instanceof Error ? error.message : String(error)}`
          }],
          isError: true
        };
      }
    }
  );

  // Register the fetch_entry tool
  server.tool(
    "fetch_entry",
    {
      path: z.string().describe("Path of the entry to fetch")
    },
    async ({ path }) => {
      try {
        const content = await fetchEntryContent(path);

        return {
          content: [{
            type: "text",
            text: content
          }]
        };
      } catch (error) {
        return {
          content: [{
            type: "text",
            text: `Error fetching entry '${path}': ${error instanceof Error ? error.message : String(error)}`
          }],
          isError: true
        };
      }
    }
  );

  // Connect to stdio transport
  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error("Context Library MCP Server started");
}

// Handle errors and shutdown
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
