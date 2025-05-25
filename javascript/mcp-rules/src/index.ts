import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import fs from "fs/promises";
import path from "path";
import os from "os";

interface AgentFile {
  path: string;
  context: "user" | "project" | "user-project";
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

/**
 * Find all AGENT.md files in the three conventional locations:
 * 1. User rules - ${XDG_CONFIG_HOME}/llm-agent/AGENT.md
 * 2. Project rules - ./AGENT.md (searching upwards from current directory)
 * 3. User-project rules - ./.my/AGENT.md
 */
async function findAgentFiles(): Promise<AgentFile[]> {
  const files: AgentFile[] = [];

  // 1. User rules
  const xdgConfigHomeEnv = process.env.XDG_CONFIG_HOME;
  let xdgConfigHome: string;

  if (xdgConfigHomeEnv) {
    console.error(`XDG_CONFIG_HOME is set to: ${xdgConfigHomeEnv}`);
    xdgConfigHome = expandTilde(xdgConfigHomeEnv);
  } else {
    const defaultConfigHome = path.join(os.homedir(), ".config");
    console.error(`XDG_CONFIG_HOME not set, using default: ${defaultConfigHome}`);
    xdgConfigHome = defaultConfigHome;
  }

  const userRulesPath = path.join(xdgConfigHome, "llm-agent", "AGENT.md");
  try {
    await fs.access(userRulesPath);
    files.push({ path: userRulesPath, context: "user" });
    console.error(`Found user rules at: ${userRulesPath}`);
  } catch {
    console.error(`No user rules found at: ${userRulesPath}`);
  }

  // 2. Project rules - search upwards from current directory
  let currentDir = process.cwd();
  let projectRulesFound = false;
  while (!projectRulesFound) {
    const projectRulesPath = path.join(currentDir, "AGENT.md");
    try {
      await fs.access(projectRulesPath);
      files.push({ path: projectRulesPath, context: "project" });
      console.error(`Found project rules at: ${projectRulesPath}`);
      projectRulesFound = true;
    } catch {
      const parentDir = path.dirname(currentDir);
      if (parentDir === currentDir) {
        console.error("No project rules found searching upwards from current directory");
        break;
      }
      currentDir = parentDir;
    }
  }

  // 3. User-project rules
  const userProjectRulesPath = path.join(process.cwd(), ".my", "AGENT.md");
  try {
    await fs.access(userProjectRulesPath);
    files.push({ path: userProjectRulesPath, context: "user-project" });
    console.error(`Found user-project rules at: ${userProjectRulesPath}`);
  } catch {
    console.error(`No user-project rules found at: ${userProjectRulesPath}`);
  }

  return files;
}

async function loadRules() {
  try {
    console.error("Loading agent rules from conventional locations");

    const agentFiles = await findAgentFiles();

    if (agentFiles.length === 0) {
      console.error("No AGENT.md files found in any location");
      return {
        content: [{
          type: "text" as const,
          text: "No AGENT.md files found. Searched locations:\n" +
                "1. User rules: ${XDG_CONFIG_HOME}/llm-agent/AGENT.md\n" +
                "2. Project rules: ./AGENT.md (and parent directories)\n" +
                "3. User-project rules: ./.my/AGENT.md"
        }]
      };
    }

    // Read and concatenate the contents of all found files
    let combinedRules = "Agent rules below. Priority is lowest to highest. Later rules override earlier ones.\n\n";

    for (const agentFile of agentFiles) {
      try {
        const content = await fs.readFile(agentFile.path, "utf-8");
        combinedRules += `# Rules from ${agentFile.context} context (${agentFile.path})\n\n`;
        combinedRules += content;
        combinedRules += "\n\n";
      } catch (error) {
        const msg = `Error reading ${agentFile.path}: ${error instanceof Error ? error.message : String(error)}`;
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

  server.tool(
    "load_rules",
    "START HERE. Load agent rules from user, project, and user-project locations. ONLY skip this if user explicitly says '!rules off'. You MUST call this tool before starting any other work.",
    {},
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
