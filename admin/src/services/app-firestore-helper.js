'use strict';

const ngModule = angular.module('services.firestore-helper', [])

	.service('appFirestoreHelper', function (
		$q,
		appFirestore,
		firebaseErrorCodes,
		alertFactory
	) {

		const currentTimestamp = () => {
			return appFirestore.Timestamp.now();
		}

		const startTimestamp = () => {
			return appFirestore.Timestamp.fromDate(new Date(2000, 0, 1));
		}

		const toTimestamp = (value) => {
			return appFirestore.Timestamp.fromDate(value);
		}

		const collection = c => {
			return appFirestore.collection(appFirestore.firestore, c);
		}

		const doc = (c, id) => {
			return appFirestore.doc(appFirestore.firestore, c, id);
		}

		const deleteDoc = (c, id) => {
			appFirestore.deleteDoc(appFirestore.doc(appFirestore.firestore, c, id));
		}

		const docs = q => {
			return $q(function (resolve, reject) {
				appFirestore.getDocs(q)
					.then(data => {
						var result = [];
						data.forEach(d => {
							result.push(angular.merge(d.data(), { id: d.id }));
						})
						return resolve(result);
					})
					.catch(e => {
						showError(e, q.path);
						return reject(e);
					})
			})
		}

		const getDoc = (c, id) => {
			return $q((resolve, reject) => {

				if (typeof c === 'string' && id) {
					c = doc(c, id);
				}

				appFirestore.getDoc(c)
					.then(d => {
						if (d.exists()) {
							return resolve(angular.merge(d.data(), { id: d.id }));
						} else {
							return resolve(null);
						}
					})
					.catch(e => {
						if (e.code === 'permission-denied') {
							console.error(`Permission denied: ${c.path}`);
						} else {
							console.error(e);
						}
						return reject(e);
					})
			})
		}

		const getSubCollection = (c, id, s) => {
			var _c = appFirestore.collection(appFirestore.firestore, c, id, s);
			var _q = appFirestore.query(_c);
			return docs(_q);
		}

		const query = (c, w, o, v) => {
			return appFirestore.query(c, appFirestore.where(w, o, v));
		}

		const showError = (e, title) => {
			console.error(e);
			var i = firebaseErrorCodes.findIndex(f => { return e.code && f.error === e.code; })
			if (i >= 0) {
				alertFactory.error(firebaseErrorCodes[i].detalhes, title);
			} else if (e.message) {
				alertFactory.error(e.message, title);
			} else {
				alertFactory.error('Erro indeterminado...', title);
			}
		}

		const removeReferences = doc => {
			try {
				let value = angular.copy(doc || {});
				Object.keys(value).forEach(k => {
					if (value[k] &&
						typeof value[k] === 'object' &&
						value[k].constructor &&
						value[k].constructor.name === 'va'
					) {
						delete value[k];
					}
				});
				return value;
			} catch (e) {
				console.error(e);
			}
		}

		return {
			currentTimestamp: currentTimestamp,
			startTimestamp: startTimestamp,
			toTimestamp: toTimestamp,
			doc: doc,
			docs: docs,
			getDoc: getDoc,
			query: query,
			collection: collection,
			getSubCollection: getSubCollection,
			removeReferences: removeReferences,
			deleteDoc: deleteDoc
		}

	})

export default ngModule;
