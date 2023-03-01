'use strict';

// import { signOut } from "@firebase/auth";

const ngModule = angular.module('services.app-auth-helper', [])

	.factory('appAuthHelper', function (
		appConfig,
		appAuth,
		$cookies,
		$q,
		$timeout,
		waitUiFactory,
		$http,
		$window,
		$location,
		URLs
	) {

		let currentUser = null,
			authReady = false,
			reloadOnSignout = true,
			lastToken = null,

			appUserData = null,

			unsubscribeOnAuthStateChanged,
			unsubscribeOnIdTokenChanged,

			notifyUserDataChanged = [];

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

		const setUserCookies = (user, callback) => {
			if (!user) return;

			user.getIdToken(true).then(token => {

				if (lastToken !== token) {
					if ($window.location.hostname === 'localhost') {
						console.group('User');
						console.log('Token', token);
						console.log(`UID: ${user.uid}`);
						console.groupEnd();
					}

					$cookies.put('__session', token);

					lastToken = token;
				}

				typeof callback === 'function' && callback(token);
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

		const redirectToIndex = hidePreloader => {

			hidePreloader = typeof hidePreloader === 'boolean' ? hidePreloader : true;

			if ($location.path() !== '/index') {
				$location.path('/index');
				$location.replace();
			}

			hidePreloader && preloaderHide();
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
							clearSessions();

							return _signOut(true);
						}

						setUserCookies(user);
						checkTokenChange();
						preloaderHide();

						return;
					}

					appAuth.signInAnonymously(auth);
				})
			});

		}

		const _signOut = (reloadOnSignout, callback) => {

			reloadOnSignout = (typeof reloadOnSignout === 'boolean' ? reloadOnSignout : true);

			if (reloadOnSignout) {
				preloaderShow();
				typeof unsubscribeOnAuthStateChanged === 'function' && unsubscribeOnAuthStateChanged();
				typeof unsubscribeOnIdTokenChanged === 'function' && unsubscribeOnIdTokenChanged();
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
			destroyNotifyUserDataChanged: destroyNotifyUserDataChanged,
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