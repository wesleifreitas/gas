(function() {
    'use strict';

    angular
        .module('myApp')
        .config(configure);

    configure.$inject = ['$stateProvider'];

    function configure($stateProvider) {
        $stateProvider.state('gas-cliente', getState());
    }

    function getState() {
        return {
            url: '/gas-cliente',
            templateUrl: 'partial/gas-cliente/gas-cliente.html',
            controller: 'GasClienteCtrl',
            controllerAs: 'vm',
            parent: 'home',
            params: {
                'id': null
            },
        };
    }
})();