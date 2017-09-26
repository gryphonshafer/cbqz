document.addEventListener( "keyup", function(event) {
    event.preventDefault();

    // for Alt+G, F2: Lookup Verse
    if ( ( event.altKey && event.keyCode == 71 ) || event.keyCode == 113 )
        document.getElementById("lookup").click();

    // for Alt+F, F4: Find Text
    if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
        document.getElementById("find").click();
} );

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
                else {
                    alert("No text selected to conduct a find for.");
                }
            },
            copy_verse: function () {
                if (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) {
                    this.questions.question_id = null;

                    var verse = this.material.data
                        [ this.question.book ][ this.question.chapter ][ this.question.verse ];

                    this.question.question = "";
                    this.question.answer   = "";

                    this.$nextTick( function () {
                        this.question.question = verse.text;
                        this.question.answer   = verse.text;
                    } );

                    this.question.question_id = null;
                    this.question.used        = null;
                    this.question.type        = null;
                }
                else {
                    alert("Incomplete reference; copy verse not possible.");
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
                this.question.as     = "Standard";
            },
            move_question: function(direction) {
                if ( this.position + direction > -1 && this.position + direction < this.questions.length ) {
                    this.position += direction;
                    this.question = this.questions[ this.position ];
                }
            },
            make_beep: function () {
                var snd = new Audio("data:audio/wav;base64,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qJrx4KOQjahZxWbcZgztj2c49nKmkId44S71j0c8eV9yDK6uPRzx5X18eDvjvQ6yKo9ZSS6l//8elePK/Lf//IInrOF/FvDoADYAGBMGb7FtErm5MXMlmPAJQVgWta7Zx2go+8xJ0UiCb8LHHdftWyLJE0QIAIsI+UbXu67dZMjmgDGCGl1H+vpF4NSDckSIkk7Vd+sxEhBQMRU8j/12UIRhzSaUdQ+rQU5kGeFxm+hb1oh6pWWmv3uvmReDl0UnvtapVaIzo1jZbf/pD6ElLqSX+rUmOQNpJFa/r+sa4e/pBlAABoAAAAA3CUgShLdGIxsY7AUABPRrgCABdDuQ5GC7DqPQCgbbJUAoRSUj+NIEig0YfyWUho1VBBBA//uQZB4ABZx5zfMakeAAAAmwAAAAF5F3P0w9GtAAACfAAAAAwLhMDmAYWMgVEG1U0FIGCBgXBXAtfMH10000EEEEEECUBYln03TTTdNBDZopopYvrTTdNa325mImNg3TTPV9q3pmY0xoO6bv3r00y+IDGid/9aaaZTGMuj9mpu9Mpio1dXrr5HERTZSmqU36A3CumzN/9Robv/Xx4v9ijkSRSNLQhAWumap82WRSBUqXStV/YcS+XVLnSS+WLDroqArFkMEsAS+eWmrUzrO0oEmE40RlMZ5+ODIkAyKAGUwZ3mVKmcamcJnMW26MRPgUw6j+LkhyHGVGYjSUUKNpuJUQoOIAyDvEyG8S5yfK6dhZc0Tx1KI/gviKL6qvvFs1+bWtaz58uUNnryq6kt5RzOCkPWlVqVX2a/EEBUdU1KrXLf40GoiiFXK///qpoiDXrOgqDR38JB0bw7SoL+ZB9o1RCkQjQ2CBYZKd/+VJxZRRZlqSkKiws0WFxUyCwsKiMy7hUVFhIaCrNQsKkTIsLivwKKigsj8XYlwt/WKi2N4d//uQRCSAAjURNIHpMZBGYiaQPSYyAAABLAAAAAAAACWAAAAApUF/Mg+0aohSIRobBAsMlO//Kk4soosy1JSFRYWaLC4qZBYWFRGZdwqKiwkNBVmoWFSJkWFxX4FFRQWR+LsS4W/rFRb/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////VEFHAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAU291bmRib3kuZGUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMjAwNGh0dHA6Ly93d3cuc291bmRib3kuZGUAAAAAAAAAACU=");
                snd.play();
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
                    this.timer.value = 30;
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
                this.$http.post( cntlr + "/used", { question_id: this.question.question_id } );
                this.question.used++;

                var as     = this.question.as;
                var number = this.question.number;

                this.move_question(1);

                if ( result == "correct" ) {
                    this.question.as     = "Standard";
                    this.question.number = parseInt(number) + 1;
                }
                else if ( result == "error" ) {
                    if ( as == "Standard" ) {
                        this.question.as = "Toss-Up";
                    }
                    else if ( as == "Toss-Up" ) {
                        this.question.as = "Bonus";
                    }
                    else if ( as == "Bonus" ) {
                        this.question.as = "Standard";
                    }

                    if ( parseInt(number) < 16 ) {
                        this.question.number = parseInt(number) + 1;
                    }
                    else if ( number == parseInt(number) ) {
                        this.question.number = parseInt(number) + 'A';
                    }
                    else if ( number == parseInt(number) + 'A' ) {
                        this.question.number = parseInt(number) + 'B';
                    }
                    else if ( number == parseInt(number) + 'B' ) {
                        this.question.number = parseInt(number) + 1;
                    }
                }
                else if ( result == "no_jump" ) {
                    this.question.as     = "Standard";
                    this.question.number = parseInt(number) + 1;
                }
            },
            replace: function (type) {
                this.$http.post(
                    cntlr + "/replace",
                    {
                        type: type,
                        questions: this.questions
                    }
                ).then( function (response) {
                    if ( response.body.error ) {
                        alert('Unable to replace with that type. Try another.');
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
        }
    });
});
