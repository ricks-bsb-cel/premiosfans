'use strict';

var config;

var view = 'usuarios';
var controller = 'viewUsuariosController';

var configPath = {
	path: '/usuarios/',
	label: 'Usuários',
	id: 'wbrLGPnBAFIZRrAnxI1c'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {

	/*
	if (!window.location.pathname.startsWith('/adm/home')) {
		return;
	}
	*/

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	$routeProvider.when(pathObj.path, route);

};

export default config;
