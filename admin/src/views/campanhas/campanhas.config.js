'use strict';

var config;

var view = 'campanhas';
var controller = 'viewCampanhasController';
var requireLogin = true;

var configPath = {
	path: '/campanhas/',
	label: 'Campanhas',
	id: 'bdo2g6A5oHWWtPuDKqvN'
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
