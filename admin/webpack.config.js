const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require("terser-webpack-plugin");
const webpack = require('webpack');

var production = true;

console.info(`on ${production ? 'Production' : 'Dev'}...`);

let sassOptions = {sourceMap: !production};

if(production){
	sassOptions.sassOptions= {
		outputStyle: production ? 'compressed' : 'none'
	};
}

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
			outputPath: (url, resourcePath) => {
				return resourcePath.replace(/^.+[\\/](assets|src)(.+[\\/]).*?$/, `/assets$2${url}`).replace(/\\/g, '/');
			}
		}
	},
	{
		test: /[\\/]src[\\/]directives[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=adminAppTemplates&relativeTo=src/directives/' },
			{ loader: 'html-loader' }
		]
	},
	{
		test: /[\\/]src[\\/]factories[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=adminAppTemplates&relativeTo=src/factories/' },
			{ loader: 'html-loader' }
		]
	},
	{
		test: /[\\/]src[\\/]services[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=adminAppTemplates&relativeTo=src/services/' },
			{ loader: 'html-loader' }
		]
	},
	{
		test: /[\\/]src[\\/]views[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=adminAppTemplates&relativeTo=src/views/' },
			{ loader: 'html-loader' }
		]
	},
	{
		test: /[\\/]src[\\/]formly[\\/].+\.html$/,
		use: [
			{ loader: 'ngtemplate-loader?module=adminAppTemplates&relativeTo=src/formly/' },
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
				options: sassOptions
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
	},

];

module.exports = [
	{
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
			path: path.resolve(__dirname, '../public/adm/dist'),
			publicPath: 'dist/'
		},
		devtool: production ? false : 'source-map',
		performance: {
			hints: false
		},
		plugins: [
			new webpack.ProvidePlugin({
				moment: path.resolve(path.join(__dirname, 'node_modules/moment'))
			}),
			new MiniCssExtractPlugin({
				filename: 'bundle.css'
			})
		],
		module: {
			rules: rules
		},
		mode: production ? 'production' : 'development'
	}
];