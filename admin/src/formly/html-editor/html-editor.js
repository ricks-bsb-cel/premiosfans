
const ngModule = angular.module('admin.formly.html-editor', [])

    .run(function (
        formlyConfig
    ) {

        /*
        https://summernote.org/getting-started/
        https://github.com/summernote/angular-summernote
        */

        var fieldObj = {
            name: 'html-editor',
            extends: 'textarea',
            templateUrl: 'html-editor/html-editor.html',
            controller: function ($scope) {
                $scope.options.templateOptions.height = $scope.options.templateOptions.height || 200;
                $scope.options.templateOptions.defaultOptions = {
                    placeholder: $scope.options.templateOptions.placeholder || null,
                    tabsize: 4,
                    height: $scope.options.templateOptions.height,
                    lang: 'pt-BR',
                    disableDragAndDrop: true,
                    disableResizeEditor: true,
                    toolbar: $scope.options.templateOptions.toolbar || [
                        ['style', ['style']],
                        ['font', ['bold', 'italic', 'underline', 'clear']],
                        ['color', ['color']],
                        ['para', ['ul', 'ol', 'paragraph']],
                        ['table', ['table']],
                        ['insert', ['link', 'picture', 'video']],
                        ['view', ['fullscreen', 'codeview']]
                    ]
                };

                if ($scope.options.templateOptions.options) {
                    $scope.options.templateOptions.defaultOptions = angular.merge(
                        $scope.options.templateOptions.defaultOptions,
                        $scope.options.templateOptions.options
                    );
                }
            }
        };

        formlyConfig.setType(fieldObj);

    });

export default ngModule;
