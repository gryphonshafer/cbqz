Vue.http.get( cntlr + "/data" ).then( function (response) {
    var data = response.body;
    data.question_set = null;

    new Vue({
        el: "#main",
        data: data,
        methods: {
            save_settings: function () {
                var selected_chapters = [];
                if ( !! this.question_set ) {
                    selected_chapters = this.question_set.statistics.filter( function (chapter) {
                        return chapter.selected == true;
                    } ).map( function (chapter) {
                        return {
                            book: chapter.book,
                            chapter: chapter.chapter
                        };
                    } );
                }

                set_json_cookie(
                    "cbqz_prefs",
                    {
                        program_id: this.program_id,
                        question_set_id: this.question_set_id,
                        material_set_id: this.material_set_id,
                    },
                    65535
                );
            },
            set_question_set: function () {
                var question_set_id = this.question_set_id;

                var question_set = this.question_sets.find( function(set) {
                    return question_set_id == set.question_set_id;
                } );

                this.question_set = question_set;
            },
            sort_question_set: function () {
                var material_set_id = this.material_set_id;
                var material_set    = this.material_sets.find( function(set) {
                    return material_set_id == set.material_set_id;
                } );

                if ( material_set.book_order ) {
                    var book_order = JSON.parse( material_set.book_order );

                    var book_order_map = {};
                    for ( var i = 0; i < book_order.length; i++ ) {
                        book_order_map[ book_order[i] ] = i;
                    }

                    this.question_set.statistics = this.question_set.statistics.sort( function ( a, b ) {
                        if ( book_order_map[ a.book ] < book_order_map[ b.book ] ) return -1;
                        if ( book_order_map[ a.book ] > book_order_map[ b.book ] ) return 1;
                        if ( a.chapter < b.chapter ) return -1;
                        if ( a.chapter > b.chapter ) return 1;
                        return 0;
                    } );
                }
            }
        },

        watch: {
            question_set_id: function () {
                this.set_question_set();
                this.save_settings();
                this.sort_question_set();
            },
            program_id:      function () { this.save_settings() },
            material_set_id: function () {
                this.save_settings();
                this.sort_question_set();
            },
        },

        mounted: function () {
            if ( ! this.program_id ) this.program_id = this.programs[0].program_id;
            if ( ! this.material_set_id ) this.material_set_id = this.material_sets[0].material_set_id;
            if ( ! this.question_set_id ) {
                for ( var i = 0; i < this.question_sets[0].statistics.length; i++ ) {
                    this.question_sets[0].statistics[i].selected = true;
                }
                this.question_set_id = this.question_sets[0].question_set_id;
            }
            else {
                this.set_question_set();
            }
            this.sort_question_set();
        }
    });
});
