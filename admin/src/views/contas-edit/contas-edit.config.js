'use strict';

var config;

var view = 'contas-edit';
var controller = 'viewContasEditController';
var requireLogin = true;

var configPath = {
	path: '/contas-edit/',
	label: 'Edição de Conta',
	id: 'SLbeGiz4toiyWBrIIciz'
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

	$routeProvider.when(path + ':id', route);
};

export default config;
