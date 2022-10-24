'use strict';

/*
O que sinto, muitas vezes faz sentido
E, outras vezes, não descubro o motivo
Que me explique por que é que não consigo ver sentido
No que sinto, o que procuro,
O que desejo e o que faz parte do meu mundo
*/

import config from './usuarios.config';
import directiveEdit from './directives/edit/edit';

const ngModule = angular.module('views.usuarios', [
	directiveEdit.name
])
	.config(config)

	.controller('viewUsuariosController', function (
		$scope,
		collectionUserProfile,
		usuarioEditFactory,
		appAuthHelper
	) {

		$scope.collectionUserProfile = collectionUserProfile;
		$scope.ready = false;
		$scope.showSearch = false;

		$scope.edit = function (doc) {

			collectionUserProfile.getEmpresas(doc.id, false)
			
				.then(perfis => {
					doc.perfilEmpresas = [];

					perfis.forEach(p => {
						doc.perfilEmpresas.push({
							data: { idEmpresa: p.idEmpresa, idPerfil: p.idPerfil }
						});
					})

					usuarioEditFactory.edit(doc);
				})

				.catch(e => {
					console.error(e);
				})
		}

		$scope.filter = {
			run: termo => {

				let attrFilter = {
					filter: [
					]
				};
				
				if (termo) {
					attrFilter.filter.push({
						field: "keywords",
						operator: "array-contains",
						value: termo
					});
				}

				$scope.collectionUserProfile.collection.startSnapshot(attrFilter);
			}
		}

		appAuthHelper.ready()
			.then(_ => {
				if (!appAuthHelper.profile.user.superUser) {
					$scope.collectionUserProfile.collection.startSnapshot({
						orderBy: "displayName"
					})
				} else {
					$scope.showSearch = true;
				}

				$scope.ready = true;
			})

		$scope.$on('$destroy', function () {
			$scope.collectionUserProfile.collection.destroySnapshot();
		});

	});


export default ngModule;
