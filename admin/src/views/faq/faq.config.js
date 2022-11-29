'use strict';

var config;

var view = 'faq';
var controller = 'viewFaqController';
var requireLogin = true;

var configPath = {
	path: '/faq',
	label: 'FAQ',
	id: 'QOPqYCIt7qu0D9gKB51c'
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
