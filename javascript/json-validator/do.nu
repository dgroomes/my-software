const DIR = (path self | path dirname)

# Generate the `package.json` file.
# 
# Generating the `package.json` file like this allows me a place to put comments. Node infamously doesn't support
# comments in the `package.json` file.
# 
# In particular, I really like commenting the URLs of the changelog pages for the packages I depend on. 
export def package-json [] {
    cd $DIR

    let ajv = "~8.17.1" # AJV releases: https://github.com/ajv-validator/ajv/releases
    let typescript = "~5.6" # TypeScript releases: https://github.com/Microsoft/TypeScript/releases
    let tsLoader = "~9.5.1" # ts-loader releases: https://github.com/TypeStrong/ts-loader/blob/main/CHANGELOG.md
    let webpack = "~5.95.0" # webpack releases: https://github.com/webpack/webpack/releases

    let packageJson = {
        name: "my-software",
        version: "0.1.0",
        description: "My JavaScript code"
        license: "UNLICENSED"
        dependencies: {
            "ajv": $ajv
        }
        devDependencies: {
            "ts-loader": $tsLoader
            "typescript": $typescript
            "webpack": $webpack
        }
    }

    $packageJson | save -f package.json
}

# npm install
export def install [] {
    cd $DIR
    npm install
}

export def build [] {
    cd $DIR
    node build.mjs
}

export def run [] {
    cd $DIR
    node dist/main.bundle.js
}
