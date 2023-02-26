'use strict';

var view = 'account-info';
var controller = 'viewAccountInfoController';

var configPath = {
	path: '/account-info/:personId',
	label: 'account-info'
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

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
