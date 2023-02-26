'use strict';

import config from './conteudo.config';

var ngModule = angular.module('views.conteudo', [
])

	.config(config)

	.controller('viewConteudoController', function (
		$scope,
		appFirestore,
		appAuthHelper,
		pageHeaderFactory,
		$routeParams,
		waitUiFactory,
		footerBarFactory,
		$timeout
	) {

		pageHeaderFactory.setModeNone();
		footerBarFactory.hide();

		$scope.sigla = $routeParams.sigla;
		$scope.conteudo = null;

		let conteudo;

		appAuthHelper.ready()

			.then(_ => {

				if (appAuthHelper.currentUser && !appAuthHelper.currentUser.isAnonymous) {
					footerBarFactory.show();
				}

				const db = appFirestore.firestore;
				const c = appFirestore.collection(db, 'conteudo');

				let q = appFirestore.query(c);
				q = appFirestore.query(q, appFirestore.where('sigla', '==', $scope.sigla));
				q = appFirestore.query(q, appFirestore.limit(1));

				return appFirestore.getDocs(q);
			})

			.then(data => {

				if (data.empty) {
					conteudo = {
						html: `<div class="col-12 mb-n2 text-start">
									<a href="page-reports.html" class="default-link card card-style" style="height:90px">
										<div class="card-center px-4">
											<div class="d-flex">
												<div class="align-self-center">
													<span class="icon icon-m rounded-s gradient-brown shadow-bg shadow-bg-xs"><i class="bi bi-bar-chart font-20 color-white"></i></span>
												</div>
												<div class="align-self-center ps-3 ms-1">
													<h1 class="font-20 mb-n1">Account Reports</h1>
													<p class="mb-0 font-12 opacity-70">See your Payment Statistics.</p>
												</div>
											</div>
										</div>
									</a>
								</div>`
					};
				} else {
					data.forEach(d => {
						conteudo = angular.merge(d.data(), { id: d.id });

						if (appAuthHelper.currentUser && appAuthHelper.currentUser.isAnonymous && !conteudo.publico) {
							$location.path('/index');
							$location.replace();
							return;
						}

						pageHeaderFactory.setModeLight(conteudo.descricao);
					})
				}

				$timeout(_ => {
					$scope.conteudo = conteudo.html;
					waitUiFactory.stop();
				})

			})

			.catch(e => {
				console.error(e);
				return reject(e);
			})

		/*
		$scope.$on('$destroy', function () {
			appAuthHelper.destroyNotifyUserDataChanged(userDataChanged);
		});
		*/

	});


export default ngModule;
