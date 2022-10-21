'use strict';

import { getStorage, ref, uploadBytes } from 'firebase/storage';

const ngModule = angular.module('services.app-storage-helper', [])

	.factory('appStorageHelper', function () {

		const uploadFile = file => {

			const storage = getStorage();
			const storageRef = ref(storage, 'some-child');

			uploadBytes(storageRef, file).then(snapshot => {
				console.log('Uploaded a blob or file!');
			});
			
		}

		return {
			uploadFile: uploadFile
		}

	})

export default ngModule;