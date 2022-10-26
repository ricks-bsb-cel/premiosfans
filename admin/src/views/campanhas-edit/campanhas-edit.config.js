'use strict';

var config;

var view = 'campanhas-edit';
var controller = 'viewCampanhasEditController';
var requireLogin = true;

var configPath = {
	path: '/campanhas-edit/',
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
