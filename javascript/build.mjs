import webpack from 'webpack';
import config from './webpack.config.mjs';

webpack(config, (err, stats) => {
    if (err || stats.hasErrors()) {
        console.error(err || stats.toJson().errors);
        process.exit(1);
    }
    console.log(stats.toString({
        colors: true,
        modules: false,
        children: false,
        chunks: false,
        chunkModules: false
    }));
});
