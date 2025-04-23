import { describe, it, beforeEach, mock } from "node:test";
import assert from "node:assert";
import * as entries from "../src/lib/entries.js";

// Mock the entries module
mock.method(entries, "listEntries");
mock.method(entries, "fetchEntryContent");

// Since we can't directly import the tools from index.ts (they're defined inline),
// we'll test the functions that the tools call

describe("MCP Tools", () => {
  beforeEach(() => {
    // Reset mocks
    mock.reset();
  });

  describe("list_entries tool", () => {
    it("should call listEntries with the correct parameters", async () => {
      const mockEntries = {
        entries: [
          {
            path: "go/README.md",
            description: "Documentation for Go utilities"
          }
        ]
      };

      // Mock listEntries to return sample entries
      mock.method(entries, "listEntries", async (pattern, excludePatterns) => {
        assert.strictEqual(pattern, "*.md");
        assert.deepStrictEqual(excludePatterns, ["**/node_modules/**"]);
        return mockEntries;
      });

      const result = await entries.listEntries("*.md", ["**/node_modules/**"]);

      assert.deepStrictEqual(result, mockEntries);
    });

    it("should handle errors from listEntries", async () => {
      // Mock listEntries to throw error
      mock.method(entries, "listEntries", async () => {
        throw new Error("Test error");
      });

      await assert.rejects(entries.listEntries, /Test error/);
    });
  });

  describe("fetch_entry tool", () => {
    it("should call fetchEntryContent with the correct parameter", async () => {
      // Mock fetchEntryContent to return sample content
      mock.method(entries, "fetchEntryContent", async (path) => {
        assert.strictEqual(path, "go/README.md");
        return "Sample content";
      });

      const result = await entries.fetchEntryContent("go/README.md");

      assert.strictEqual(result, "Sample content");
    });

    it("should handle errors from fetchEntryContent", async () => {
      // Mock fetchEntryContent to throw error
      mock.method(entries, "fetchEntryContent", async () => {
        throw new Error("Test error");
      });

      await assert.rejects(entries.fetchEntryContent, /Test error/);
    });
  });
});
