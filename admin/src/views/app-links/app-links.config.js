'use strict';

var view = 'app-links';
var controller = 'viewAppLinksController';

var configPath = {
	path: '/app-links/',
	label: 'AppLinks',
	id: 'ibLhTUSYV1tJOWCqttw0'
};

var route = {
	templateUrl: view + '/' + view + '.html',
	controller: controller,
	configPath: configPath
};

const config = function (
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
