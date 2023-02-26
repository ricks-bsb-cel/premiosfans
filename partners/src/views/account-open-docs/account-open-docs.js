'use strict';

import config from './account-open-docs.config';

var ngModule = angular.module('views.account-open-docs', [
])

	.config(config)

	.controller('viewAccountOpenDocsController', function (
		$scope,
		appAuthHelper,
		pageHeaderFactory,
		globalFactory,
		profileService,
		$window,
		waitUiFactory,
		$routeParams,
		footerBarFactory
	) {

		pageHeaderFactory.setModeLight('Documentos');

		$scope.ready = false;
		$scope.forms = null;

		$scope.type = $routeParams.type;
		$scope.id = $routeParams.id;

		footerBarFactory.hide();

		$scope.docs = null;

		const filePrefix = '/api/utils/v1/img/';

		const save = model => {
			var toSave = { ...model } || {};

			Object.keys(toSave).forEach(k => {
				if (toSave[k]) {
					toSave[k] = toSave[k].replace(filePrefix, '');
				}
			})

			profileService.saveDocumentImages(toSave)
				.catch(e => {
					console.info(e);
				})
		}

		const imageTitle = t => {
			return `<h4 class="color-blue-dark text-center m-0">${t}</h4>`
		}

		appAuthHelper.ready()

			.then(_ => {
				return profileService.getDocumentImages();
			})

			.then(getDocumentImagesResult => {

				$scope.docs = getDocumentImagesResult;

				Object.keys($scope.docs || {}).forEach(k => {
					if ($scope.docs[k]) { $scope.docs[k] = filePrefix + $scope.docs[k]; }
				})

				$scope.forms = {
					imagens: {
						model: $scope.docs || {},
						form: null,
						fields: [
							{
								template: imageTitle('Frente do Documento')
							},
							{
								key: 'imagem_doc_frente',
								type: 'image-upload',
								templateOptions: {
									slimOptions: {
										size: null,
										minSize: null,
										ratio: '8:5',
										storage: {
											filename: `/app/${appAuthHelper.currentUser.uid}/user/doc-frente-${globalFactory.guid()}`
										}
									}
								},
								watcher: {
									listener: function (field, newValue, oldValue, scope) {
										save(scope.model);
									}
								}
							},
							{
								template: imageTitle('Verso do Documento')
							},
							{
								key: 'imagem_doc_verso',
								type: 'image-upload',
								templateOptions: {
									slimOptions: {
										size: null,
										minSize: null,
										ratio: '8:5',
										storage: {
											filename: `/app/${appAuthHelper.currentUser.uid}/user/doc-verso-${globalFactory.guid()}`
										}
									}
								},
								watcher: {
									listener: function (field, newValue, oldValue, scope) {
										save(scope.model);
									}
								}
							},
							{
								template: imageTitle('Sua foto (Selfie)')
							},
							{
								key: 'imagem_doc_selfie',
								type: 'image-upload',
								templateOptions: {
									slimOptions: {
										size: null,
										minSize: null,
										ratio: '1:1',
										storage: {
											filename: `/app/${appAuthHelper.currentUser.uid}/user/selfie-${globalFactory.guid()}`
										}
									}
								},
								watcher: {
									listener: function (field, newValue, oldValue, scope) {
										save(scope.model);
									}
								}
							}
						]
					}
				};

				$scope.ready = true;

				waitUiFactory.hide();

			})

			.catch(e => {
				console.info(e);
			})


		$scope.close = _ => {

			waitUiFactory.start();

			profileService.saveNextOptionAbertura($scope.id, 'aprovacao')
				.then(_ => {
					waitUiFactory.stop();
					$window.history.back();
				})
				.catch(e => {
					waitUiFactory.stop();
					console.info(e);
				})
		}

	});


export default ngModule;
