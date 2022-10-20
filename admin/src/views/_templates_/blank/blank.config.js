'use strict';

var config;

var view = 'blank';
var controller = 'viewBlankController';
var requireLogin = true;

var configPath = {
	path: '/blank/',
	label: 'Blank Page Demo',
	icon: 'fas fa-code',
	id: 'wVYRs4nHrCbbdXgjm44r'
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
