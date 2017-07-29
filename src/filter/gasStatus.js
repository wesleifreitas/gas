(function() {
    'use strict';

    angular.module('myApp').filter('gasStatus', gasStatus);

    gasStatus.$inject = ['GAS'];
    /* @ngInject */
    function gasStatus(GAS) {
        return function(value) {
            for (var i = 0; i <= GAS.STATUS.length - 1; i++) {
                if (GAS.STATUS[i].id === value) {
                    return GAS.STATUS[i];
                }
            }
            return {
                id: 0,
                name: '',
                class: 'fa-question'
            };
        };
    }
})();