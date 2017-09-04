(function() {
    'use strict';

    angular.module('myApp').directive('cepSearch', cepSearch);

    cepSearch.$inject = ['cepService'];

    function cepSearch(cepService) {
        var directive = {
            restrict: 'A',
            require: 'ngModel',
            scope: {
                cepSearchEvent: '&cepSearchEvent'
            },
            link: init
        };
        return directive;

        function init(scope, element, attrs, ngModelCtrl) {
            ngModelCtrl.$parsers.push(function(value) {
                if (value.length === 8) {
                    cepService.cep(value)
                        .then(function success(response) {
                            var event = { data: response.data };
                            scope.cepSearchEvent({
                                event: event
                            });
                        }, function error(response) {});
                }
                return value;
            });
        }
    }
})();