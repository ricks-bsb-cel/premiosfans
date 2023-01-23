'use strict';

var view = 'cartos-accounts';
var controller = 'viewCartosAccountsController';

var configPath = {
	path: '/cartos-accounts',
	label: 'Contas Cartos',
	id: 'VpsBaTKLljlmuw63g3mx'
};

var route = {
	templateUrl: 'cartos/' + view + '/' + view + '.html',
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
