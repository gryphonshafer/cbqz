var beep = new Audio( cntlr + "/../beep.mp3" );

Vue.http.get( cntlr + "/data" ).then( function (response) {
    var data = response.body;
    data.lookup = {
        book    : null,
        chapter : null,
        verse   : null
    };
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
    data.quiz_view_hidden = 1;
    data.position         = 0;
    data.mean_score       = null;
    data.active_team      = {};
    data.active_quizzer   = {};
    data.timer            = {
        value : data.metadata.timer_default,
        state : "ready",
        label : "Start Timer",
    };
    data.classes = {
        cursor_progress : false
    };

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
                    this.lookup.book    = this.question.book;
                    this.lookup.chapter = this.question.chapter;
                    this.lookup.verse   = this.question.verse;
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

            result: function (result) {
                this.set_timer( this.metadata.timer_default );
                this.classes.cursor_progress = true;

                var result_data = result_operation( {
                    number  : this.question.number,
                    as      : this.question.as,
                    form    : "question",
                    result  : result,
                    quizzer : this.active_quizzer.name,
                    team    : this.active_team.name,
                    quiz    : JSON.parse( JSON.stringify( this.metadata.quiz_teams_quizzers ) )
                } );

                for ( var i = 0; i < this.metadata.quiz_teams_quizzers.length; i++ ) {
                    if ( this.active_team.name == this.metadata.quiz_teams_quizzers[i].team.name ) {
                        if ( !! result_data.team ) {
                            if ( ! this.metadata.quiz_teams_quizzers[i].team.events )
                                this.metadata.quiz_teams_quizzers[i].team.events = {};

                            this.metadata.quiz_teams_quizzers[i].team.score += result_data.team;

                            this.metadata.quiz_teams_quizzers[i].team.events[
                                this.question.number
                            ] = this.metadata.quiz_teams_quizzers[i].team.score;
                        }

                        for ( var j = 0; j < this.metadata.quiz_teams_quizzers[i].quizzers.length; j++ ) {
                            if (
                                this.active_quizzer.name ==
                                this.metadata.quiz_teams_quizzers[i].quizzers[j].name
                            ) {
                                if ( result == "success" )
                                        this.metadata.quiz_teams_quizzers[i].quizzers[j].correct++;
                                if ( result == "failure" )
                                        this.metadata.quiz_teams_quizzers[i].quizzers[j].incorrect++;

                                if ( !! result_data.label ) {
                                    if ( ! this.metadata.quiz_teams_quizzers[i].quizzers[j].events )
                                        this.metadata.quiz_teams_quizzers[i].quizzers[j].events = {};

                                    this.metadata.quiz_teams_quizzers[i].quizzers[j].events[
                                        this.question.number
                                    ] = result_data.label;
                                }
                                break;
                            }
                        }
                        break;
                    }
                }

                this.$http.post( cntlr + "/used", {
                    metadata : this.metadata,
                    question : this.question,
                    team     : this.active_team,
                    quizzer  : this.active_quizzer,
                    result   : result
                } ).then( function (response) {
                    this.active_team    = {};
                    this.active_quizzer = {};

                    this.question.used++;
                    this.move_question("forward");

                    this.question.as     = result_data.as;
                    this.question.number = result_data.number;

                    this.classes.cursor_progress = false;

                    if ( ! response.body.success ) {
                        alert(
                            "There was an error updating the used count for the question.\n" +
                            response.body.error + "."
                        );
                    }
                    else {
                        this.quiz_questions.unshift( response.body.quiz_question );
                    }
                } );
            },

            team_event: function ( team_name, event_type ) {
                var challenge_accepted  = false;
                var event_symbol        = event_type.substr( 0, 1 ).toUpperCase();
                var event_symbol_suffix = "";

                if ( event_type == "timeout" ) {
                    this.set_timer( this.metadata.timer_default * 2 );
                    this.timer_click();
                }
                if ( event_type == "challenge" ) {
                    challenge_accepted = confirm(
                        "Did you accept the challenge? Click \"OK\".\n" +
                        "Did you decline the challenge? Click \"Cancel\"."
                    );
                    event_symbol_suffix = (challenge_accepted) ? "+" : "-";
                }

                this.classes.cursor_progress = true;

                var event_key =
                    Date.now().toString().substr( 4, 6 ) +
                    Math.round( Math.random() * 1000 + 1000 ) +
                    "|" +
                    event_symbol;

                for ( var i = 0; i < this.metadata.quiz_teams_quizzers.length; i++ ) {
                    if ( team_name == this.metadata.quiz_teams_quizzers[i].team.name ) {
                        if ( ! this.metadata.quiz_teams_quizzers[i].team.events )
                            this.metadata.quiz_teams_quizzers[i].team.events = {};

                        this.metadata.quiz_teams_quizzers[i].team.events[event_key] =
                            event_symbol + event_symbol_suffix;
                    }
                }

                var event_data = {
                    metadata        : this.metadata,
                    team            : team_name,
                    form            : event_type,
                    question_number : event_key
                };
                if ( event_type == "challenge" ) {
                    event_data["result"] = (challenge_accepted) ? "success" : "failure";
                }

                this.$http.post( cntlr + "/team_event", event_data ).then( function (response) {
                    this.classes.cursor_progress = false;

                    if ( ! response.body.success ) {
                        alert(
                            "There was an error recording the " + event_type + " to the server.\n" +
                            response.body.error + "."
                        );
                    }
                    else {
                        this.quiz_questions.unshift( response.body.quiz_question );
                    }
                } );
            },

            delete_quiz_event: function (question_number) {
                if ( confirm("Are you sure you want to delete this quiz event?") ) {
                    this.classes.cursor_progress = true;

                    for ( var i = 0; i < this.metadata.quiz_teams_quizzers.length; i++ ) {
                        if ( !! this.metadata.quiz_teams_quizzers[i].team.events )
                            delete this.metadata.quiz_teams_quizzers[i].team.events[question_number];

                        for ( var j = 0; j < this.metadata.quiz_teams_quizzers[i].quizzers.length; j++ ) {
                            if ( !! this.metadata.quiz_teams_quizzers[i].quizzers[j].events )
                                delete this.metadata.quiz_teams_quizzers[i].quizzers[j].events[question_number];
                        }
                    }

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
                        else {
                            for ( var i = 0; i < this.quiz_questions.length; i++ ) {
                                if ( this.quiz_questions[i].question_number == question_number )
                                    this.quiz_questions.splice( i, 1 );
                            }
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
                this.lookup.book    = book;
                this.lookup.chapter = chapter;
                this.lookup.verse   = verse;
            },

            search_reference_click: function (verse) {
                this.lookup.book    = verse.book;
                this.lookup.chapter = verse.chapter;
                this.lookup.verse   = verse.verse;
            },

            select_quizzer: function ( team, quizzer ) {
                this.active_team    = team;
                this.active_quizzer = quizzer;

                if ( this.timer.state != "running" ) this.timer_click();
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
            if ( this.questions.length > 0 ) {
                if ( this.quiz_questions.length == 0 ) {
                    this.question        = this.questions[ this.position ];
                    this.question.number = 1;
                    this.question.as     = this.metadata.as_default;
                }
                else {
                    var reverse_quiz_questions = this.quiz_questions.slice().reverse();

                    for ( var i = 0; i < reverse_quiz_questions.length; i++ ) {
                        if ( reverse_quiz_questions[i].form == "question" ) {
                            var as     = this.questions[i].as     = reverse_quiz_questions[i].question_as;
                            var number = this.questions[i].number = reverse_quiz_questions[i].question_number;

                            // TODO: probably need to remove this entirely and clean up
                            var result_data = result_operation( {
                                as      : as,
                                number  : number,
                                result  : reverse_quiz_questions[i].result,
                                quizzer : reverse_quiz_questions[i].quizzer,
                                team    : reverse_quiz_questions[i].team,
                                quiz    : JSON.parse( JSON.stringify( this.metadata.quiz_teams_quizzers ) )
                            } );

                            this.move_question("forward");

                            this.question.as     = result_data.as;
                            this.question.number = result_data.number;
                        }
                    }
                }
            }

            if ( this.error ) {
                this.question.question = '<span class="unique_chapter">' + this.error + '.</span>';
                this.question.answer   = '<span class="unique_chapter">' + this.error + '.</span>';
            }
        }
    });

    document.addEventListener( "keyup", function(event) {
        event.preventDefault();

        // for Alt+G, F2: Lookup Verse
        if ( ( event.altKey && event.keyCode == 71 ) || event.keyCode == 113 )
            document.getElementById("lookup").click();

        // for Alt+T: Prompt for Reference
        if ( event.altKey && event.keyCode == 84 )
            vue_app.$refs.material_lookup.enter_reference();

        // for Alt+F, F4: Find Text
        if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
            vue_app.$refs.material_search.find();
        
        // for Alt+S: Start Timer
        if ( event.altKey && event.keyCode == 83 )
            document.getElementById("timer_click").click();

        // for Alt+C: Correct
        if ( event.altKey && event.keyCode == 67 )
            document.getElementById("correct").click();

        // for Alt+E: Error
        if ( event.altKey && event.keyCode == 69 )
            document.getElementById("error").click();

        // for Alt+N: No Jump
        if ( event.altKey && event.keyCode == 78 )
            document.getElementById("no_jump").click();
    } );
});
