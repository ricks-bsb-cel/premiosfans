
'use strict';

var config;

var view = 'influencers';
var controller = 'viewInfluencersController';
var requireLogin = true;

var configPath = {
	path: '/influencers/',
	label: 'Influencers',
	id: 'ydJuj0UyCo8ZUzdXZPn6'
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
