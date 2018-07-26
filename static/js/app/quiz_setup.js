Vue.http.get( cntlr + "/quiz_setup" ).then( function (response) {
    var data = response.body;

    data.official       = false;
    data.save_for_later = false;

    var cbqz_prefs = get_json_cookie("cbqz_prefs");
    data.question_types = ( !! cbqz_prefs && !! cbqz_prefs.question_types )
        ? cbqz_prefs.question_types
        : data.program_question_types;

    if ( ! data.quiz_teams_quizzers ) {
        var teams_count   = 3;
        var team_size     = 4;
        var quizzer_names = new Array(
            "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Gulf", "Hotel", "India", "Juliet",
            "Kilo", "Lima", "Mike", "November", "Oscar", "Papa", "Quebec", "Romeo", "Sierra", "Tango",
            "Uniform", "Victor", "Whiskey", "X-ray", "Yankee", "Zulu"
        );
        data.quiz_teams_quizzers = "";
        for ( var code = 65; code < 65 + teams_count; code++ ) {
            if ( data.quiz_teams_quizzers.length > 0 ) data.quiz_teams_quizzers += "\n\n";
            data.quiz_teams_quizzers += "Team " + String.fromCharCode(code);
            for ( var bib = 1; bib <= team_size; bib++ ) {
                data.quiz_teams_quizzers += "\n" + bib + ". " + quizzer_names.shift() + " Quizzer";
            }
        }
    }

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
                        weight_percent: this.weight_percent,
                        question_types: this.question_types
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
            reset_question_types: function () {
                this.question_types = this.program_question_types;
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
            },
            not_generate_ready: function () {
                return (
                    this.name.length > 0 &&
                    this.quizmaster.length > 0 &&
                    this.scheduled.length > 0 &&
                    this.question_types.length > 0 &&
                    this.quiz_teams_quizzers.length > 0 &&
                    this.target_questions > 0 &&
                    this.timer_default > 0 &&
                    this.timer_values.length > 0 &&
                    this.selected_chapters_count > 0
                ) ? false : true;
            },
            can_reset_question_types: function () {
                return ( this.question_types != this.program_question_types ) ? true : false;
            },
        },

        watch: {
            weight_chapters: function () { this.save_settings() },
            weight_percent:  function () { this.save_settings() },
            question_types:  function () { this.save_settings() }
        },

        created: function () {
            this.set_weighted_chapters();
        },

        mounted: function () {
            this.save_settings();
        }
    });
});
