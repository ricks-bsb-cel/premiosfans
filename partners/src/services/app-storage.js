'use strict';

import { getStorage, ref, uploadBytes, uploadBytesResumable, getDownloadURL } from "firebase/storage";

const ngModule = angular.module('services.app-storage', [])

	.factory('appStorage', function (
	) {

		let _storage = null;

		const init = app => {
			_storage = getStorage(app);
		}

		return {
			init: init,
			ref: ref,
			uploadBytes: uploadBytes,
			uploadBytesResumable: uploadBytesResumable,
			getDownloadURL: getDownloadURL,
			get storage() {
				return _storage;
			}
		}
	})

export default ngModule;