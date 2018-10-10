var vue_app = new Vue({
    el: '#live_scoresheet',
    data: {
        quiz: null
    },
    filters: {
        ucfirst: function (value) {
            if ( ! value ) return '';
            value = value.toString();
            return value.charAt(0).toUpperCase() + value.slice(1);
        }
    }
});

var live_scoresheet_ws;
function start_live_scoresheet_ws() {
    live_scoresheet_ws = new WebSocket(stats_room_websocket_url);

    live_scoresheet_ws.onmessage = function (e) {
        vue_app.$data.quiz = JSON.parse( e.data );
    };

    live_scoresheet_ws.onclose = function (e) {
        start_live_scoresheet_ws();
    };
}
start_live_scoresheet_ws();
