'use strict';

var config;

var view = 'transacoes';
var controller = 'viewTransacoesController';
var requireLogin = true;

var configPath = {
	path: '/transacoes/',
	label: 'transacoes',
	id: 'YKIPr7Pah7un2MQT1daT'
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

	/*
	if (!window.location.pathname.startsWith('/adm/home')) {
		return;
	}
	*/

	var pathObj = pathProvider.addPath(
		view,
		configPath
	);

	var path = pathObj.path;

	$routeProvider.when(path, route);

};

export default config;
