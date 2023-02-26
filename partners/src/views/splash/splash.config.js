'use strict';

var config;

var view = 'splash';
var controller = 'viewSplashController';

var configPath = {
	path: '/splash/',
	label: 'splash'
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

	var pathObj = pathProvider.addPath(view, configPath);
	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
