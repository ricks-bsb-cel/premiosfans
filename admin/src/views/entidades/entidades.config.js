'use strict';

var config;

var view = 'entidades';
var controller = 'viewEntidadesController';
var requireLogin = true;

var configPath = {
	path: '/entidades/',
	label: 'Cadastro de Entidades',
	id: null
};

var route = {
	templateUrl: 'entidades/entidades.html',
	controller: controller,
	requireLogin: requireLogin,
	configPath: configPath
};

config = function (
	$routeProvider,
	pathProvider
) {
	const pathObj = pathProvider.addPath(
		view,
		configPath
	);

	$routeProvider.when(pathObj.path + ':type', route);
};

export default config;
