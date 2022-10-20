'use strict';

var config;

var view = 'crud';
var controller = 'viewCrudController';
var requireLogin = true;

var configPath = {
	path: '/crud/',
	id: '4aokDbUmG4Ah1XOw9txv'
};

var route = {
	templateUrl: `_templates_/${view}/${view}.html`,
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
