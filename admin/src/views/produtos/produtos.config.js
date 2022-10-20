'use strict';

var config;

var view = 'produtos';
var controller = 'viewProdutosController';
var requireLogin = true;

var configPath = {
	path: '/produtos/',
	label: 'Produtos',
	id: 'H0QBd7rgbsaApsazEQbS'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	requireLogin: requireLogin,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {
	var pathObj = pathProvider.addPath(
		view,
		configPath
	);
		
	var path = pathObj.path;

	$routeProvider.when(path, route);
};

export default config;
