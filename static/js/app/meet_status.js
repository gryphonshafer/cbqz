Vue.http.get( cntlr + "/meet_status" ).then( function (response) {
    var now = new Date;

    var vue_app = new Vue({
        el: '#meet_status',
        data: {
            quizzes: response.body,
            now: now.toLocaleTimeString()
        },
        filters: {
            ucfirst: function (value) {
                if ( ! value ) return '';
                value = value.toString();
                return value.charAt(0).toUpperCase() + value.slice(1);
            },

            time: function (value) {
                var now = new Date(value);
                return now.toLocaleTimeString();
            }
        },
        mounted: function () {
            var vue = this;

            this.$options.interval = setInterval( function () {
                var now = new Date;
                vue.now = now.toLocaleTimeString();
            }, 1000);
        }
    });

    var meet_status_ws;
    function start_meet_status_ws() {
        meet_status_ws = new WebSocket(meet_status_websocket_url);

        meet_status_ws.onmessage = function (e) {
            vue_app.$data.quizzes = JSON.parse( e.data );
        };

        meet_status_ws.onclose = function (e) {
            start_meet_status_ws();
        };
    }
    start_meet_status_ws();
});
