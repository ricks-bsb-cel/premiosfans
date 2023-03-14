'use strict';

import Swal from 'sweetalert2';

let ngModule = angular.module('factories.alert', [])

	.factory('alertFactory',

		function (
			$q
		) {

			var success = function (msg) {
				return $q(function (resolve, reject) {
					Swal.fire({
						html: msg,
						icon: 'success'
					}).then(function () {
						resolve();
					})
				})
			};

			var error = function (msg, title) {
				return $q(function (resolve, reject) {

					var attr = {
						html: msg,
						icon: 'error'
					};

					if (title) { attr.title = title; }

					if (attr.html.xhrStatus && attr.html.data && attr.html.data.error) {
						attr.html = attr.html.data.error;
					}

					Swal.fire(attr).then(function () {
						resolve();
					})
				})
			};

			var warning = function (msg) {
				return $q(function (resolve, reject) {
					Swal.fire({
						html: msg,
						icon: 'warning'
					}).then(function () {
						resolve();
					})
				})
			};

			var info = function (msg, title) {
				return $q(function (resolve, reject) {
					var attr = {
						html: msg,
						icon: 'info'
					};
					if (title) { attr.title = title; }
					Swal.fire(attr)
						.then(function () {
							resolve();
						})
				})
			};

			var yesno = function (msg, title) {
				return $q(function (resolve, reject) {
					Swal.fire({
						title: title || 'Tem certeza?',
						html: msg,
						icon: 'question',
						showCancelButton: true,
						cancelButtonColor: '#d33',
						confirmButtonText: 'Sim',
						cancelButtonText: 'Não'
					}).then((result) => {
						if (result.isConfirmed) {
							resolve();
						} else {
							reject();
						}
					})

				})
			};

			var factory = {
				success: success,
				error: error,
				warning: warning,
				info: info,
				yesno: yesno
			};

			return factory;
		}
	);

export default ngModule;
