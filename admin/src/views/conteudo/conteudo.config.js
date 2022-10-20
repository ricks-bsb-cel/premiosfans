'use strict';

var config;

var view = 'conteudo';
var controller = 'viewConteudoController';
var requireLogin = true;

var configPath = {
	path: '/conteudo/',
	id: 'HABUMcnh41MkGwYSTVKM'
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
