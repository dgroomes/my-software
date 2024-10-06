/*
This script generates the `package.json` files for this project. Run it with `node package-json.mjs` or `./package-json.mjs`.
*/

import fs from "fs";

const versions = {
    ajv: "~8.17.1", // AJV releases: https://github.com/ajv-validator/ajv/releases
    typescript: "~5.6", // TypeScript releases: https://github.com/Microsoft/TypeScript/releases
    tsLoader: "~9.5.1", // ts-loader releases: https://github.com/TypeStrong/ts-loader/blob/main/CHANGELOG.md
    webpack: "~5.95.0", // webpack releases: https://github.com/webpack/webpack/releases
};

/**
 * Generate a 'package.json' file.
 *
 * @param dryRun If true, the 'package.json' file will not be written.
 * @param packageJsonContent The content of the 'package.json' file, as a JavaScript object.
 */
function generatePackageJson(dryRun, packageJsonContent) {
    const packageJsonString = JSON.stringify(packageJsonContent, null, 2) + "\n";
    const path = "package.json";

    console.log(`Writing 'package.json' file to '${path}'...`);
    if (dryRun) {
        console.log("DRY RUN. File not written.");
        return;
    }

    fs.writeFile(path, packageJsonString, (err) => {
        if (err) throw new Error(`Failed to write 'package.json' file to '${path}': ${err}`);
    });
}

generatePackageJson( false, {
    name: "my-software",
    version: "0.1.0",
    description: "My JavaScript code",
    scripts: {
        "build": "webpack"
    },
    license: "UNLICENSED",
    dependencies: {
        "ajv": versions.ajv,
    },
    devDependencies: {
        "ts-loader": versions.tsLoader,
        typescript: versions.typescript,
        webpack: versions.webpack
    },
});
