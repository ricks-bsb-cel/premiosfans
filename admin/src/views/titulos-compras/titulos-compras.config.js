'use strict';

var view = 'titulos-compras';
var controller = 'viewTitulosComprasController';

var configPath = {
	path: '/titulos-compras/',
	label: 'Títulos Compras',
	id: 'YR9WSUctRMT7HaAZ9PfH'
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

	$routeProvider.when(path + ':idCampanha?', route);

};

export default config;
