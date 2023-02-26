'use strict';

// import { signOut } from "@firebase/auth";

const ngModule = angular.module('services.app-auth-helper', [])

	.factory('appAuthHelper', function (
		globalFactory,
		appConfig,
		appAuth,
		$cookies,
		$q,
		$timeout,
		firebaseAuthMessages,
		waitUiFactory,
		appDatabase,
		alertFactory,
		$http,
		$window,
		$location,
		URLs
	) {

		let recaptchaVerifier,
			currentUser = null,
			authReady = false,
			widgetId = null,
			confirmationResult = null,
			reloadOnSignout = true,

			appUserData = null,

			snapshotAppUserData = null,

			unsubscribeOnAuthStateChanged,
			unsubscribeOnIdTokenChanged,

			notifyUserDataChanged = [];


		const initAppUserData = uid => {

			const path = `zoeAccount/${uid}/pf`;
			snapshotAppUserData = appDatabase.ref(appDatabase.database, path);

			refreshUserData();

			appDatabase.onValue(snapshotAppUserData, snapshot => {

				appUserData = snapshot.val() || {};

				notifyUserDataChanged.forEach(notify => {
					notify.call(appUserData);
				})

			});

		}

		const clearSessions = toLogin => {

			toLogin = typeof toLogin === 'boolean' ? toLogin : true;

			currentUser = null;
			var cookies = $cookies.getAll();

			Object.keys(cookies).forEach(function (k) {
				$cookies.remove(k);
				$window.localStorage.removeItem('idlogin');
				cookies[k] = null;
			});

			if (reloadOnSignout && toLogin) {
				redirectToIndex();
			}

		}

		const initAppUser = (cpf, celular, accountSubmitted) => {

			return $q(resolve => {

				waitUiFactory.start();

				let data = {
					cpf: cpf,
					celular: celular
				};

				if (typeof accountSubmitted === 'boolean') {
					data.accountSubmitted = accountSubmitted;
				}

				$http({
					url: URLs.user.appInit,
					method: 'post',
					headers: {
						'Authorization': 'Bearer ' + token()
					},
					data: data
				}).then(
					function () {
						setUserCookies(currentUser, _ => {
							return resolve();
						})
					},
					function (e) {
						console.error(e);
						return resolve();
					}
				);
			})

		}

		const refreshUserData = _ => {
			$http({
				url: URLs.user.account.refresh,
				method: 'get',
				headers: { 'Authorization': 'Bearer ' + token() }
			}).then(
				function () { },
				function (e) {
					console.error(e);
				}
			);
		}

		const updateUser = attrs => {

			if (!attrs.data || !attrs.data.cpf || !attrs.data.phoneNumber) {
				throw new Error('Parm error...');
			}

			let data = { ...attrs.data };
			data.dtNascimento = data.dtNascimento_yyyymmdd;

			$http({
				url: URLs.user.updateUserInfo,
				method: 'post',
				headers: {
					'Authorization': 'Bearer ' + token()
				},
				data: data
			}).then(
				function (response) {
					if (typeof attrs.success === 'function') {
						attrs.success(response.data);
					}
				},
				function (e) {
					console.error(e);
					if (typeof attrs.error === 'function') {
						attrs.error(e);
					}
				}
			);

		}

		const setUserCookies = (user, callback) => {
			user.getIdToken(true)
				.then(token => {

					if ($window.location.hostname === 'localhost') {
						console.info(token);
						console.info(`UID: ${user.uid}`);
					}

					$cookies.put('__session', token);

					if (typeof callback === 'function') {
						callback();
					}
				})
		}

		const checkTokenChange = _ => {
			const auth = appAuth.getAuth();

			unsubscribeOnIdTokenChanged = auth.onIdTokenChanged(user => {

				currentUser = user;

				if (!user) {
					clearSessions();
					if (reloadOnSignout) {
						redirectToIndex();
					}
					return;
				}

				setUserCookies(user);
			});
		}

		const token = _ => {
			const auth = appAuth.getAuth();
			return auth.currentUser.accessToken;
		}

		const redirectToIndex = _ => {

			if ($location.path() !== '/index') {
				$location.path('/index');
				$location.replace();
			}

			preloaderHide();
		}

		const _getAuth = _ => {
			return appAuth.getAuth();
		}

		const preloaderHide = _ => {
			const preloader = document.getElementById('preloader')

			if (preloader) {
				preloader.classList.add('preloader-hide');
			}
		}

		const preloaderShow = _ => {
			const preloader = document.getElementById('preloader')

			if (preloader) {
				preloader.classList.remove('preloader-hide');
			}
		}

		const signInAnonymously = _ => {
			return new Promise((resolve, reject) => {
				const auth = appAuth.getAuth();
				appAuth.signInAnonymously(auth)

					.then(signInResult => {
						return resolve(signInResult.user);
					})

					.catch((e) => {
						return reject(e);
					});
			})
		}

		const _init = _ => {
			const auth = appAuth.getAuth();

			auth.languageCode = 'BR';

			appConfig.init(_ => {

				unsubscribeOnAuthStateChanged = appAuth.onAuthStateChanged(auth, user => {

					currentUser = user;
					authReady = true;

					if (currentUser) {

						if (!currentUser.isAnonymous) {
							setUserCookies(user);
							initAppUserData(user.uid);
						}

						checkTokenChange();

					} else {

						clearSessions();

						if (reloadOnSignout) {
							redirectToIndex();
						}

						if (snapshotAppUserData) {
							appDatabase.off(snapshotAppUserData);
							snapshotAppUserData = null;
						}

					}

					if (reloadOnSignout) {
						preloaderHide();
					}

				})

			});

		}

		const _signOut = (reloadOnSignout, callback) => {

			reloadOnSignout = (typeof reloadOnSignout === 'boolean' ? reloadOnSignout : true);

			if (reloadOnSignout) {
				preloaderShow();
				unsubscribeOnAuthStateChanged();
				unsubscribeOnIdTokenChanged();
			}

			const auth = appAuth.getAuth();

			waitUiFactory.start();

			appAuth.signOut(auth)

				.then(_ => {

					clearSessions(false);

					if (reloadOnSignout) {
						$location.path('/splash');
						$location.replace();

						$window.location.reload();
					}

					if (typeof callback === 'function') {
						callback();
					}

				})

				.catch(e => {
					console.error(e);
				});
		};

		const destroyNotifyUserDataChanged = notifyUserDataChangedParm => {
			notifyUserDataChanged = notifyUserDataChanged.filter(f => {
				return r.id !== notifyUserDataChangedParm.id;
			})
		};

		const _ready = (notifyUserDataChangedParm) => {

			if (notifyUserDataChangedParm && notifyUserDataChangedParm.id && typeof notifyUserDataChangedParm.call === 'function') {
				notifyUserDataChanged.push(notifyUserDataChangedParm);
			}

			return $q(resolve => {

				const _resolve = _ => {
					if (!currentUser) {
						return resolve(null);
					} else {
						getUserClaims()
							.then(customData => {
								return resolve(Object.assign(currentUser, { customData: customData }));
							})
					}
				}

				const checkIsReady = () => {

					// Se autenticação anonima ok
					if (authReady && currentUser && currentUser.isAnonymous) {
						_resolve();
					}

					if (!authReady || (currentUser && !appUserData)) {
						$timeout(_ => {
							checkIsReady();
						}, 250);
						return;
					}

					_resolve();
				}

				checkIsReady();
			})
		};

		const initRecaptchaVerifier = attrs => {

			if (recaptchaVerifier) {
				return;
			}

			try {
				const auth = appAuth.getAuth();

				auth.useDeviceLanguage();

				recaptchaVerifier = new appAuth.RecaptchaVerifier(attrs.container, {
					"size": "invisible",
					"callback": response => {

						recaptchaVerifier.render()
							.then(wid => {
								widgetId = wid;
								if (typeof attrs.ready === 'function') {
									attrs.ready();
								}
							})
							.catch(e => {
								console.error(e);
								if (typeof attrs.error === 'function') {
									attrs.error(e);
								}
							})

					},
					"expired-callback": function () {
						console.info('expired');
						if (typeof attrs.expired === 'function') {
							attrs.expired();
						}
					},
					"error-callback": e => {
						console.error(e);
					}
				}, auth);

			} catch (e) {
				console.error(e);
				if (typeof attrs.error === 'function') {
					attrs.error(e);
				}
			}

		};

		const sendCodeToNumber = attrs => {

			if (currentUser && !currentUser.isAnonymous) {
				throw new Error('Um usuário autenticado já está logado...');
			}

			const appVerifier = recaptchaVerifier;
			const auth = appAuth.getAuth();

			attrs.celular = globalFactory.onlyNumbers(attrs.celular);

			if (!attrs.celular || attrs.celular.length !== 11) {
				if (typeof attrs.error === 'function') {
					attrs.error('Informe o número do celular com 11 dígitos...');
				}
				return;
			}

			attrs.celular = '+55' + attrs.celular;

			appAuth.signInWithPhoneNumber(auth, attrs.celular, appVerifier)
				.then(result => {
					confirmationResult = result;
					if (typeof attrs.success === 'function') {
						attrs.success();
					}
				}).catch(e => {
					if (typeof attrs.error === 'function') {
						attrs.error(e);
					}
				});

		};

		const checkCode = attrs => {

			attrs.codigo = globalFactory.onlyNumbers(attrs.codigo);

			if (!attrs.codigo || attrs.codigo.length !== 6) {
				if (typeof attrs.error === 'function') {
					attrs.error('Informe o número o código com 6 dígitos...');
				}
				return;
			}

			const auth = appAuth.getAuth();
			let user = null;
			let checkPromisse;

			if (currentUser && currentUser.isAnonymous) {
				const credential = appAuth.PhoneAuthProvider.credential(confirmationResult.verificationId, attrs.codigo);
				checkPromisse = appAuth.linkWithCredential(auth.currentUser, credential);
			} else {
				checkPromisse = confirmationResult.confirm(attrs.codigo);
			}

			return checkPromisse

				.then(confirmResult => {
					user = confirmResult.user;

					return initAppUser(attrs.cpf, attrs.celular);
				})

				.then(_ => {
					// Se o usuário já está com a submissão de conta pronta, reload...

					if (user.accountSubmitted) {
						$window.location.reload();
					}

					currentUser = user;

					setUserCookies(user, _ => {
						if (typeof attrs.success === 'function') {
							attrs.success(user);
						}
					})

				})

				.catch(e => {

					waitUiFactory.stop();

					if (e.code === 'auth/account-exists-with-different-credential') {

						alertFactory.error('Este número de celular já está vinculado à uma conta. Utilize a opção "Acesse sua Conta".').then(_ => {
							_signOut();
						})

						return;
					}

					const message = firebaseAuthMessages[e.code] || e.message;

					alertFactory.error(message);

					if (typeof attrs.error === 'function') {
						attrs.error(e);
					}

				})
		};

		const getCartosAccounts = _ => {
			return appUserData.userData?.account?.cartos?.accounts || [];
		}

		const getUserClaims = _ => {
			return new Promise((resolve, reject) => {
				currentUser.getIdTokenResult()
					.then(tokenResult => {
						return resolve(tokenResult.claims || {});
					})
					.catch(e => {
						return reject(e);
					})
			})
		}

		return {
			init: _init,
			getAuth: _getAuth,
			signOut: _signOut,
			ready: _ready,
			initRecaptchaVerifier: initRecaptchaVerifier,
			sendCodeToNumber: sendCodeToNumber,
			checkCode: checkCode,
			updateUser: updateUser,
			destroyNotifyUserDataChanged: destroyNotifyUserDataChanged,
			getCartosAccounts: getCartosAccounts,
			signInAnonymously: signInAnonymously,
			getUserClaims: getUserClaims,
			initAppUser: initAppUser,

			get token() {
				return token();
			},

			get appUserData() {
				return appUserData || null;
			},

			get currentUser() {
				return currentUser || null;
			},

			get profile() {
				return appUserData?.profile || null;
			},

			get cartosUser() {
				return appUserData?.userData?.account?.cartos?.user || false;
			},

			get emailValidated() {
				return appUserData?.userData?.account?.cartos?.user && appUserData?.userData?.account?.cartos?.status?.emailValidated === true;
			},

			get emailCanResend() {
				return appUserData?.userData?.account?.cartos?.user && appUserData?.userData?.account?.cartos?.status?.emailCanSendCode === true;
			},

			get status() {
				return appUserData?.userData?.account?.cartos?.user && appUserData?.userData?.account?.cartos ? appUserData?.userData?.account?.cartos?.status || {} : {};
			}

		}

	})

export default ngModule;