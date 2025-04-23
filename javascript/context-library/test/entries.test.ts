import { describe, it, beforeEach, afterEach, mock } from "node:test";
import assert from "node:assert";
import { loadConfig, listEntries, fetchEntryContent } from "../src/lib/entries.js";
import fs from "fs/promises";
import path from "path";
import os from "os";

// Mock the fs/promises module
mock.method(fs, "readFile");
mock.method(fs, "readdir");
mock.method(fs, "stat");
mock.method(os, "homedir", () => "/home/user");

describe("Library Entries Module", () => {
  const sampleConfig = {
    base_path: "~/repos/personal/my-software",
    entries: [
      {
        path: "go/README.md",
        description: "Documentation for Go utilities"
      },
      {
        path: "javascript/json-validator/README.md",
        description: "JSON validator documentation"
      }
    ],
    exclude_patterns: ["**/node_modules/**", "**/*.log"]
  };

  beforeEach(() => {
    // Reset mocks
    mock.reset();
  });

  describe("loadConfig", () => {
    it("should load and parse the configuration file", async () => {
      // Mock readFile to return sample config
      mock.method(fs, "readFile", async () => JSON.stringify(sampleConfig));

      const config = await loadConfig();

      assert.deepStrictEqual(config, {
        ...sampleConfig,
        base_path: "/home/user/repos/personal/my-software"
      });
    });

    it("should throw error when file cannot be read", async () => {
      // Mock readFile to throw error
      mock.method(fs, "readFile", async () => {
        throw new Error("File not found");
      });

      await assert.rejects(loadConfig, /Failed to load library entries/);
    });
  });

  describe("listEntries", () => {
    beforeEach(() => {
      // Mock readFile to return sample config
      mock.method(fs, "readFile", async () => JSON.stringify(sampleConfig));
    });

    it("should list all entries when no filter is provided", async () => {
      const result = await listEntries();

      assert.deepStrictEqual(result, {
        entries: sampleConfig.entries
      });
    });

    it("should filter entries by pattern", async () => {
      const result = await listEntries("**/README.md");

      assert.deepStrictEqual(result, {
        entries: sampleConfig.entries
      });
    });

    it("should filter entries by exclude patterns", async () => {
      const result = await listEntries(undefined, ["**/json-validator/**"]);

      assert.deepStrictEqual(result, {
        entries: [sampleConfig.entries[0]]
      });
    });
  });

  describe("fetchEntryContent", () => {
    beforeEach(() => {
      // Mock readFile to return sample config
      mock.method(fs, "readFile", async (filePath) => {
        if (filePath.toString().endsWith("library-entries.json")) {
          return JSON.stringify(sampleConfig);
        }
        if (filePath.toString().includes("README.md")) {
          return "# Sample Content";
        }
        throw new Error("File not found");
      });

      // Mock isDirectory check
      mock.method(fs, "stat", async () => ({
        isDirectory: () => false
      }));
    });

    it("should fetch and format file content", async () => {
      const content = await fetchEntryContent("go/README.md");

      assert.ok(content.includes("go/README.md"));
      assert.ok(content.includes("# Sample Content"));
    });

    it("should throw error for non-existent entry", async () => {
      await assert.rejects(fetchEntryContent("non-existent.md"), /Entry not found/);
    });

    it("should handle directory entries", async () => {
      // Mock isDirectory to return true
      mock.method(fs, "stat", async () => ({
        isDirectory: () => true
      }));

      // Mock readdir to return files
      mock.method(fs, "readdir", async () => [
        { name: "file1.txt", isDirectory: () => false },
        { name: "file2.txt", isDirectory: () => false }
      ]);

      const content = await fetchEntryContent("javascript/json-validator");

      assert.ok(content.includes("file1.txt"));
      assert.ok(content.includes("file2.txt"));
    });
  });
});
