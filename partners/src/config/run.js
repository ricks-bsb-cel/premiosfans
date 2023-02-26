'use strict';

var run = function (
	$rootScope,
	path,
	waitUiFactory,
	footerBarFactory,
	$location
) {

	footerBarFactory.hide();

	$rootScope['pathProvider'] = path;

	$rootScope.$on("$routeChangeStart",
		function (event, next, current) {
			waitUiFactory.show();
			footerBarFactory.hide();
		})

	const body = angular.element(document.body);

	if (window.localStorage.currentTheme === 'dark') {
		body.removeClass('theme-light').addClass('theme-dark');
	}

	if (!$location.path()) {
		$location.path('/splash');
		$location.replace();
	}

};

export default run;
