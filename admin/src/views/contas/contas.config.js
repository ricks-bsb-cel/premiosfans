'use strict';

var config;

var view = 'contas';
var controller = 'viewContasController';
var requireLogin = true;

var configPath = {
	path: '/contas/',
	label: 'Contas',
	id: 'DQldWbAOMxudYSZOBwio'
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
