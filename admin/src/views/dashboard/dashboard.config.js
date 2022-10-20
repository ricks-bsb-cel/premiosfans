
'use strict';

var config;

var view = 'dashboard';
var controller = 'viewDashboardController';
var requireLogin = true;

var configPath = {
	path: '/dashboard/',
	label: 'Dashboard',
	id: 'Q626zGJ61SqhxtV5TwkW'
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
