document.addEventListener( "keyup", function(event) {
    event.preventDefault();

    // for Alt+G, F2: Lookup Verse
    if ( ( event.altKey && event.keyCode == 71 ) || event.keyCode == 113 )
        document.getElementById("lookup").click();

    // for Alt+F, F4: Find Text
    if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
        document.getElementById("find").click();
} );

var beep = new Audio( cntlr + "/../beep.mp3" );

Vue.http.get( cntlr + "/data" ).then( function (response) {
    new Vue({
        el: "#quizroom",
        data: response.body,
        methods: {
            lookup: function () {
                if (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) {
                    this.material.book = this.question.book;
                    this.$nextTick( function () {
                        this.material.chapter = this.question.chapter;
                        this.$nextTick( function () {
                            this.material.verse = this.question.verse;
                        } );
                    } );
                }
                else {
                    alert("Incomplete reference; lookup not possible.");
                }
            },
            find: function () {
                var selection = document.getSelection();
                if ( selection.rangeCount > 0 && selection.isCollapsed == 0 ) {
                    var search_text = "";
                    for ( var i = 0; i < selection.rangeCount; i++ ) {
                        search_text = search_text + selection.getRangeAt(i).toString();
                    }

                    this.material.search = search_text;
                }
            },
            lookup_from_search: function (verse) {
                this.material.book = verse.book;
                this.$nextTick( function () {
                    this.material.chapter = verse.chapter;
                    this.$nextTick( function () {
                        this.material.verse = verse.verse;
                    } );
                } );
            },
            setup_question: function () {
                this.question        = this.questions[ this.position ];
                this.question.number = 1;
                this.question.as     = this.metadata.as_default;
            },
            move_question: function(direction) {
                if ( this.position + direction > -1 && this.position + direction < this.questions.length ) {
                    this.position += direction;
                    this.question = this.questions[ this.position ];
                }
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

                this.$http.post( cntlr + "/used", { question_id: this.question.question_id } );
                this.question.used++;

                var as     = this.question.as;
                var number = this.question.number;

                this.move_question(1);

                var as_number        = result_operation( result, as, number );
                this.question.as     = as_number.as;
                this.question.number = as_number.number;
            },
            mark_for_edit: function () {
                var reason = prompt( "Enter comment about this question:", "Contains an error" );
                if (reason) {
                    this.$http.post(
                        cntlr + "/mark",
                        {
                            question_id: this.question.question_id,
                            reason:      reason
                        }
                    ).then( function (response) {
                        this.question.marked = reason;
                    } );
                }
            },
            replace: function (type) {
                this.$http.post(
                    cntlr + "/replace",
                    {
                        type:      type,
                        questions: this.questions
                    }
                ).then( function (response) {
                    if ( response.body.error ) {
                        alert("Unable to replace with that type. Try another.");
                    }
                    else {
                        var question = response.body.question;

                        question.as     = this.question.as;
                        question.number = this.question.number;

                        this.question = this.questions[ this.position ] = question;
                    }
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
            "material.book": function () {
                this.material.chapters = Object.keys( this.material.data[ this.material.book ] ).sort(
                    function ( a, b ) {
                        return a - b;
                    }
                );

                this.material.chapter = null;
                this.$nextTick( function () {
                    this.material.chapter = this.material.chapters[0];
                } );
            },
            "material.chapter": function () {
                if ( !! this.material.chapter ) {
                    this.material.verses = this.material.data[ this.material.book ][ this.material.chapter ];
                    this.material.verse  = this.material.verses[1].verse;
                }
            },
            "material.verse": function () {
                this.$nextTick( function () {
                    window.location.href = "#v" + this.material.verse;
                } );
            },
            "material.search": function () {
                this.material.matched_verses = [];

                if ( this.material.search.length > 2 ) {
                    var search_term = this.material.search.toLowerCase().replace( /\W+/g, "" );

                    var books = Object.keys( this.material.data ).sort();
                    for ( var i = 0; i < books.length; i++ ) {
                        var chapters = Object.keys( this.material.data[ books[i] ] ).sort(
                            function ( a, b ) {
                                return a - b;
                            }
                        );

                        for ( var j = 0; j < chapters.length; j++ ) {
                            var verses = this.material.data[ books[i] ][ chapters[j] ];
                            var verse_numbers = Object.keys(verses).sort();

                            for ( var k = 0; k < verse_numbers.length; k++ ) {
                                var verse_number = verse_numbers[k];

                                if ( verses[verse_number].search.indexOf( search_term ) != -1 ) {
                                    this.material.matched_verses.push( verses[verse_number] );
                                }
                            }
                        }
                    }
                }
            }
        },
        mounted: function () {
            this.material.books = Object.keys( this.material.data );
            this.material.book  = this.material.books[0];

            if ( this.questions.length > 0 ) this.setup_question();

            if ( this.error ) {
                this.question.question = '<span class="unique_chapter">' + this.error + '.</span>';
                this.question.answer   = '<span class="unique_chapter">' + this.error + '.</span>';
            }
        }
    });
});
