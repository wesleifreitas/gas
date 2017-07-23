(function() {
    'use strict';

    angular
        .module('myApp')
        .config(configure);

    configure.$inject = ['$stateProvider'];

    function configure($stateProvider) {
        $stateProvider.state('gas-cliente-form', getState());
    }

    function getState() {
        return {
            url: '/gas-cliente/:id',
            templateUrl: 'partial/gas-cliente/gas-cliente-form.html',
            controller: 'gasClienteFormCtrl',
            controllerAs: 'vm',
            parent: 'home',
            params: {
                'id': null
            },
            resolve: {
                getData: getData
            }
        };
    }

    getData.$inject = ['$state', '$stateParams', 'gasClienteService'];

    function getData($state, $stateParams, gasClienteService) {
        console.info('$stateParams', $stateParams);

        if ($stateParams.id) {
            return gasClienteService.getById($stateParams.id).then(success, error);
        } else {
            return {};
        }

        function success(response) {
            console.info(response);
            if (response.query.length === 0) {
                $state.go('404');
            } else {
                return response.query[0];
            }
        }

        function error(response) {
            return response;
        }
    }
})();