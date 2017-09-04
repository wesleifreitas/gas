(function() {
    'use strict';

    angular.module('myApp').controller('GasClienteCtrl', GasClienteCtrl);

    GasClienteCtrl.$inject = ['config', 'gasClienteService', '$rootScope', '$scope', '$state', '$mdDialog', 'GAS'];

    function GasClienteCtrl(config, gasClienteService, $rootScope, $scope, $state, $mdDialog, GAS) {

        var vm = this;
        vm.init = init;
        vm.getData = getData;
        vm.searchDialog = searchDialog;
        vm.create = create;
        vm.update = update;
        vm.remove = remove;
        vm.status = GAS.STATUS;
        vm.gasCliente = {
            limit: 10,
            page: 1,
            selected: [],
            order: '',
            data: [],
            pagination: pagination,
            total: 0
        };

        // $on
        // https://docs.angularjs.org/api/ng/type/$rootScope.Scope
        $scope.$on('grupoSelected', function(event, args) {
            //console.info('grupoSelected!', args);
            getData({ reset: true });
        });

        function init() {

            var filterLast = JSON.parse(localStorage.getItem('filter')) || {};

            if (filterLast[$state.current.url.split('/')[1]]) {
                vm.filter = filterLast;
            } else {
                vm.filter = {};
                vm.filter[$state.current.url.split('/')[1]] = true;
            }

            getData({ reset: true });
        }

        function pagination(page, limit) {
            vm.gasCliente.data = [];
            getData();
        }

        function getData(params) {

            params = params || {};

            vm.filter.page = vm.gasCliente.page;
            vm.filter.limit = vm.gasCliente.limit;

            if (params.reset) {
                vm.gasCliente.data = [];
            }

            localStorage.setItem('filter', JSON.stringify(vm.filter));
            vm.gasCliente.promise = gasClienteService.get(vm.filter)
                .then(function success(response) {
                    //console.info('success', response);

                    for (var i = 0; i <= response.query.length - 1; i++) {
                        response.query[i].CLI_CPFCNPJ = String(response.query[i].CLI_CPFCNPJ);
                        // ajustar dates
                        if (response.query[i].GAS_ULTIMA_TROCA !== '') {
                            response.query[i].GAS_ULTIMA_TROCA = new Date(response.query[i].GAS_ULTIMA_TROCA);
                        }
                        if (response.query[i].GAS_PROXIMA_TROCA !== '') {
                            response.query[i].GAS_PROXIMA_TROCA = new Date(response.query[i].GAS_PROXIMA_TROCA);
                        }
                    }

                    vm.gasCliente.total = response.recordCount;
                    vm.gasCliente.data = vm.gasCliente.data.concat(response.query);
                }, function error(response) {
                    console.error('error', response);
                });
        }

        function searchDialog() {
            var locals = { filter: vm.filter };

            $mdDialog.show({
                locals: locals,
                preserveScope: true,
                controller: 'GasClienteSearchDialogCtrl',
                controllerAs: 'vm',
                templateUrl: 'partial/gas-cliente/gas-cliente-search-dialog.html',
                parent: angular.element(document.body),
                //targetEvent: event,
                clickOutsideToClose: false
            }).then(function(data) {
                getData({ reset: true });
            });
        }

        function create() {
            $state.go('gas-cliente-form');
        }

        function update(id) {
            $state.go('gas-cliente-form', { id: id });
        }

        function remove() {

            var confirm = $mdDialog.confirm()
                .title('ATENÇÃO')
                .textContent('Deseja realmente remover o(s) item(ns) selecionado(s)?')
                .targetEvent(event)
                .ok('SIM')
                .cancel('NÃO');

            $mdDialog.show(confirm).then(function() {
                gasClienteService.remove(vm.gasCliente.selected)
                    .then(function success(response) {
                        if (response.success) {
                            $('.md-selected').remove();
                            vm.gasCliente.selected = [];
                        }
                    }, function error(response) {
                        console.error('error', response);
                    });
            }, function() {
                // cancel
            });
        }
    }
})();