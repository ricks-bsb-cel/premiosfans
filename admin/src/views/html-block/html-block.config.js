'use strict';

var config;

var view = 'html-block';
var controller = 'viewHtmlBlockController';
var requireLogin = true;

var configPath = {
	path: '/html-block/',
	id: 'cHC1tL3romOos8undO5Q'
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
