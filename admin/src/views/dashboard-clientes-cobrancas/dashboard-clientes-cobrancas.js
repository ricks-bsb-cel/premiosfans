import { isFunction } from 'angular';
import config from './dashboard-clientes-cobrancas.config';

'use strict';

var ngModule;

ngModule = angular.module('views.dashboard-clientes-cobrancas', [
])

	.config(config)

	.controller('viewDashboardClientesCobrancasController', function (
		$scope,
		navbarTopLeftFactory,
		firebaseService,
		collectionPlanos,
		collectionEmpresas,
		collectionCobrancas,
		collectionContratos,
		$routeParams
	) {

		$scope.contrato = null;
		$scope.empresa = null;
		$scope.plano = null;

		$scope.collectionCobrancas = collectionCobrancas;

		$scope.ready = false;

		navbarTopLeftFactory.reset(false);

		$scope.getIconInfoBox = function (cobranca) {

			if (cobranca.diasRestantesParaPagamento > 0) {
				return 'fas fa-tag';
			} else if (cobranca.diasRestantesParaPagamento === 0) {
				return 'fas fa-exclamation';
			} else {
				return 'fas fa-exclamation-triangle';
			}

		}

		$scope.getClassInfoBox = function (cobranca) {

			if (cobranca.diasRestantesParaPagamento > 0) {
				return 'bg-info';
			} else if (cobranca.diasRestantesParaPagamento === 0) {
				return 'bg-warning';
			} else {
				return 'bg-danger';
			}

		}

		firebaseService.getProfile(userProfile => {
			collectionContratos.collection.getDoc($routeParams.idContrato).then(contrato => {
				$scope.contrato = contrato;
				collectionPlanos.collection.getDoc(contrato.idPlano).then(plano => {
					$scope.plano = plano;
				})
			})

			collectionEmpresas.collection.getDoc($routeParams.idEmpresa).then(empresa => {
				$scope.empresa = empresa;
			})

			$scope.collectionCobrancas.collection.getSnapshot({
				idEmpresa: $routeParams.idEmpresa,
				idContrato: $routeParams.idContrato,
				uidCliente: userProfile.user.uid
			});
		})

		/*
		firebaseService.registerListenersAuthStateChanged(user => {

			collectionContratos.collection.getDoc($routeParams.idContrato).then(contrato => {
				$scope.contrato = contrato;
				collectionPlanos.collection.getDoc(contrato.idPlano).then(plano => {
					$scope.plano = plano;
				})
			})

			collectionEmpresas.collection.getDoc($routeParams.idEmpresa).then(empresa => {
				$scope.empresa = empresa;
			})

			$scope.collectionCobrancas.collection.getSnapshot({
				idEmpresa: $routeParams.idEmpresa,
				idContrato: $routeParams.idContrato,
				uidCliente: user.uid
			});

		})
		*/

		firebaseService.init();

	});

export default ngModule;
