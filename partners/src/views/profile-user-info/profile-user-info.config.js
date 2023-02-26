'use strict';

var view = 'profile-user-info';
var controller = 'viewProfileUserInfoController';

var configPath = {
	path: '/profile-user-info/',
	label: 'profile-user-info'
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
