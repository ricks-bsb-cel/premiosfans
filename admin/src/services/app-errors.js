'use strict';

const ngModule = angular.module('services.app-errors', [])

	.factory('appErrors', function (
		firebaseErrorCodes,
		alertFactory,
		$rootScope
	) {

		const showError = (e, title) => {

			if (!$rootScope.showPermissionErrorMsgs) {
				return;
			}

			console.error(e);

			var i = firebaseErrorCodes.findIndex(f => { return e.code && f.error === e.code; })

			if (i >= 0) {
				alertFactory.error(firebaseErrorCodes[i].detalhes, title);
			} else if (e.message) {
				alertFactory.error(e.message, title);
			} else {
				alertFactory.error('Erro indeterminado...', title);
			}
		}

		return {
			showError: showError
		}

	})

export default ngModule;
