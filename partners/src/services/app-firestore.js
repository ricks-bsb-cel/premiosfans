'use strict';

import { Timestamp, getFirestore, doc, onSnapshot, collection, query, where, limit, getDocs } from "firebase/firestore";

const ngModule = angular.module('services.app-firestore', [])

	.factory('appFirestore', function (
	) {

		let _firestore = null;

		const init = app => {
			_firestore = getFirestore(app);
		}

		return {
			init: init,
			Timestamp: Timestamp,
			getFirestore: getFirestore,
			doc: doc,
			onSnapshot: onSnapshot,
			collection: collection,
			query: query,
			getDocs: getDocs,
			where: where,
			limit: limit,
			get firestore() {
				return _firestore;
			}
		}
	})

export default ngModule;