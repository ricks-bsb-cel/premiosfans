'use strict';

var config;

var view = 'importacoes';
var controller = 'viewFolhaImportacoesController';
var requireLogin = true;

var configPath = {
	path: '/folha/importacoes/',
	label: 'Importações',
	icon: 'fas fa-code',
	id: 'SWFUkD45d21JjmJAGcCF'
};

var route = {
	templateUrl: `folha/${view}/${view}.html`,
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
