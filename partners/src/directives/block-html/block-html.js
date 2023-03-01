
/*
Herdamos do passado
Velhos erros e ideais
Que só servem de exemplo
Pros demais que já ha muito tempo...
*/

const ngModule = angular.module('directives.block-html', [])

	.factory('blockHtmlFactory', function (
		appAuthHelper,
		appFirestore
	) {

		async function getTemplate(sigla) {
			await appAuthHelper.ready();

			let result = "<i>404 * Not Found</i>";
			const db = appFirestore.firestore;
			const c = appFirestore.collection(db, '_htmlBlock');

			let q = appFirestore.query(c);

			q = appFirestore.query(q, appFirestore.where('sigla', '==', sigla));
			q = appFirestore.query(q, appFirestore.limit(1));

			const data = await appFirestore.getDocs(q);

			data.forEach(d => {
				result = angular.merge(d.data(), { id: d.id });
			})

			return result;
		};

		return {
			getTemplate: getTemplate
		}
	})

	.directive('blockHtml', function ($compile, blockHtmlFactory) {
		return {
			restrict: 'E',
			link: function (scope, element) {
				blockHtmlFactory.getTemplate(scope.sigla).then(data => {
					const el = $compile(data.html)(scope);

					element.append(el);

					if (scope.delegate && typeof scope.delegate.ready === 'function') {
						scope.delegate.ready(data);
					}
				})
			},
			scope: {
				sigla: '=',
				delegate: '=?',
				extra1: '=?',
				extra2: '=?',
				extra3: '=?'
			}
		};
	});

export default ngModule;
