'use strict';

var view = 'account-open-send';
var controller = 'viewAccountOpenSendController';

var configPath = {
	path: '/account-open-send/:type/:id',
	label: 'account-open-send'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

var config = function (
	$routeProvider,
	pathProvider
) {
	var pathObj = pathProvider.addPath(view, configPath);
	var path = pathObj.path;

	$routeProvider.when(path, route);
};

export default config;
