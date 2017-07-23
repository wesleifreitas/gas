(function() {
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
            }
        }

        function removeById(event) {
            var confirm = $mdDialog.confirm()
                .title('ATENÇÃO')
                .textContent('Deseja realmente remover este registro?')
                .targetEvent(event)
                .ok('SIM')
                .cancel('NÃO');

            $mdDialog.show(confirm).then(function() {
                gasClienteService.removeById($stateParams.id)
                    .then(function success(response) {
                        if (response.success) {
                            console.info('success', response);
                            $state.go('gasCliente');
                        } else {
                            console.warn('warn', response);
                        }
                    }, function error(response) {
                        console.error('error', response);
                    });
            }, function() {
                // cancel
            });
        }

        function cancel() {
            $state.go('gasCliente');
        }

        function save() {

            if ($stateParams.id) {
                //update
                gasClienteService.update($stateParams.id, vm.gasCliente)
                    .then(function success(response) {
                        if (response.success) {
                            console.info('success', response);
                            $state.go('gasCliente');
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
                            $state.go('gasCliente');
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