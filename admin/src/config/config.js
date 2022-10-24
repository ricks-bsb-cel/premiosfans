import run from './run';
import apiUrls from './api-urls';

const ngModule = angular.module('config', [apiUrls.name])
	.run(run)

	.value('globalParms', {
		appName: 'Premios Fans Admin',
		appUrl: 'https://premiosfans.app',
		appVersion: '0.1.0',
		logoImg: '/adm/img/logo.png',
		initDelay: 10, // In seconds...
	})

	.value('pexelsConfig', {
		minQueryLength: 3,
		searchTimer: null,
		photos: [],
		allowInfinite: true,
		maxItems: 12,
		itemsPerLoad: 12,
		nextPage: null,
		iScroll: null,
		apikey: '563492ad6f91700001000001059da27e8d704ed3a3e61af7d5436097',
		urls: {
			search: 'https://api.pexels.com/v1/search'
		}
	})

	.value('cloudinaryConfig', {
		url: 'https://api.cloudinary.com/v1_1/ycard-app/upload',
		defaultUploadPreset: 'zoepay'
	})

	.filter('unsafe', function ($sce) {
		return $sce.trustAsHtml;
	})

	.filter('url', function () {
		return function (value, showHttp) {
			return (showHttp ? window.location.origin : window.location.host) + '/' + value;
		}
	})

	.filter('ddmmyyyy', function (appConfig) {
		return function (v) {
			const displayMask = appConfig.get("/masks/data/display");
			if (v) {
				if (typeof v === 'object') {
					return moment(v.toDate()).format(displayMask);
				} else if (v.substr(10, 1) === 'T') {
					return moment(v).format(displayMask);
				} else {
					return moment.unix(v).format(displayMask);
				}
			} else {
				return null;
			}
		}
	})

	.filter('cpfCnpj', function (globalFactory) {
		return function (v) {
			if (v) {
				if (v.length === 11) {
					return globalFactory.formatCpf(v);
				} else if (v.length === 14) {
					return globalFactory.formatCnpj(v);
				} else {
					return v;
				}
			} else {
				return null;
			}
		}
	})

	.filter('hhmm', function () {
		return function (v) {
			if (v) {
				if (typeof v === 'object') {
					return moment(v.toDate()).format('HH:mm');
				} else if (v.substr(10, 1) === 'T') {
					return moment(v).format('HH:mm');
				} else {
					return moment.unix(v).format("HH:mm");
				}
			} else {
				return null;
			}
		}
	})

	.filter('ddmmyyyyhhmm', function (appConfig) {
		return function (v) {
			const displayMask = appConfig.get("/masks/dataHora/display");
			if (v) {
				if (typeof v === 'object') {
					return moment(v.toDate()).format(displayMask);
				} else {
					return moment.unix(v).format(displayMask);
				}
			} else {
				return null;
			}
		}
	})

	.filter('ddmmhhmm', function (appConfig) {
		return function (v) {
			const displayMask = appConfig.get("/masks/dataHoraSemAno/display");
			if (v) {
				if (typeof v === 'object') {
					return moment(v.toDate()).format(displayMask);
				} else {
					return moment.unix(v).format(displayMask);
				}
			} else {
				return null;
			}
		}
	})

	.filter('capitalize', function (globalFactory) {
		return function (v) {
			if (v) {
				return globalFactory.capitalize(v);
			} else {
				return null;
			}
		}
	})

	.filter('upperCase', function () {
		return function (v) {
			return (v || '').toUpperCase();
		}
	})

	.config( // https://morgul.github.io/ui-bootstrap4/#!#tooltip
		function (
			$uibTooltipProvider
		) {
			$uibTooltipProvider.options({
				animation: true,
				placement: "top-right",
				popupDelay: 500,
				trigger: 'mouseenter'
			});
		}
	)

	.config(['$qProvider', function ($qProvider) {
		$qProvider.errorOnUnhandledRejections(false);
	}]);

export default ngModule;
