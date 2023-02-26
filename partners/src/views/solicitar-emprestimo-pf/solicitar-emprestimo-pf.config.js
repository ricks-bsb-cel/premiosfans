'use strict';

var view = 'solicitar-emprestimo-pf';
var controller = 'viewSolicitarEmprestimoPFController';

var configPath = {
	path: '/solicitar-emprestimo-pf',
	label: 'solicitar-emprestimo-pf'
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
