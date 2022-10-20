'use strict';
/* global grecaptcha */

const ngModule = angular.module('services.app-auth-helper', [])

	.factory('appAuthHelper', function (
		globalFactory,
		appConfig,
		appErrors,
		appAuth,
		appDatabaseHelper,
		$rootScope,
		$cookies,
		$http,
		$q,
		URLs,
		alertFactory,
		blockUiFactory,
		$timeout,
		$window
	) {

		var currentUser = null;
		var userProfile = null;
		var authReady = false;

		const clearSessions = () => {
			currentUser = null;
			userProfile = null;

			var cookies = $cookies.getAll();

			Object.keys(cookies).forEach(function (k) {
				$cookies.remove(k);
				cookies[k] = null;
			});
		}

		const setUserCookies = user => {
			console.info(user.accessToken);
			$cookies.put('__session', user.accessToken);
		}

		const checkTokenChange = () => {
			const auth = appAuth.getAuth();
			auth.onIdTokenChanged(user => {
				currentUser = user;
				if (!user) {
					clearSessions();
					redirectToLogin();
					return;
				}
				setUserCookies(user);
			});
		}

		const loadUserProfile = user => {
			appDatabaseHelper.once('/usuario/' + user.uid)
				.then(data => {
					userProfile = data;

					if (userProfile.user.empresaAtual) {
						userProfile.user.empresaAtual.nome = globalFactory.capitalize(userProfile.user.empresaAtual.nome);
					}

					userProfile.user.empresas.forEach(e => {
						e.nome = globalFactory.capitalize(e.nome);
					})

					appConfig.initEmpresa(userProfile.user.idEmpresa);

					authReady = true;
				})
		}

		const token = _ => {
			const auth = appAuth.getAuth();
			return auth.currentUser ? auth.currentUser.accessToken : null;
		}

		const setEmpresaUser = (idEmpresa, uid) => {

			uid = uid || currentUser.uid;

			const httpParms = {
				url: URLs.auth.setEmpresaUsuario,
				method: 'post',
				data: {
					uid: uid,
					idEmpresa: idEmpresa
				},
				headers: {
					Authorization: token()
				}
			};

			blockUiFactory.start();

			$http(httpParms).then(
				function (response) {
					if (uid === currentUser.uid) {

						$rootScope.showPermissionErrorMsgs = false;

						currentUser.getIdToken(true).then(token => {
							$cookies.put('__session', token);
							$window.location.reload();
						})

					} else {
						alertFactory.info(`Empresa selecionada para o usuário.`);
					}
				},
				function (e) {
					blockUiFactory.stop();
					console.error(e);
				}
			);

		}

		const getUserInfo = attr => {

			const httpParms = {
				url: URLs.auth.getUserInfo + '/' + attr.uid + (attr.full ? '?full=true' : ''),
				method: 'get',
				headers: {
					Authorization: token()
				}
			};

			blockUiFactory.start();

			$http(httpParms).then(
				function (response) {
					blockUiFactory.stop();
					if (typeof attr.success === 'function') {
						attr.success(response.data);
					}
				},
				function (e) {
					blockUiFactory.stop();
					console.error(e);
					if (typeof attr.error === 'function') {
						attr.error(e);
					}
				}
			);

		}

		const redirectToLogin = function () {
			if (!$window.location.pathname.startsWith('/adm/login')) {
				window.location.replace('/adm/login');
			}
		}

		const redirectToHome = function () {
			if (!$window.location.pathname.startsWith('/adm/home')) {
				window.location.replace('/adm/home');
			}
		}

		const _getAuth = () => {
			return appAuth.getAuth();
		}

		const _init = _ => {
			const auth = appAuth.getAuth();

			appConfig.init(_ => {

				appAuth.onAuthStateChanged(auth, user => {

					currentUser = user;

					if (!currentUser) {
						clearSessions();
						authReady = true;
						return;
					}

					setUserCookies(user);

					if (user && $window.location.pathname.startsWith('/adm/login')) {
						redirectToHome();
						return;
					}

					loadUserProfile(user);
					checkTokenChange();

				})

			});

		}

		const _signInWithRedirect = () => {

			const googleProviderConfig = appConfig.get("/login/googleProvider");

			const auth = appAuth.getAuth();
			const googleProvider = new appAuth.GoogleAuthProvider();

			auth.languageCode = googleProviderConfig.languageCode;

			googleProvider.setCustomParameters(googleProviderConfig.customParameters);

			googleProviderConfig.scope.forEach(s => {
				googleProvider.addScope(s);
			})

			var returnUrl = $window.location.origin + "/adm/home";

			history.replaceState(null, document.title, returnUrl);

			appAuth.signInWithRedirect(auth, googleProvider)
				.catch(function (e) {
					console.error(e);
				});
		};

		const _signInWithEmail = (email, password) => {
			blockUiFactory.start();
			const auth = appAuth.getAuth();
			return $q((resolve, reject) => {
				appAuth.signInWithEmailAndPassword(auth, email, password)
					.then(_ => {
						$window.location.href = "/adm/home";
						return resolve();
					})
					.catch(function (e) {
						blockUiFactory.stop();
						appErrors.showError(e);
						return reject(e);
					});
			})
		}

		const _signOut = () => {

			const auth = appAuth.getAuth();

			$rootScope.showPermissionErrorMsgs = false;

			appAuth.signOut(auth).then(() => {
				clearSessions();
				$window.location.reload();
			}).catch(e => {
				console.error(e);
			});
		}

		const _ready = () => {
			return $q(resolve => {
				const checkIsReady = () => {
					if (!authReady) {
						$timeout(() => { checkIsReady(); }, 250);
						return;
					}
					return resolve(currentUser);
				}
				checkIsReady();
			})
		}

		return {
			init: _init,
			getAuth: _getAuth,
			signInWithRedirect: _signInWithRedirect,
			signInWithEmail: _signInWithEmail,
			signOut: _signOut,
			ready: _ready,
			setEmpresaUser: setEmpresaUser,
			getUserInfo: getUserInfo,

			get user() {
				return currentUser;
			},

			get profile() {
				return userProfile;
			},
			
			get token() {
				return token();
			}

		}

	})

export default ngModule;