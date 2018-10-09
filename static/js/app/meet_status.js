Vue.http.get( cntlr + "/meet_status" ).then( function (response) {
    var vue_app = new Vue({
        el: '#meet_status',
        data: {
            quizzes: response.body
        },
        filters: {
            ucfirst: function (value) {
                if ( ! value ) return '';
                value = value.toString();
                return value.charAt(0).toUpperCase() + value.slice(1);
            }
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
