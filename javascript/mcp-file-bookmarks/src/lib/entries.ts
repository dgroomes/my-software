import fs from "fs/promises";
import path from "path";
import os from "os";
import { minimatch } from "minimatch";

// Define the structure of a library entry
export interface LibraryEntry {
  path: string;
  description: string;
}

// Define the structure of the library entries configuration
export interface LibraryConfig {
  base_path: string;
  entries: LibraryEntry[];
  exclude_patterns?: string[];
}

// Cache for the library configuration
let configCache: LibraryConfig | null = null;

/**
 * Load the library configuration from the JSON file
 */
export async function loadConfig(): Promise<LibraryConfig> {
  if (configCache) {
    return configCache;
  }

  const configPath = path.join(process.cwd(), "test-file-bookmarks.json");
  try {
    const configData = await fs.readFile(configPath, "utf-8");
    const config = JSON.parse(configData) as LibraryConfig;

    // Expand ~ to home directory if present
    if (config.base_path.startsWith("~")) {
      config.base_path = config.base_path.replace("~", os.homedir());
    }

    // Normalize path
    config.base_path = path.normalize(config.base_path);

    configCache = config;
    return config;
  } catch (error) {
    throw new Error(`Failed to load library entries: ${error instanceof Error ? error.message : String(error)}`);
  }
}

/**
 * List all library entries, optionally filtering by pattern
 *
 * @param pattern Optional glob pattern to filter entries
 * @param excludePatterns Optional glob patterns to exclude
 * @returns List of matching library entries
 */
export async function listEntries(
  pattern?: string,
  excludePatterns?: string[]
): Promise<{ entries: LibraryEntry[] }> {
  const config = await loadConfig();

  let entries = config.entries;

  // Apply pattern filter if provided
  if (pattern) {
    entries = entries.filter(entry => minimatch(entry.path, pattern));
  }

  // Apply exclude patterns from configuration
  if (config.exclude_patterns) {
    for (const excludePattern of config.exclude_patterns) {
      entries = entries.filter(entry => !minimatch(entry.path, excludePattern));
    }
  }

  // Apply additional exclude patterns if provided
  if (excludePatterns) {
    for (const excludePattern of excludePatterns) {
      entries = entries.filter(entry => !minimatch(entry.path, excludePattern));
    }
  }

  return { entries };
}

/**
 * Check if a path is a directory
 *
 * @param fullPath Full path to check
 * @returns True if the path is a directory
 */
async function isDirectory(fullPath: string): Promise<boolean> {
  try {
    const stats = await fs.stat(fullPath);
    return stats.isDirectory();
  } catch (error) {
    return false;
  }
}

/**
 * Format file content with a header
 *
 * @param filePath Path to the file
 * @param content File content
 * @returns Formatted content with header
 */
function formatFileContent(filePath: string, content: string): string {
  return `╭───── ${filePath} ─────╮\n${content}\n╰${"─".repeat(filePath.length + 12)}╯`;
}

/**
 * List all files in a directory recursively
 *
 * @param dirPath Directory path
 * @param basePath Base path for relative paths
 * @param excludePatterns Patterns to exclude
 * @returns List of file paths
 */
async function listFilesRecursively(
  dirPath: string,
  basePath: string,
  excludePatterns: string[] = []
): Promise<string[]> {
  const files: string[] = [];

  const entries = await fs.readdir(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    const relativePath = path.relative(basePath, fullPath);

    // Skip if matches exclude patterns
    if (excludePatterns.some(pattern => minimatch(relativePath, pattern))) {
      continue;
    }

    if (entry.isDirectory()) {
      const subFiles = await listFilesRecursively(fullPath, basePath, excludePatterns);
      files.push(...subFiles);
    } else {
      files.push(fullPath);
    }
  }

  return files;
}

/**
 * Fetch the content of a library entry
 *
 * @param entryPath Path of the entry to fetch
 * @returns Formatted content of the entry
 */
export async function fetchEntryContent(entryPath: string): Promise<string> {
  const config = await loadConfig();

  // Check if the entry exists in the configuration
  const entry = config.entries.find(e => e.path === entryPath);
  if (!entry) {
    throw new Error(`Entry not found: ${entryPath}`);
  }

  // Resolve the full path
  const fullPath = path.join(config.base_path, entryPath);

  // Check if the path is a directory
  const isDir = await isDirectory(fullPath);

  if (isDir) {
    // For directories, concatenate all files
    const excludePatterns = config.exclude_patterns || [];
    const files = await listFilesRecursively(fullPath, config.base_path, excludePatterns);

    // Read and format each file
    const contents: string[] = [];
    for (const file of files) {
      try {
        const content = await fs.readFile(file, "utf-8");
        const relativePath = path.relative(config.base_path, file);
        contents.push(formatFileContent(relativePath, content));
      } catch (error) {
        console.error(`Failed to read file ${file}:`, error);
      }
    }

    return contents.join("\n\n");
  } else {
    // For single files, just return the content with a header
    try {
      const content = await fs.readFile(fullPath, "utf-8");
      return formatFileContent(entryPath, content);
    } catch (error) {
      throw new Error(`Failed to read file ${entryPath}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
