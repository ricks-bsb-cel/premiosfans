'use strict';

var run = function (
	$rootScope,
	$location,
	path
) {

	$rootScope['pathProvider'] = path;

	$rootScope.showPermissionErrorMsgs = true;

	$rootScope.$on('$routeChangeStart', function (event, next) {
		if (next.controller && window.location.pathname == '/adm/pages') {
			$location.path('/default');
			event.preventDefault();
		}
	});

};

export default run;
