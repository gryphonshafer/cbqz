var beep = new Audio( cntlr + "/../beep.mp3" );

Vue.http.get( cntlr + "/data" ).then( function (response) {
    var data = response.body;
    data.question = {
        number   : null,
        type     : null,
        as       : null,
        used     : null,
        book     : null,
        chapter  : null,
        verse    : null,
        question : null,
        answer   : null,
        marked   : null,
        score    : null
    };
    data.quiz_view_hidden          = 1;
    data.rearrange_quizzers_hidden = 1;
    data.rearrange_quizzers_data   = "";
    data.set_score_type            = "";
    data.position                  = 0;
    data.mean_score                = null;
    data.active_team               = {};
    data.active_quizzer            = {};
    data.timer                     = {
        value : data.metadata.timer_default,
        state : "ready",
        label : "Start Timer",
    };
    data.classes = {
        cursor_progress : false
    };
    if ( ! data.metadata.quiz_teams_quizzers_original )
        data.metadata.quiz_teams_quizzers_original =
        JSON.parse( JSON.stringify( data.metadata.quiz_teams_quizzers ) );

    function result_operation_process ( vue_obj, input, skip_post_processing ) {
        if ( !! input.team ) {
            var filtered_teams = vue_obj.metadata.quiz_teams_quizzers.filter( function (value) {
                return value.team.name == input.team;
            } )[0];
            input.team     = filtered_teams.team;
            input.quizzers = filtered_teams.quizzers;

            if ( !! input.quizzer )
                input.quizzer = filtered_teams.quizzers.filter( function (value) {
                    return value.name == input.quizzer;
                } )[0];
        }

        input.quiz     = vue_obj.metadata.quiz_teams_quizzers;
        input.history  = vue_obj.quiz_questions;
        input.sk_type  = vue_obj.metadata.score_type;
        input.sk_types = vue_obj.metadata.score_types;

        var result_data = result_operation( JSON.parse( JSON.stringify(input) ) );

        if ( !! result_data.sk_type ) vue_obj.metadata.score_type = result_data.sk_type;

        if ( ! skip_post_processing ) {
            for ( var i = 0; i < vue_obj.metadata.quiz_teams_quizzers.length; i++ ) {
                if ( !! input.team && input.team.name == vue_obj.metadata.quiz_teams_quizzers[i].team.name ) {
                    if ( !! result_data.team || !! result_data.team_label ) {
                        if ( ! vue_obj.metadata.quiz_teams_quizzers[i].team.events )
                            vue_obj.metadata.quiz_teams_quizzers[i].team.events = {};

                        if ( !! result_data.team )
                            vue_obj.metadata.quiz_teams_quizzers[i].team.score += result_data.team;

                        vue_obj.metadata.quiz_teams_quizzers[i].team.events[
                            input.number
                        ] = ( !! result_data.team_label )
                            ? result_data.team_label
                            : vue_obj.metadata.quiz_teams_quizzers[i].team.score;
                    }

                    for ( var j = 0; j < vue_obj.metadata.quiz_teams_quizzers[i].quizzers.length; j++ ) {
                        if (
                            input.quizzer &&
                            input.quizzer.name ==
                            vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].name
                        ) {
                            if ( input.form == "question" && ! result_data.skip_counts ) {
                                if ( input.result == "success" ) {
                                    vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].correct++;
                                    vue_obj.metadata.quiz_teams_quizzers[i].team.correct++;
                                }
                                if ( input.result == "failure" ) {
                                    vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].incorrect++;
                                    vue_obj.metadata.quiz_teams_quizzers[i].team.incorrect++;
                                }
                            }

                            if ( !! result_data.label ) {
                                if ( ! vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].events )
                                    vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].events = {};

                                vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].events[
                                    input.number
                                ] = result_data.label;
                            }

                            if ( !! result_data.quizzer )
                                vue_obj.metadata.quiz_teams_quizzers[i].quizzers[j].score += result_data.quizzer;

                            break;
                        }
                    }
                    break;
                }
            }
        }

        return result_data;
    }

    var vue_app = new Vue({
        el: "#quizroom",
        data: data,
        methods: {
            lookup_reference: function () {
                if (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) {
                    this.$refs.material_lookup.lookup_reference(
                        this.question.book,
                        this.question.chapter,
                        this.question.verse
                    );
                }
                else {
                    alert("Incomplete reference; lookup not possible.");
                }
            },

            move_question: function (target) {
                if ( target == parseInt(target) ) {
                    target--;
                    if ( target >= 0 && target < this.questions.length ) {
                        this.position = target;
                        this.question = this.questions[ this.position ];
                    }
                }
                else {
                    var direction = 0;
                    if ( target.substr( 0, 1 ).toLowerCase() == "b" ) {
                        direction = -1;
                    }
                    else {
                        direction = 1;
                    }
                    if (
                        this.position + direction > -1 &&
                        this.position + direction < this.questions.length
                    ) {
                        this.position += direction;
                        this.question = this.questions[ this.position ];
                    }
                }
            },

            toggle_quiz_view: function () {
                this.quiz_view_hidden = ! this.quiz_view_hidden;
            },

            toggle_rearrange_quizzers: function (save) {
                if ( this.rearrange_quizzers_hidden ) {
                    var build_string    = "";
                    this.set_score_type = this.metadata.score_type;

                    for ( var i = 0; i < this.metadata.quiz_teams_quizzers.length; i++ ) {
                        if ( build_string.length > 0 ) build_string = build_string + "\n\n";
                        build_string = build_string + this.metadata.quiz_teams_quizzers[i].team.name;

                        for ( var j = 0; j < this.metadata.quiz_teams_quizzers[i].quizzers.length; j++ ) {
                            build_string = build_string + "\n" +
                                this.metadata.quiz_teams_quizzers[i].quizzers[j].bib + ". " +
                                this.metadata.quiz_teams_quizzers[i].quizzers[j].name;
                        }
                    }

                    this.rearrange_quizzers_data = build_string + "\n";
                }
                else if (save) {
                    this.classes.cursor_progress = true;
                    this.metadata.score_type     = this.set_score_type;

                    this.$http.post( cntlr + "/rearrange_quizzers", {
                        metadata      : this.metadata,
                        quizzers_data : this.rearrange_quizzers_data
                    } ).then( function (response) {
                        this.classes.cursor_progress = false;

                        if ( ! response.body.success ) {
                            alert(
                                "There was an error processing the rearrange quizzers request.\n" +
                                response.body.error + "."
                            );
                        }
                        else {
                            this.metadata.quiz_teams_quizzers = response.body.quiz_teams_quizzers;
                        }
                    } );
                }

                this.rearrange_quizzers_hidden = ! this.rearrange_quizzers_hidden;
            },

            make_beep: function () {
                beep.play();
            },

            timer_click: function () {
                if ( this.timer.state == "ready" || this.timer.state == "stopped" ) {
                    this.timer.state = "running";
                    this.timer.label = "Stop Timer";
                    this.timer_tick();
                }
                else if ( this.timer.state == "running" ) {
                    this.timer.state = "stopped";
                    this.timer.label = "Continue";
                }
                else if ( this.timer.state == "ended" ) {
                    this.timer.state = "ready";
                    this.timer.value = this.metadata.timer_default;
                    this.timer.label = "Start Timer";
                }
            },

            timer_tick: function () {
                var self = this;

                setTimeout( function () {
                    if ( self.timer.state == "running" ) {
                        self.timer.value--;

                        if ( self.timer.value > 0 ) {
                            self.timer_tick();
                        }
                        else {
                            self.make_beep();
                            self.timer.state = "ended";
                            self.timer.label = "Reset";
                        }
                    }
                }, 1000 );
            },

            set_timer: function (value) {
                this.timer.state = "ready";
                this.timer.label = "Start Timer";
                this.timer.value = value;
            },

            quiz_event: function ( type, team ) {
                var form = (
                    type == "success" ||
                    type == "failure" ||
                    type == "none"
                ) ? "question" : type;

                var confirmation = false;

                if ( type == "timeout" ) {
                    this.set_timer( this.metadata.timeout );
                    this.timer_click();
                }
                else {
                    this.set_timer( this.metadata.timer_default );
                }

                if ( type == "challenge" ) {
                    confirmation = confirm(
                        "Did you accept the challenge? Click \"OK\".\n" +
                        "Did you decline the challenge? Click \"Cancel\"."
                    );
                }

                this.classes.cursor_progress = true;

                var event_data = {
                    team   : ( (team) ? team.name : this.active_team.name ),
                    form   : form,
                    number : ( form == "question" )
                        ? this.question.number
                        : Date.now().toString().substr( 4, 6 ) +
                            Math.round( Math.random() * 1000 + 1000 ) +
                            "|" +
                            type.substr( 0, 1 ).toUpperCase()
                };

                if ( form == "question" ) {
                    event_data["result"]  = type;
                    event_data["quizzer"] = this.active_quizzer.name;
                    event_data["as"]      = this.question.as;
                }
                else if ( type == "foul" || type == "sub-in" || type == "sub-out" ) {
                    event_data["quizzer"] = this.active_quizzer.name;
                }
                else if ( type == "challenge" ) {
                    event_data["result"] = (confirmation) ? "success" : "failure";
                }

                var result_data = result_operation_process( this, event_data );

                this.$http.post( cntlr + "/quiz_event", {
                    metadata   : this.metadata,
                    question   : this.question,
                    event_data : event_data
                } ).then( function (response) {
                    this.active_team    = {};
                    this.active_quizzer = {};

                    if ( form == "question" ) {
                        this.question.used++;
                        this.move_question("forward");

                        this.question.as     = result_data.as;
                        this.question.number = result_data.number;

                        this.$http.post( cntlr + "/status", {
                            quiz_id         : this.metadata.quiz_id,
                            question_number : this.question.number
                        } );
                    }

                    this.classes.cursor_progress = false;

                    if ( ! response.body.success ) {
                        alert(
                            "There was an error communicating with the server.\n" +
                            response.body.error + "."
                        );
                    }
                    else {
                        this.quiz_questions.unshift( response.body.quiz_question );
                        if ( !! result_data.message ) alert( result_data.message );
                    }
                } );
            },

            delete_quiz_event: function (question_number) {
                if ( confirm("Are you sure you want to delete this quiz event?") ) {
                    this.classes.cursor_progress = true;

                    this.metadata.quiz_teams_quizzers =
                        JSON.parse( JSON.stringify( this.metadata.quiz_teams_quizzers_original ) );

                    this.quiz_questions.shift();
                    this.quiz_build_up();

                    this.$http.post( cntlr + "/delete_quiz_event", {
                        metadata        : this.metadata,
                        question_number : question_number
                    } ).then( function (response) {
                        this.classes.cursor_progress = false;

                        if ( ! response.body.success ) {
                            alert(
                                "There was an error deleting this quiz event.\n" +
                                response.body.error + "."
                            );
                        }
                    } );
                }
            },

            mark_for_edit: function () {
                var reason = prompt( "Enter comment about this question:", "Contains an error" );
                if (reason) {
                    this.classes.cursor_progress = true;

                    this.$http.post(
                        cntlr + "/mark",
                        {
                            question_id: this.question.question_id,
                            reason:      reason
                        }
                    ).then( function (response) {
                        this.classes.cursor_progress = false;
                        if ( response.body.success ) {
                            this.question.marked = reason;
                        }
                        else {
                            alert(
                                "There was an error marking the question for edit.\n" +
                                response.body.error + "."
                            );
                        }
                    } );
                }
            },

            print_quiz: function () {
                var question_ids = [];
                for ( var i = 0; i < this.questions.length; i++ ) {
                    question_ids.push( this.questions[i].question_id );
                }

                window.open(
                    cntlr +
                    "/../editor/questions?quiz=" + btoa( JSON.stringify(question_ids) ),
                    "_blank"
                );
            },

            exit_quiz: function () {
                document.location.href = cntlr;
            },

            close_quiz: function () {
                if ( confirm("Are you sure you want to close this quiz?") ) {
                    document.location.href = cntlr + "/close?quiz_id=" + this.metadata.quiz_id;
                }
            },

            replace: function (type) {
                this.classes.cursor_progress = true;
                this.$http.post(
                    cntlr + "/replace",
                    {
                        type      : type,
                        questions : this.questions,
                        position  : this.position,
                        quiz_id   : this.metadata.quiz_id
                    }
                ).then( function (response) {
                    this.classes.cursor_progress = false;
                    if ( response.body.error ) {
                        alert(
                            "Unable to replace question.\n" +
                            response.body.error
                        );
                    }
                    else {
                        var question = response.body.question;

                        question.as     = this.question.as;
                        question.number = this.question.number;

                        this.question = this.questions[ this.position ] = question;
                        this.set_type_counts();
                    }
                } );
            },

            set_type_counts: function () {
                var ranges    = this.metadata.type_ranges;
                var questions = this.questions;

                for ( var i = 0; i < ranges.length; i++ ) {
                    ranges[i][3] = [];
                    ranges[i][4] = 0;
                }
                for ( var i = 0; i < questions.length; i++ ) {
                    for ( var j = 0; j < ranges.length; j++ ) {
                        var match = ranges[j][0].find( function (element) {
                            return element == questions[i].type;
                        } );
                        if ( !! match ) ranges[j][4]++;
                        ranges[j][3][i] = ranges[j][4];
                    }
                }

                var mean_score = 0;
                for ( var i = 0; i < this.questions.length; i++ ) {
                    mean_score += parseFloat( this.questions[i].score );
                }
                this.mean_score = Number( mean_score / this.questions.length ).toFixed(1);
            },

            lookup_reference_change: function ( book, chapter, verse ) {
                this.$refs.material_search.set_selected_ref(
                    book,
                    chapter,
                    verse
                );
            },

            search_reference_click: function (verse) {
                this.$refs.material_lookup.lookup_reference(
                    verse.book,
                    verse.chapter,
                    verse.verse
                );
            },

            select_quizzer: function ( team, quizzer ) {
                this.active_team    = team;
                this.active_quizzer = quizzer;

                if ( this.timer.state != "running" ) this.timer_click();

                this.$http.post( cntlr + "/status", {
                    quiz_id         : this.metadata.quiz_id,
                    question_number : this.question.number,
                    team            : this.active_team,
                    quizzer         : this.active_quizzer
                } );
            },

            reset_quiz_select: function () {
                this.active_team    = {};
                this.active_quizzer = {};

                this.set_timer( this.metadata.timer_default );

                this.$http.post( cntlr + "/status", {
                    quiz_id         : this.metadata.quiz_id,
                    question_number : this.question.number
                } );
            },

            quiz_build_up: function (skip_post_processing) {
                this.position        = 0;
                this.question        = this.questions[0];
                this.question.number = 1;
                this.question.as     = this.metadata.as_default;

                var reverse_quiz_questions = this.quiz_questions.slice().reverse();
                for ( var i = 0; i < reverse_quiz_questions.length; i++ ) {
                    var result_data = result_operation_process(
                        this,
                        {
                            number  : this.question.number,
                            as      : this.question.as,
                            form    : reverse_quiz_questions[i].form,
                            result  : reverse_quiz_questions[i].result,
                            quizzer : reverse_quiz_questions[i].quizzer,
                            team    : reverse_quiz_questions[i].team
                        },
                        skip_post_processing
                    );

                    this.move_question("forward");

                    this.question.as     = result_data.as;
                    this.question.number = result_data.number;
                }

                this.$http.post( cntlr + "/status", {
                    quiz_id         : this.metadata.quiz_id,
                    question_number : this.question.number
                } );
            }
        },
        computed: {
            verse_incomplete: function () {
                return (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) ? false : true;
            }
        },
        watch: {
            "question.question_id": function () {
                this.lookup_reference();
            }
        },
        created: function () {
            this.set_type_counts();
        },
        mounted: function () {
            if ( ! this.error ) {
                this.quiz_build_up(true);
            }
            else {
                this.question.question = '<span class="unique_chapter">' + this.error + '</span>';
                this.question.answer   = '<span class="unique_chapter">' + this.error + '</span>';
            }
        }
    });

    document.addEventListener( "keyup", function(event) {
        event.preventDefault();

        // for Alt+G, F2: Lookup Verse
        if ( ( event.altKey && event.keyCode == 71 ) || event.keyCode == 113 )
            document.getElementById("lookup").click();

        // for Alt+T: Prompt for Reference
        if ( event.altKey && event.keyCode == 84 ) vue_app.$refs.material_lookup.enter_reference();

        // for Alt+F, F4: Find Text
        if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
            vue_app.$refs.material_search.find(true);

        // for Alt+S: Timer Click
        if ( event.altKey && event.keyCode == 83 ) document.getElementById("prime_timer_button").click();

        // for Alt+C: Correct
        if ( event.altKey && event.keyCode == 67 ) document.getElementById("button_correct").click();

        // for Alt+E: Error
        if ( event.altKey && event.keyCode == 69 ) document.getElementById("button_error").click();

        // for Alt+N: No Jump
        if ( event.altKey && event.keyCode == 78 ) document.getElementById("button_no_jump").click();
    } );
});
