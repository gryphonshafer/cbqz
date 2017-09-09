Vue.config.keyCodes.v = 86;

Vue.config.keyCodes.q = 81;
Vue.config.keyCodes.w = 87;
Vue.config.keyCodes.e = 69;
Vue.config.keyCodes.r = 82;

Vue.config.keyCodes.b = 66;
Vue.config.keyCodes.u = 85;
Vue.config.keyCodes.i = 73;

Vue.config.keyCodes.a = 65;
Vue.config.keyCodes.s = 83;
Vue.config.keyCodes.x = 88;
Vue.config.keyCodes.c = 67;

var vm = new Vue({
    el: "#app",
    data: data,
    methods: {

        format: function (className) {
            var selection = document.getSelection();

            if ( selection.rangeCount > 0 && selection.isCollapsed == 0 ) {

                for ( var i = 0; i < selection.rangeCount; i++ ) {
                    var range       = selection.getRangeAt(i);
                    var replacement = document.createTextNode( range.toString() );

                    if (className) {
                        var span = document.createElement('span');
                        span.className = className;
                        span.appendChild(replacement);
                        replacement = span;
                    }

                    range.deleteContents();
                    range.insertNode(replacement);
                }

                this.question.question = this.$refs.question.innerHTML;
                this.question.answer   = this.$refs.answer.innerHTML;
            }
        },

        save: function () {
            this.$http.post( cntlr + '/save', this.question ).then( function (response) {
                this.question = response.body.question;
            } );
        },
    }
});

function setTitle(title) {
    document.title = 'CBQZ ' + title;
}

vm.$watch( 'title', function ( newVal, oldVal ) {
    setTitle(newVal);
} );

setTitle( vm.title );
