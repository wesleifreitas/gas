(function () {
    'use strict';

    angular.module('myApp').controller('GasClienteFormCtrl', GasClienteFormCtrl);

    GasClienteFormCtrl.$inject = ['$scope', '$state', '$stateParams', '$mdDialog',
        'gasClienteService', 'getData', 'EXAMPLE'
    ];

    function GasClienteFormCtrl($scope, $state, $stateParams, $mdDialog,
        gasClienteService, getData, EXAMPLE) {

        var vm = this;
        vm.init = init;
        vm.gasCliente = {};
        vm.uf = EXAMPLE.UF;
        vm.getData = getData;
        vm.removeById = removeById;
        vm.cancel = cancel;
        vm.cepSearch = cepSearch;
        vm.calcMedia = calcMedia;
        vm.callProximaTroca = callProximaTroca;
        vm.save = save;

        function init() {
            if ($stateParams.id) {
                vm.action = 'update';

                vm.gasCliente = {
                    nome: vm.getData.NOME,
                    cpf: String(vm.getData.CPF),
                    data: new Date(vm.getData.DATA)
                };
            } else {
                vm.action = 'create';
                //default
                vm.gasCliente.GAS_ULTIMA_TROCA = new Date();
            }
        }

        function removeById(event) {
            var confirm = $mdDialog.confirm()
                .title('ATENÇÃO')
                .textContent('Deseja realmente remover este registro?')
                .targetEvent(event)
                .ok('SIM')
                .cancel('NÃO');

            $mdDialog.show(confirm).then(function () {
                gasClienteService.removeById($stateParams.id)
                    .then(function success(response) {
                        if (response.success) {
                            console.info('success', response);
                            $state.go('gas-cliente');
                        } else {
                            console.warn('warn', response);
                        }
                    }, function error(response) {
                        console.error('error', response);
                    });
            }, function () {
                // cancel
            });
        }

        function cancel() {
            $state.go('gas-cliente');
        }

        function cepSearch(event) {
            //console.info('cepSearch', event);
            vm.gasCliente.CLI_ENDERECO = event.data.logradouro;
            vm.gasCliente.CLI_BAIRRO = event.data.bairro;
            vm.gasCliente.CLI_CIDADE = event.data.localidade;
            vm.gasCliente.CLI_UF = event.data.uf;
        }

        function calcMedia() {
            if (vm.action === 'create' &&
                vm.gasCliente.GAS_MEDIA > 0 &&
                angular.isDate(vm.gasCliente.GAS_ULTIMA_TROCA)) {

                var diffDay = moment(vm.gasCliente.GAS_ULTIMA_TROCA)
                    .diff(moment(), 'days');

                vm.gasCliente.GAS_PROXIMA_TROCA = moment(vm.gasCliente.GAS_ULTIMA_TROCA)
                    .add(diffDay, 'day');

                vm.diff = moment(vm.gasCliente.GAS_ULTIMA_TROCA)
                    .diff(moment(), 'months', true).toFixed(1);
            } else {
                vm.gasCliente.GAS_PROXIMA_TROCA = null;
            }
            console.info('vm.diff', vm.diff);
        }

        function callProximaTroca() {
            if (vm.action === 'create' &&
                vm.gasCliente.GAS_MEDIA > 0 &&
                angular.isDate(vm.gasCliente.GAS_ULTIMA_TROCA)) {

                vm.gasCliente.GAS_PROXIMA_TROCA = moment(vm.gasCliente.GAS_ULTIMA_TROCA)
                    .add(vm.gasCliente.GAS_MEDIA * 30, 'days');
            } else {
                vm.gasCliente.GAS_PROXIMA_TROCA = null;
            }
        }

        function save() {

            if ($stateParams.id) {
                //update
                gasClienteService.update($stateParams.id, vm.gasCliente)
                    .then(function success(response) {
                        if (response.success) {
                            console.info('success', response);
                            $state.go('gas-cliente');
                        } else {
                            console.warn('warn', response);
                        }
                    }, function error(response) {
                        console.error('error', response);
                    });
            } else {
                // create
                gasClienteService.create(vm.gasCliente)
                    .then(function success(response) {
                        if (response.success) {
                            console.info('success', response);
                            $state.go('gas-cliente');
                        } else {
                            console.warn('warn', response);
                        }
                    }, function error(response) {
                        console.error('error', response);
                    });
            }
        }
    }
})();