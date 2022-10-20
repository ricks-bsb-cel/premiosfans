'use strict';

var config;

var view = 'contratos';
var controller = 'viewContratosController';
var requireLogin = true;

var configPath = {
	path: '/contratos/',
	label: 'Contratos',
	id: 'bdo2g6A5oHWWtPuDKqvN'
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

	$routeProvider.when(path + ':idCliente?', route);

};

export default config;
