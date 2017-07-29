(function() {
    'use strict';

    angular.module('myApp').controller('GasClienteSearchDialogCtrl', GasClienteSearchDialogCtrl);

    GasClienteSearchDialogCtrl.$inject = ['$mdDialog', 'locals', '$mdToast', 'GAS'];

    function GasClienteSearchDialogCtrl($mdDialog, locals, $mdToast, GAS) {

        var vm = this;
        vm.init = init;
        vm.status = GAS.STATUS;
        vm.filter = locals.filter;
        vm.save = save;
        vm.cancel = cancel;

        function init(event) {}

        function save() {
            $mdDialog.hide();
        }

        function cancel() {
            $mdDialog.cancel();
        }
    }
})();