'use strict';

import { getStorage, ref, uploadBytes } from 'firebase/storage';

const ngModule = angular.module('services.app-storage', [])

	.factory('appStorage', function () {

		return {
			getStorage: getStorage,
			ref: ref,
			uploadBytes: uploadBytes
		}
	})

export default ngModule;