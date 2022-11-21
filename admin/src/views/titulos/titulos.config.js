'use strict';

var view = 'titulos';
var controller = 'viewTitulosController';

var configPath = {
	path: '/titulos/',
	label: 'Títulos',
	id: 'UkjLFCPp028syEFe3Xs2'
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
