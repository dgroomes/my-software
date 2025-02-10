import esbuild from "esbuild";

await esbuild.build({
    entryPoints: ["main.ts"],
    bundle: true,

    // Obsidian's runtime environment includes a number of packages. If our plugin happens to use a package that is
    // already in Obsidian's runtime, then we need to make sure to not bundle that package in our plugin distribution.
    // It's undesirable to bundle the same package multiple times in the same program.
    //
    // Unfortunately, there isn't really a canonical list of these packages. The best we can do is just periodically
    // check the esbuild config of the official example project: https://github.com/obsidianmd/obsidian-sample-plugin/blob/6d09ce3e39c4e48d756d83e7b51583676939a5a7/esbuild.config.mjs#L20
    // and recreate that.
    external: [
        "obsidian",
        "electron",
        "@codemirror/autocomplete",
        "@codemirror/collab",
        "@codemirror/commands",
        "@codemirror/language",
        "@codemirror/lint",
        "@codemirror/search",
        "@codemirror/state",
        "@codemirror/view",
        "@lezer/common",
        "@lezer/highlight",
        "@lezer/lr"
    ],
    format: "cjs",
    target: "es2022",
    sourcemap: "external",
    outfile: "dist/main.js"
}); 