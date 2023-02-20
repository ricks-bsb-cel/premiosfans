'use strict';

import editServiceUserCredential from './directives/edit-service-user-credential/edit';
import newAccount from './directives/new-account/edit';

const ngModule = angular.module('directives.cartos-admin', [
	editServiceUserCredential.name,
	newAccount.name
])

	.controller('cartosAdminController',
		function (
			$scope,
			$timeout,
			collectionCartosAccounts,
			collectionCartosPixKeys,

			cartosAdminEditServiceUserCredentialFactory,
			cartosAdminNewAccountFactory
		) {

			const
				_posAccount = 0;

			$scope.ready = false;

			$scope.treeOptions = {
				nodeChildren: "children",
				dirSelectable: true
			};

			$scope.editCartosUserAlias = _ => {
				cartosAdminEditServiceUserCredentialFactory.edit($scope.serviceUserCredential);
			}

			$scope.newAccount = _ => {
				cartosAdminNewAccountFactory.edit($scope.serviceUserCredential)
			}

			$scope.treeViewData = [
				{
					nodeType: "account-root",
					isRoot: true,
					nome: "Contas",
					children: []
				}
			]

			/*
			$scope.dataForTheTree = [
				{
					"name": "Joe", "age": "21", "children": [
						{ "name": "Smith", "age": "42", "children": [] },
						{
							"name": "Gary", "age": "21", "children": [
								{
									"name": "Jenifer", "age": "23", "children": [
										{ "name": "Dani", "age": "32", "children": [] },
										{ "name": "Max", "age": "34", "children": [] }
									]
								}
							]
						}
					]
				},
				{ "name": "Albert", "age": "33", "children": [] },
				{ "name": "Ron", "age": "29", "children": [] }
			];
			*/

			async function loadAccounts() {
				const cpf = $scope.serviceUserCredential.cpf;

				let accounts = await collectionCartosAccounts.getByCpf(cpf);
				let pixKeys = await collectionCartosPixKeys.getByCpf(cpf);

				accounts = accounts.map(a => {
					const obj = {
						nodeType: "account",
						children: [
							{
								nodeType: "pix-root",
								isRoot: true,
								accountId: a.accountId,
								nome: "PIX",
								children: pixKeys
									.filter(f => {
										return f.accountId === a.accountId;
									})
									.map(m => {
										return {
											nodeType: "pixkey",
											key: m.key,
											accountId: m.accountId,
											cpf: m.cpf,
											type: m.type
										}
									})
							}
						]
					};

					return { ...a, ...obj };
				})

				$timeout(_ => {
					$scope.ready = true;
					$scope.treeViewData[_posAccount].children = accounts;
				})

				$scope.element.find('.wait').hide()
			};

			$scope.init = e => {
				$scope.element = e;
				loadAccounts(e);
			}

			$scope.nodeSelected = node => {
				console.info(node);
			}

		}
	)

	.directive('blockCartosAdmin', function () {
		return {
			restrict: 'E',
			templateUrl: 'cartos-admin/cartos-admin.html',
			controller: 'cartosAdminController',
			scope: {
				serviceUserCredential: "="
			},
			link: function (scope, element) {
				scope.init(element);
			}
		};
	});

export default ngModule;
