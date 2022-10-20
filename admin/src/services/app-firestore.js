'use strict';

import { Timestamp, getFirestore, FieldPath, query, collection, where, onSnapshot, limit, doc, getDoc, setDoc, addDoc, getDocs, orderBy, deleteDoc } from "firebase/firestore";

const ngModule = angular.module('services.app-firestore', [])

	.factory('appFirestore', function (
	) {

		let firestore = null;

		const init = app => {
			firestore = getFirestore(app);
		}

		return {
			init: init,
			doc: doc,
			collection: collection,
			where: where,
			query: query,
			getDocs: getDocs,
			setDoc: setDoc,
			deleteDoc: deleteDoc,
			Timestamp: Timestamp,
			getFirestore: getFirestore,
			onSnapshot: onSnapshot,
			limit: limit,
			getDoc: getDoc,
			addDoc: addDoc,
			orderBy: orderBy,
			get firestore() {
				return firestore;
			}
		}
	})

export default ngModule;