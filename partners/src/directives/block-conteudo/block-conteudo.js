
const ngModule = angular.module('directives.block-conteudo', [])

	.factory('blockConteudoFactory', function (
		appAuthHelper,
		appFirestore
	) {

		const getTemplate = sigla => {
			return new Promise((resolve, reject) => {
				
				return appAuthHelper.ready().then(_ => {

					const db = appFirestore.firestore;
					const c = appFirestore.collection(db, 'conteudo');

					let q = appFirestore.query(c);
					q = appFirestore.query(q, appFirestore.where('sigla', '==', sigla));
					q = appFirestore.query(q, appFirestore.limit(1));

					appFirestore.getDocs(q)
						.then(data => {

							if (data.empty) {
								return resolve("<i>404 * Not Found</i>");
							} else {
								data.forEach(d => {
									d = angular.merge(d.data(), { id: d.id });
									return resolve(d);
								})
							}

						})
						.catch(e => {
							console.error(e);
							return reject(e);
						})

				})
			})
		};

		return {
			getTemplate: getTemplate
		}
	})

	.directive('blockConteudo', function ($compile, blockConteudoFactory) {
		return {
			restrict: 'E',
			template: '<div class="spinner-border color-white" role="status" style="left:calc(50% - 22px);position:fixed;z-index:10;top:30%;"></div>',
			link: function (scope, element) {
				blockConteudoFactory.getTemplate(scope.sigla)
					.then(data => {
						const el = $compile(data.html)(scope);
						element.replaceWith(el);
						if (scope.delegate && typeof scope.delegate.ready === 'function') {
							scope.delegate.ready(data);
						}
					})
			},
			scope: {
				sigla: '@'
			}
		};
	});

export default ngModule;
