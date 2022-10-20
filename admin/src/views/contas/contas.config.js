'use strict';

var config;

var view = 'contas';
var controller = 'viewContasController';
var requireLogin = true;

var configPath = {
	path: '/contas/',
	label: 'contas',
	id: '3ujuC11vFSA9tnFYOe7U'
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

	/*
	if (!window.location.pathname.startsWith('/adm/home')) {
		return;
	}
	*/

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
