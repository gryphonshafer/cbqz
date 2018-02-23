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

                this.set_weighted_chapters();

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
            set_weighted_chapters: function () {
                var weight_chapters_remaining = this.weight_chapters;
                for ( var i = this.question_set.statistics.length - 1; i >= 0; i-- ) {
                    this.question_set.statistics[i].weighted = false;

                    if ( weight_chapters_remaining > 0 && this.question_set.statistics[i].selected ) {
                        this.question_set.statistics[i].weighted = true;
                        weight_chapters_remaining--;
                    }
                }
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

                if ( this.weight_chapters > count ) this.weight_chapters = count;
                return count;
            }
        },

        watch: {
            weight_chapters: function () { this.save_settings() },
            weight_percent:  function () { this.save_settings() },
        },

        created: function () {
            this.set_weighted_chapters();
        }
    });
});
