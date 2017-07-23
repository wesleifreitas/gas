(function() {
    'use strict';

    angular.module('myApp').filter('gasStatus', gasStatus);

    gasStatus.$inject = ['GAS'];
    /* @ngInject */
    function gasStatus(GAS) {
        return function(value) {
            for (var i = 0; i <= GAS.STATUS.length - 1; i++) {
                if (GAS.STATUS[i].id === value) {
                    return GAS.STATUS[i].name;
                }
            }
            return '?';
        };
    }

    angular.module('myApp').filter('gasStatusClass', gasStatusClass);

    gasStatusClass.$inject = ['GAS'];
    /* @ngInject */
    function gasStatusClass(GAS) {
        return function(value) {
            for (var i = 0; i <= GAS.STATUS.length - 1; i++) {
                if (GAS.STATUS[i].id === value) {
                    return GAS.STATUS[i].class;
                }
            }
            return 'fa-question';
        };
    }
})();