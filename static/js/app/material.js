var app = new Vue({
    el: '#app',
    data: {
        message: 'Local Data Operational'
    },
    components: {
        'local-component': {
            template: '<span>Local Component Operational</span>'
        }
    }
});
