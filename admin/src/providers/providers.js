'use strict';

import pathProvider from './path';

const ngModule = angular.module(
	'providers',
	[
		pathProvider.name
	]
);

export default ngModule;
