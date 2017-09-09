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
    data: {
        title: 'Questions Editor',
        types: [ 'SQ', 'MA', 'CR', 'CVR', 'Q', 'FTV', 'FT', 'SIT' ],
        books: [
            'Matthew',
            'Mark',
            'Luke',
            'John',
            '1 Corinthians',
            '2 Corinthians',
            'Acts',
        ],
        question: {
            type: 'FTV',
            book: '1 Corinthians',
            chapter: '5',
            verse: '15',
            question: '\
                This is <span class="unique_phrase">some text</span>.\
                This is <span class="unique_word">even</span> <span class="unique_phrase">more text</span>.\
                And this is a <span class="unique_phrase"><span class="unique_chapter">special</span> word</span>.',
            answer: '\
                This is <span class="unique_phrase">some text</span>.\
                This is <span class="unique_word">even</span> <span class="unique_phrase">more text</span>.\
                And this is a <span class="unique_phrase"><span class="unique_chapter">special</span> word</span>.'
        },
        list: {
            books: [
                '1 Corinthians',
                '2 Corinthians',
            ],
            book: '1 Corinthians',
            chapters: [ 1, 2, 3, 4, 5 ],
            chapter: 3,
            questions: [
                { id: 1138, label: '1 (CR 0)' },
                { id: 1138, label: '1 (SQ 0)' },
                { id: 1138, label: '1 (SQ 0)' },
                { id: 1138, label: '1 (SQ 0)' },
                { id: 1138, label: '1 (SQ 0)' },
                { id: 1138, label: '2 (CVR 0)' },
                { id: 1138, label: '2 (MA 0)' },
                { id: 1138, label: '2 (SQ 0)' },
                { id: 1138, label: '2 (SQ 0)' },
                { id: 1138, label: '2 (SQ 0)' },
                { id: 1138, label: '2 (SQ 0)' },
                { id: 1138, label: '2 (SQ 0)' },
                { id: 1138, label: '3 (CR 0)' },
                { id: 1138, label: '3 (CR 0)' },
                { id: 1138, label: '3 (CVR 0)' },
                { id: 1138, label: '3 (SQ 0)' },
                { id: 1138, label: '3 (SQ 0)' },
                { id: 1138, label: '3 (SQ 0)' },
                { id: 1138, label: '3 (SQ 0)' },
                { id: 1138, label: '3 (SQ 0)' }
            ],
            question: ''
        }
    },
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
            this.$http.get('/editor/save').then( function (response) {
                this.question.answer = response.body.data.answer;
            } );
        }

    }
});

function setTitle(title) {
    document.title = 'CBQZ ' + title;
}

vm.$watch( 'title', function ( newVal, oldVal ) {
    setTitle(newVal);
} );

setTitle( vm.title );
