'use strict';

import { getFunctions, httpsCallable } from "firebase/functions";

const ngModule = angular.module('services.app-functions', [])

	.factory('appFunctions', function () {

		return {
			getFunctions: getFunctions,
			httpsCallable: httpsCallable
		}
	})

export default ngModule;