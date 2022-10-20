'use strict';

const ngModule = angular.module('services.app-collection', [])

	.factory('appCollection', function (
		appFirestore,
		appFirestoreHelper,
		appAuthHelper,
		$timeout,
		blockUiFactory,
		globalFactory,
		appErrors,
		$q
	) {

		var instance = function (attr) {

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
				if (_.isObject(w) && w.field && w.operator && w.value) {
					return appFirestore.query(q, appFirestore.where(w.field, w.operator, w.value));
				} else {
					var c = w.trim().split(' ');
					return appFirestore.query(q, appFirestore.where(c[0], c[1], c[2]));
				}
			}

			this.addOrUpdateDoc = (id, data) => {
				return $q((resolve, reject) => {
					blockUiFactory.start();

					const db = appFirestore.firestore;
					var command = null;

					if (id === 'new') {
						command = appFirestore.addDoc(appFirestore.collection(db, attr.collection), data)
					} else {
						command = appFirestore.setDoc(appFirestore.doc(db, attr.collection, id), data, { merge: true });
					}

					command
						.then(doc => {
							if (id === 'new') {
								data.id = doc.id;
							}
							blockUiFactory.stop();
							return resolve(data);
						})
						.catch(e => {
							blockUiFactory.stop();
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

			this.startSnapshot = (attrFilter) => {
				attrFilter = attrFilter || {};

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

							if (attrFilter.id) {
								appFirestoreHelper.getDoc(attr.collection, attrFilter.id)
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

							if (attrFilter.filter) {
								if (Array.isArray(attrFilter.filter)) {
									attrFilter.filter.forEach(f => {
										q = addWhereAsString(q, f);
									})
								} else {
									q = addWhereAsString(q, attrFilter.filter);
								}
							}

							if (attrFilter.orderBy || attr.orderBy) {
								q = appFirestore.query(q, appFirestore.orderBy(attrFilter.orderBy || attr.orderBy));
							}

							if (attrFilter.limit) {
								var q = appFirestore.query(q, appFirestore.limit(attrFilter.limit));
							}

							this.unsubscribeSnapshot = appFirestore.onSnapshot(q, querySnapshot => {

								this.empty = querySnapshot.empty;

								querySnapshot.docChanges().forEach(change => {

									let doc = change.doc;
									let d = angular.merge(doc.data(), { id: doc.id });

									// Remove as referencias (dá problema no AngularJS)
									// As references só podem ser usadas no BackEnd
									Object.keys(d).forEach(k => {
										if (k.includes('reference')) { delete d[k]; }
									})

									if (change.type === 'removed') {
										this.data = this.data.filter(f => {
											return f.id !== doc.id;
										})
									} else {

										if (typeof attr.eachRow === 'function') {
											d = attr.eachRow(d);
										}

										var i = this.data.findIndex(f => { return f.id === doc.id; });

										if (i < 0) {
											this.data.push(d);
										} else {
											this.data[i] = d;
										}

									}

								});

								finishLoad();

							}, e => {
								appErrors.showError(e, attr.collection);
							})

						} catch (e) {
							debugger;
							appErrors.showError(e, attr.collection);
						}
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

			this.removeFakeData = (idEmpresa, confirm, callback) => {
				var self = this;

				const deleteAll = function () {
					toastrFactory.info('Removendo dados de teste da collection [' + self.collection + ']...');

					const db = appFirestore.firestore;
					const collection = appFirestore.collection(db, self.collection);

					var total = 0;
					var clientes = null;

					const deleteNextFakeDocs = function () {

						var query = appFirestoreHelper.query(collection, 'idEmpresa', '==', idEmpresa);
						query = appFirestoreHelper.query(query, 'isFakeData', '==', true);
						query = appFirestore.query(query, appFirestore.limit(10));

						appFirestoreHelper.docs(query)

							.then(docs => {
								clientes = docs;
								if (clientes.length === 0) {
									return true;
								} else {
									var deleteClientes = [];
									clientes.forEach(c => {
										deleteClientes.push(appFirestore.deleteDoc(appFirestore.doc(firestore, self.collection, c.id)));
										total++;
									});
									return Promise.all(deleteClientes);
								}
							})

							.then(_ => {
								if (clientes.length === 0) {
									toastrFactory.success(total + " registros de teste foram removidos da collection [" + self.collection + "]");
									if (typeof callback == 'function') {
										callback();
									}
								} else {
									deleteNextFakeDocs();
								}
							})

							.catch(e => {
								console.error(e);
							})

					}

					deleteNextFakeDocs();
				}

				if (!confirm) {
					deleteAll();
				} else {
					alertFactory.yesno('Tem certeza que deseja remover as informações de teste?').then(function () {
						deleteAll();
					})
				}
			}

			this.removeDoc = id => {
				appFirestoreHelper.deleteDoc(attr.collection, id);
			}

			this.query = filter => {
				const db = appFirestore.firestore;
				const c = appFirestore.collection(db, attr.collection);
				var q = appFirestore.query(c);

				if (Array.isArray(filter)) {
					filter.forEach(f => {
						q = addWhereAsString(q, f);
					})
				} else {
					q = addWhereAsString(q, filter);
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
