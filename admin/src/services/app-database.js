'use strict';

import { getDatabase, ref, onValue, set, get, child, off } from 'firebase/database';

const ngModule = angular.module('services.app-database', [])

	.factory('appDatabase', function (
	) {
		let _database = null;

		const init = app => {
			_database = getDatabase();
		}

		return {
			init: init,
			ref: ref,
			set: set,
			get: get,
			child: child,
			onValue: onValue,
			off: off,
			get database() {
				return _database;
			}
		}
	})

export default ngModule;