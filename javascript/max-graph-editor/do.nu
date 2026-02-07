const DIR = path self | path dirname

# Generate the `package.json` file.
export def package-json [] {
    cd $DIR

    let maxgraph = "0.22.0" # https://www.npmjs.com/package/@maxgraph/core
    let puppeteer = "24.37.2" # https://www.npmjs.com/package/puppeteer
    let react = "19.2.4" # https://www.npmjs.com/package/react
    let react_dom = "19.2.4" # https://www.npmjs.com/package/react-dom
    let types_react = "19.2.13" # https://www.npmjs.com/package/@types/react
    let types_react_dom = "19.2.3" # https://www.npmjs.com/package/@types/react-dom
    let typescript = "5.9.3" # https://www.npmjs.com/package/typescript

    let packageJson = {
        name: "max-graph-editor",
        version: "0.1.0",
        private: true,
        type: "module",
        dependencies: {
            "@maxgraph/core": $maxgraph,
            "puppeteer": $puppeteer,
            "react": $react,
            "react-dom": $react_dom
        },
        devDependencies: {
            "@types/react": $types_react,
            "@types/react-dom": $types_react_dom,
            "typescript": $typescript
        }
    }

    $packageJson | save --force package.json
}

export def install [] {
    cd $DIR
    bun install
}

export def build-client [] {
    cd $DIR
    bun build src/client/main.tsx --outfile public/app.js --format esm --target browser
}

export def check [] {
    cd $DIR
    bunx tsc --project tsconfig.json --noEmit
}

export def run [diagram: string, --port: int = 3000] {
    cd $DIR
    bun src/server.ts $diagram $port
}

export def server-start [diagram: string, --port: int = 3000] {
    cd $DIR
    let args = [
      "server-start"
      "--diagram" $diagram
      "--port" ($port | into string)
    ]
    run-external bun do.ts ...$args
}

export def server-stop [] {
    cd $DIR
    let args = ["server-stop"]
    run-external bun do.ts ...$args
}

export def server-status [] {
    cd $DIR
    let args = ["server-status"]
    run-external bun do.ts ...$args
}

export def server-log [] {
    cd $DIR
    let args = ["server-log"]
    run-external bun do.ts ...$args
}

export def browser-start [--mode: string = "headful", --reset-profile, --url: string = ""] {
    cd $DIR
    mut args = ["browser-start" "--mode" $mode]
    if ($url | is-not-empty) {
        $args = ($args | append ["--url" $url])
    }
    if $reset_profile {
        $args = ($args | append "--reset-profile")
    }
    run-external bun do.ts ...$args
}

export def browser-stop [] {
    cd $DIR
    let args = ["browser-stop"]
    run-external bun do.ts ...$args
}

export def browser-status [] {
    cd $DIR
    let args = ["browser-status"]
    run-external bun do.ts ...$args
}

export def screenshot [...args: string] {
    cd $DIR
    run-external bun do.ts screenshot ...$args
}

export def browser-eval [...args: string] {
    cd $DIR
    run-external bun do.ts browser-eval ...$args
}

export def screenshot-latest [] {
    cd $DIR
    let args = ["screenshot-latest"]
    run-external bun do.ts ...$args
}

export def export-mxgraph [diagram: string, --out: string = ""] {
    cd $DIR
    mut args = [
      "export-mxgraph"
      "--diagram" $diagram
    ]
    if ($out | is-not-empty) {
        $args = ($args | append ["--out" $out])
    }
    run-external bun do.ts ...$args
}

export def status [] {
    cd $DIR
    let args = ["status"]
    run-external bun do.ts ...$args
}

export def stop [] {
    cd $DIR
    let args = ["stop"]
    run-external bun do.ts ...$args
}
