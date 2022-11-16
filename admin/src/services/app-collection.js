'use strict';

const ngModule = angular.module('services.app-collection', [])

	.factory('appCollection', function (
		appFirestore,
		appFirestoreHelper,
		appAuthHelper,
		$timeout,
		globalFactory,
		appErrors,
		$q
	) {

		const instance = function (attr) {

			if (!attr || !attr.collection) {
				throw new Error('appServiceCollection parm error');
			}

			this.data = [];
			this.ready = false;
			this.empty = false;
			this.unsubscribeSnapshot = null;

			var onLoadFinishAttr = null;
			var onLoadFinishCallback = null;

			const getData = _ => {
				var result = angular.copy(this.data);
				if (onLoadFinishAttr && onLoadFinishAttr.orderBy) {
					result = globalFactory.sortArray(result, onLoadFinishAttr.orderBy);
				}
				return result;
			}

			const addWhereAsString = (q, w) => {
				if (_.isObject(w) && w.field && w.operator && typeof w.value !== 'undefined') {
					return appFirestore.query(q, appFirestore.where(w.field, w.operator, w.value));
				} else {
					var c = w.trim().split(' ');
					return appFirestore.query(q, appFirestore.where(c[0], c[1], c[2]));
				}
			}

			this.addOrUpdateDoc = (id, data) => {
				return $q((resolve, reject) => {
					const db = appFirestore.firestore;
					var command = null;

					if (data.id) delete data.id;

					if (id === 'new') {
						command = appFirestore.addDoc(appFirestore.collection(db, attr.collection), data)
					} else {
						command = appFirestore.setDoc(appFirestore.doc(db, attr.collection, id), data, { merge: true });
					}

					command
						.then(doc => {
							if (id === 'new') {
								data.id = doc.id;
							} else {
								data.id = id;
							}
							return resolve(data);
						})

						.catch(e => {
							console.error(attr.collection, e);

							return reject(e);
						})

				})
			}

			this.destroySnapshot = () => {
				onLoadFinishCallback = null;
				if (typeof this.unsubscribeSnapshot === 'function') {
					this.unsubscribeSnapshot();
				}
			}

			const finishLoad = () => {
				$timeout(() => {
					if (typeof onLoadFinishCallback === 'function') {
						onLoadFinishCallback(getData());
					}
					this.ready = true;
				})
			}

			this.startSnapshot = (parms) => {
				parms = parms || {};
				parms.loadReferences = parms.loadReferences || [];

				appAuthHelper.ready()

					.then(_ => {

						try {

							this.data = [];

							if (this.unsubscribeSnapshot) {
								this.unsubscribeSnapshot();
								console.info('Last snapshot finished...');
							}

							console.info(`New query on collection [${attr.collection}]`);
							const db = appFirestore.firestore;
							const c = appFirestore.collection(db, attr.collection);

							if (parms.id) {
								appFirestoreHelper.getDoc(attr.collection, parms.id)
									.then(d => {
										this.data.push(d);
										finishLoad();
									})
									.catch(e => {
										appErrors.showError(e, attr.collection);
									})

								return;
							}

							var q = appFirestore.query(c);

							if (attr.filterEmpresa) {
								var q = appFirestore.query(q, appFirestore.where("idEmpresa", "==", appAuthHelper.profile.user.idEmpresa));
							}

							if (parms.filter) {
								if (Array.isArray(parms.filter)) {
									parms.filter.forEach(f => {
										q = addWhereAsString(q, f);
									})
								} else {
									q = addWhereAsString(q, parms.filter);
								}
							}

							if (parms.orderBy || attr.orderBy) {
								q = appFirestore.query(q, appFirestore.orderBy(parms.orderBy || attr.orderBy));
							}

							if (parms.limit) {
								var q = appFirestore.query(q, appFirestore.limit(parms.limit));
							}

							this.unsubscribeSnapshot = appFirestore.onSnapshot(q, querySnapshot => {

								this.empty = querySnapshot.empty;

								querySnapshot.docChanges().forEach(change => {

									let doc = change.doc;
									let d = angular.merge(doc.data(), { id: doc.id });
									let references = [];

									// Remove as referencias (dá problema no AngularJS)
									// As references só podem ser usadas no BackEnd
									Object.keys(d).forEach(k => {
										if (k.includes('reference')) {
											if (parms.loadReferences.includes(k)) {
												references.push(d[k]);
											}
											delete d[k];
										}
									})

									if (change.type === 'removed') {
										this.data = this.data.filter(f => {
											return f.id !== doc.id;
										})
									} else {

										if (typeof attr.eachRow === 'function') {
											d = attr.eachRow(d);
										}

										let i = this.data.findIndex(f => {
											return f.id === doc.id;
										});

										if (i < 0) {
											i = this.data.push(d) - 1;
										} else {
											this.data[i] = d;
										}

										if (references.length) {
											this.loadReferenceOnDoc(this.data[i], references);
										}

									}

								});

								finishLoad();

							}, e => {
								appErrors.showError(e, attr.collection);
							})

						} catch (e) {
							appErrors.showError(e, attr.collection);
						}
					})
			}

			this.loadReferenceOnDoc = (doc, references) => {
				references.forEach(r => {
					appFirestore.getDoc(r)

						.then(d => {
							if (d.exists()) {
								$timeout(_ => {
									doc[d.ref.parent.path + '_reference'] = { id: d.id, ...d.data() };
								})
							}
						})

						.catch(e => {
							console.error(e);
						})
				})
			}

			this.onLoadFinish = (callback, loadFinishAttr) => {
				onLoadFinishCallback = callback;
				onLoadFinishAttr = loadFinishAttr;
				if (this.data.length > 0) {
					callback(getData());
				}
			}

			this.isReady = () => {
				return this.ready;
			}

			this.isEmpty = () => {
				return this.empty;
			}

			this.removeDoc = id => {
				appFirestoreHelper.deleteDoc(attr.collection, id);
			}

			this.query = filter => {
				const db = appFirestore.firestore;
				const c = appFirestore.collection(db, attr.collection);
				var q = appFirestore.query(c);

				if (filter) {
					if (Array.isArray(filter)) {
						filter.forEach(f => {
							q = addWhereAsString(q, f);
						})
					} else {
						q = addWhereAsString(q, filter);
					}
				}

				return appFirestoreHelper.docs(q);
			}

			if (attr.autoStartSnapshot) {
				$timeout(() => {
					this.startSnapshot();
				})
			} else {
				this.ready = true;
			}

			return this;
		}

		return instance;
	})

export default ngModule;
