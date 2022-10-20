
'use strict';

var config;

var view = 'planos';
var controller = 'viewPlanosController';
var requireLogin = true;

var configPath = {
	path: '/planos/',
	label: 'Planos',
	id: '3iZqvTpCgHdLEty3juep'
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
