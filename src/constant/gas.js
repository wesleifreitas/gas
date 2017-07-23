(function() {
    'use strict';

    angular.module('myApp').constant('GAS', {
        STATUS: [{
            id: 0,
            name: 'Vazio',
            class: 'fa-battery-empty'
        }, {
            id: 1,
            name: 'Quase vazio',
            class: 'fa-battery-quarter'
        }, {
            id: 2,
            name: 'Na metade',
            class: 'fa-battery-half'
        }, {
            id: 3,
            name: 'Quase cheio',
            class: 'fa-battery-three-quarters'
        }, {
            id: 4,
            name: 'Cheio',
            class: 'fa-battery-full'
        }]
    });
})();