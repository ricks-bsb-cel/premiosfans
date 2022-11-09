module.exports = {
	"root": true,
	"parserOptions": {
		"ecmaVersion": 2018
	},
	"env": {
		"es6": true,
		"node": true,
	},
	"extends": [
		"eslint:recommended",
		"google",
	],
	"rules": {
		"quotes": 0,
		"no-tabs": 0,
		"allowIndentationTabs": 0,
		"arraysInObjects": 0,
		"indent": "off",
		"object-curly-spacing": [2, "always"],
		'max-len': ["error", { "code": 1024 }],
		"semi": 0,
		"comma-dangle": 0,
		"one-var": 0,
		"arrow-parens": 0,
		"padded-blocks": 0,
		"space-before-function-paren": 0,
		"brace-style": 0,
		"block-spacing": 0,
		"require-jsdoc": 0,
		"valid-jsdoc": 0,
		"no-useless-escape": 0,
		"no-control-regex": 0,
		"new-cap": 0,
		"camelcase": 0,
		"no-undef": 0,
		"no-trailing-space": 0
	},
};
