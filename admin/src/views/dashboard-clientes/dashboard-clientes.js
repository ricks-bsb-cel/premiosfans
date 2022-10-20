import { isFunction } from 'angular';
import config from './dashboard-clientes.config';

'use strict';

var ngModule;

ngModule = angular.module('views.dashboard-clientes', [
])

	.config(config)

	.controller('viewDashboardClientesController', function (
		$scope,
		navbarTopLeftFactory,
		firebaseService,
		collectionCobrancas,
		collectionContratos
	) {

		$scope.collectionContratos = collectionContratos;
		$scope.collectionCobrancas = collectionCobrancas;

		$scope.ready = false;

		navbarTopLeftFactory.reset(false);

		const diasRestantesPagamentoContrato = function (contrato) {
			var diasRestantesParaPagamento = 999;

			$scope.collectionCobrancas.collection.data.filter(f => {
				return f.idContrato === contrato.id;
			}).forEach(c => {
				if (diasRestantesParaPagamento > c.diasRestantesParaPagamento) {
					diasRestantesParaPagamento = c.diasRestantesParaPagamento;
				}
			})

			return diasRestantesParaPagamento;
		}

		$scope.getIconInfoBox = function (contrato) {

			if (!$scope.hasCobranca(contrato)) {
				return 'fas fa-tag';
			}

			var diasRestantesParaPagamento = diasRestantesPagamentoContrato(contrato);

			if (diasRestantesParaPagamento > 0) {
				return 'fas fa-tag';
			} else if (diasRestantesParaPagamento === 0) {
				return 'fas fa-exclamation';
			} else {
				return 'fas fa-exclamation-triangle';
			}

		}

		$scope.getClassInfoBox = function (contrato) {

			if (!$scope.hasCobranca(contrato)) {
				return 'bg-info';
			}

			var diasRestantesParaPagamento = diasRestantesPagamentoContrato(contrato);

			if (diasRestantesParaPagamento > 0) {
				return 'bg-info';
			} else if (diasRestantesParaPagamento === 0) {
				return 'bg-warning';
			} else {
				return 'bg-danger';
			}

		}

		$scope.hasCobranca = function (contrato) {
			return $scope.collectionCobrancas.collection.data.findIndex(f => {
				return f.idContrato === contrato.id;
			}) >= 0;
		}

		$scope.getCobrancas = function (contrato) {
			return $scope.collectionCobrancas.collection.data.filter(f => {
				return f.idContrato === contrato.id;
			});
		}

		firebaseService.getProfile(userProfile => {
			$scope.collectionContratos.collection.getSnapshot({
				uidCliente: userProfile.user.uid
			}, {
				loadReferences: ['idEmpresa_reference', 'idPlano_reference'],
				ordered: { idEmpresa: 'asc' }
			});

			$scope.collectionCobrancas.collection.getSnapshot({
				uidCliente: userProfile.user.uid
			});
		})

		/*
		firebaseService.registerListenersAuthStateChanged(function (user) {

			$scope.collectionContratos.collection.getSnapshot({
				uidCliente: user.uid
			}, {
				loadReferences: ['idEmpresa_reference', 'idPlano_reference'],
				ordered: {
					idEmpresa: 'asc'
				}
			});

			$scope.collectionCobrancas.collection.getSnapshot({
				uidCliente: user.uid
			});

		})
		*/

		firebaseService.init();

	});

export default ngModule;
