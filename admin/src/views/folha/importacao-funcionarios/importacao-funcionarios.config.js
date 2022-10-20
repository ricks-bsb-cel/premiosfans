'use strict';

var config;

var view = 'importacao-funcionarios';
var controller = 'viewFolhaImportacaoFuncionariosController';
var requireLogin = true;

var configPath = {
	path: '/folha/importacao-funcionarios/',
	label: 'Importação de Funcionários',
	id: '6V8nfnqj58HZBodpN5lA'
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
