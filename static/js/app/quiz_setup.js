Vue.http.get( cntlr + "/quiz_setup" ).then( function (response) {
    var data = response.body;

    new Vue({
        el: "#quiz_setup",
        data: data,
        methods: {
            chapter_clicked: function (chapter) {
                chapter.selected = ! chapter.selected;
                this.save_settings();
            },
            select_chapters: function (type) {
                var chapters = this.question_set.statistics;
                var state    = ( type == "all" ) ? true : false;

                for ( var i = 0; i < chapters.length; i++ ) {
                    chapters[i].selected = state;
                }
                this.save_settings();
            },
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
                        selected_chapters: selected_chapters,
                        program_id: this.program_id,
                        question_set_id: this.question_set_id,
                        material_set_id: this.material_set_id,
                        weight_chapters: this.weight_chapters,
                        weight_percent: this.weight_percent
                    },
                    65535
                );
            },
            start_quiz: function () {
                document.location.href = cntlr + "/quiz";
            }
        },

        computed: {
            selected_chapters_count: function () {
                var chapters = this.question_set.statistics;
                var count    = 0;

                for ( var i = 0; i < chapters.length; i++ ) {
                    if ( chapters[i].selected ) count++;
                }

                return count;
            }
        },

        watch: {
            weight_chapters: function () { this.save_settings() },
            weight_percent:  function () { this.save_settings() }
        }
    });
});
