import path from "path"

export default {
    stats: {
        logging: "verbose",
    },
    infrastructureLogging: {
        level: "verbose",
    },
    mode: 'development',
    entry: './src/main.ts',
    module: {
        rules: [{
            test: /\.tsx?$/, use: 'ts-loader', exclude: /node_modules/,
        },],
    },
    devtool: 'inline-source-map',
    output: {
        filename: '[name].bundle.js', path: path.resolve('dist'), clean: true,
    },
    resolve: {
        extensions: [".ts", ".js"],
    }
};
