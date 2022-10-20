
'use strict';

var config;

var view = 'api-config';
var controller = 'viewApiConfigController';
var requireLogin = true;

var configPath = {
	path: '/api-config/',
	label: 'Configuração da API',
	id: 'MZwnN4ybhDa68YPmI0iW'
};

var route = {
	templateUrl: `${view}/${view}.html`,
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
