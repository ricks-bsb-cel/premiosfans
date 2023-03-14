const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require("terser-webpack-plugin");
const webpack = require('webpack');

var production = false;

console.info(`on ${production ? 'Production' : 'Dev'}...`);

const rules = [
	{
		test: /\.js$/,
		exclude: /node_modules/,
		use: {
			loader: 'babel-loader'
		}
	},

	{
		test: /[\\/](assets|src)[\\/].*?\.(woff2?|ttf|otf|eot|jpg|png|svg|mp3|mp4)$/,
		loader: 'file-loader',
		options: {
			name: '[name].[hash].[ext]',
			outputPath: '/'
		}
	},

	{
		test: /[\\/]src[\\/]directives[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=clienteLoginAppTemplates&relativeTo=src/directives/' },
			{ loader: 'html-loader' }
		]
	},

	{
		test: /[\\/]src[\\/]factories[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=clienteLoginAppTemplates&relativeTo=src/factories/' },
			{ loader: 'html-loader' }
		]
	},

	{
		test: /[\\/]src[\\/]services[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=clienteLoginAppTemplates&relativeTo=src/services/' },
			{ loader: 'html-loader' }
		]
	},

	{
		test: /[\\/]src[\\/]views[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=clienteLoginAppTemplates&relativeTo=src/views/' },
			{ loader: 'html-loader' }
		]
	},

	{
		test: /[\\/]src[\\/]formly[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=clienteLoginAppTemplates&relativeTo=src/formly/' },
			{ loader: 'html-loader' }
		]
	},

	// sass
	{
		test: /\.scss$/,
		use: [
			MiniCssExtractPlugin.loader,
			{
				loader: 'css-loader',
				options: {
					sourceMap: !production
				}
			},
			{
				loader: 'resolve-url-loader',
				options: {
					sourceMap: !production,
					root: path.resolve(__dirname, './')
				}
			},
			{
				loader: 'sass-loader',
				options: {
					sourceMap: !production,
					sassOptions: {
						outputStyle: production ? 'compressed' : 'nested'
					}
				}
			}
		]
	},

	// css
	{
		test: /\.css$/,
		use: [
			MiniCssExtractPlugin.loader,
			{
				loader: 'css-loader',
				options: {
					sourceMap: !production,
					url: false
				}
			}
		]
	}

	/*
	{
		test: /.node$/,
		use: 'node-loader'
	}

	{
		test: /\.css$/,
		use: [
			MiniCssExtractPlugin.loader,
			{
				loader: 'css-loader',
				options: {
					sourceMap: !production,
					url: false
				}
			}
		]
	},
	*/

];

module.exports = [
	{
		// target: 'node',
		entry: './src/index.js',
		optimization: {
			minimize: production,
			minimizer: [
				new TerserPlugin({
					terserOptions: {
						sourceMap: !production,
						mangle: false,
						compress: {
							drop_console: production
						}
					},
					extractComments: production
				})
			],
		},
		output: {
			filename: 'bundle.js',
			path: path.resolve(__dirname, '../public/partners'),
			publicPath: 'partners/assets'
		},
		devtool: production ? false : 'source-map',
		performance: {
			hints: false
		},
		plugins: [
			new webpack.ProvidePlugin({
				Buffer: ['buffer', 'Buffer'],
				moment: path.resolve(path.join(__dirname, 'node_modules/moment'))
			}),
			new MiniCssExtractPlugin({
				filename: 'bundle.css'
			})
			/*
			new webpack.ProvidePlugin({
				process: 'process/browser',
			})
			*/
		],
		/*
		resolve: {
			extensions: ['.ts', '.js'],
			fallback: {
				"stream": require.resolve("stream-browserify"),
				"buffer": require.resolve("buffer"),
				"path": require.resolve("path-browserify")
			}
		},
		*/
		module: {
			rules: rules
		},
		mode: production ? 'production' : 'development'
	}
];