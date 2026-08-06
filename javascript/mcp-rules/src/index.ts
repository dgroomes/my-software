import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import fs from "fs/promises";
import path from "path";
import os from "os";

interface AgentFile {
  path: string;
  displayPath: string;
  context: "user-global" | "user-local";
}

/**
 * Find all AGENTS.md files in the two conventional locations:
 * 1. User-global rules - ~/.config/llm-agent/AGENTS.md
 * 2. User-local rules - ./.my/AGENTS.md
 */
async function findAgentFiles(): Promise<AgentFile[]> {
  const files: AgentFile[] = [];

  // 1. User-global rules
  const userGlobalRulesPath = path.join(os.homedir(), ".config", "llm-agent", "AGENTS.md");
  try {
    await fs.access(userGlobalRulesPath);
    files.push({
      path: userGlobalRulesPath,
      displayPath: "~/.config/llm-agent/AGENTS.md",
      context: "user-global"
    });
    console.error(`Found user-global rules at: ${userGlobalRulesPath}`);
  } catch {
    console.error(`No user-global rules found at: ${userGlobalRulesPath}`);
  }

  // 2. User-local rules
  const userLocalRulesPath = path.join(process.cwd(), ".my", "AGENTS.md");
  try {
    await fs.access(userLocalRulesPath);
    files.push({
      path: userLocalRulesPath,
      displayPath: "./.my/AGENTS.md",
      context: "user-local"
    });
    console.error(`Found user-local rules at: ${userLocalRulesPath}`);
  } catch {
    console.error(`No user-local rules found at: ${userLocalRulesPath}`);
  }

  return files;
}

async function loadRules() {
  try {
    console.error("Loading agent rules from conventional locations");

    const agentFiles = await findAgentFiles();

    if (agentFiles.length === 0) {
      console.error("No AGENTS.md files found in any location");
      return {
        content: [{
          type: "text" as const,
          text: "No AGENTS.md files found. Searched locations:\n" +
                "1. User-global rules: ~/.config/llm-agent/AGENTS.md\n" +
                "2. User-local rules: ./.my/AGENTS.md"
        }]
      };
    }

    // Read and concatenate the contents of all found files
    let combinedRules = "Agent rules below. Priority is lowest to highest. Later rules override earlier ones.\n\n";

    for (const agentFile of agentFiles) {
      try {
        const content = await fs.readFile(agentFile.path, "utf-8");
        combinedRules += `(rules from ${agentFile.context} context: ${agentFile.displayPath})\n\n`;
        combinedRules += content;
        combinedRules += "\n\n";
      } catch (error) {
        const msg = `Error reading ${agentFile.displayPath}: ${error instanceof Error ? error.message : String(error)}`;
        console.error(msg);
        combinedRules += `# Error loading ${agentFile.context} rules\n${msg}\n\n`;
      }
    }

    console.error(`Successfully loaded rules from ${agentFiles.length} file(s)`);

    return {
      content: [{
        type: "text" as const,
        text: combinedRules
      }]
    };
  } catch (error) {
    const errorMsg = `Error loading rules: ${error instanceof Error ? error.message : String(error)}`;
    console.error(errorMsg);
    return {
      content: [{
        type: "text" as const,
        text: errorMsg
      }],
      isError: true
    };
  }
}

/**
 * Main entry point for the Rules MCP server.
 *
 * This server provides a tool to load agent rules from conventional locations.
 */
async function main() {
  const server = new McpServer({
    name: "Rules",
    version: "0.1.0"
  });

  server.registerTool(
    "load_rules",
    {
      description: "START HERE. Load agent rules from user-global and user-local locations. ONLY skip this if user explicitly says '!rules off'. You MUST call this tool before starting any other work.",
      inputSchema: {}
    },
    loadRules
  );

  const transport = new StdioServerTransport();
  await server.connect(transport);

  console.error("Rules MCP Server started");
}

main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
