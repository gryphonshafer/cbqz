var vue_app = new Vue({
    el: '#meet_status',
    data: {
        quizzes: null
    }
});

var meet_status_ws;
function start_meet_status_ws() {
    meet_status_ws = new WebSocket(meet_status_websocket_url);

    meet_status_ws.onmessage = function (e) {
        var data = JSON.parse( e.data );
        vue_app.$data.quizzes = data;
    };

    meet_status_ws.onclose = function (e) {
        start_meet_status_ws();
    };
}
start_meet_status_ws();
