const { capitalize } = require("./node_modules/my-string-utils");

process.argv.slice(2).forEach((it) => {
    process.stdout.write(capitalize(it) + " ");
});
