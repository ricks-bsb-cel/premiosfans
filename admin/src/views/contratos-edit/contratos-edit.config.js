'use strict';

var config;

var view = 'contratos-edit';
var controller = 'viewContratosEditController';
var requireLogin = true;

var configPath = {
	path: '/contratos-edit/',
	label: 'Edição de Contrato',
	id: 'AbpDMaJFc8BMUyNx0aPt'
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

	$routeProvider.when(path + ':id/:edit?', route);
};

export default config;
