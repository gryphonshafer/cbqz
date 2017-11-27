Vue.http.get( cntlr + "/data" ).then( function (response) {
    var data = response.body;
    data.lookup = {
        book    : null,
        chapter : null,
        verse   : null
    };

    var vue_app = new Vue({
        el: "#editor",
        data: data,
        methods: {
            copy_verse: function () {
                if (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) {
                    this.questions.question_id = null;

                    var verse = this.material
                        [ this.question.book ][ this.question.chapter ][ this.question.verse ];

                    this.question.question = "";
                    this.question.answer   = "";

                    this.$nextTick( function () {
                        this.question.question = verse.text;
                        this.question.answer   = verse.text;
                    } );

                    this.question.question_id = null;
                    this.question.used        = null;
                    this.question.marked      = null;
                }
                else {
                    alert("Incomplete reference; copy verse not possible.");
                }
            },

            lookup_reference: function () {
                if (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) {
                    this.lookup.book = this.question.book;
                    this.lookup.chapter = this.question.chapter;
                    this.lookup.verse = this.question.verse;
                }
                else {
                    alert("Incomplete reference; lookup not possible.");
                }
            },

            format: function (className) {
                var selection = document.getSelection();
                if ( selection.rangeCount > 0 && selection.isCollapsed == 0 ) {
                    for ( var i = 0; i < selection.rangeCount; i++ ) {
                        var range       = selection.getRangeAt(i);
                        var replacement = document.createTextNode( range.toString() );

                        if (className) {
                            var span = document.createElement("span");
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
                else {
                    alert("No text selected to format.");
                }
            },

            save_new: function () {
                if (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0 &&
                    !! this.question.type
                ) {
                    this.question.question = this.$refs.question.innerHTML;
                    this.question.answer   = this.$refs.answer.innerHTML;
                    this.question.marked   = null;

                    this.question.question_id = null;

                    this.$http.post( cntlr + "/save", this.question ).then( function (response) {
                        var question = response.body.question;

                        if ( ! this.questions.data[ question.book ] )
                            this.questions.data[ question.book ] = {};
                        if ( ! this.questions.data[ question.book ][ question.chapter ] )
                            this.questions.data[ question.book ][ question.chapter ] = {};

                        this.questions.data
                            [ question.book ][ question.chapter ][ question.question_id ] = question;

                        this.questions.books = Object.keys( this.questions.data ).sort();
                        this.questions.book = null;

                        this.$nextTick( function () {
                            this.questions.book = question.book;

                            this.$nextTick( function () {
                                this.questions.chapter = question.chapter;
                                this.questions.marked_questions = this.grep_marked_questions();
                            } );
                        } );

                        this.clear_form();

                        this.$nextTick( function () {
                            this.question.book    = question.book;
                            this.question.chapter = question.chapter;
                            this.question.verse   = question.verse;

                            document.getElementById("verse").focus();
                            this.$nextTick( function () {
                                document.getElementById("verse").select();
                            } );
                        } );
                    } );
                }
                else {
                    alert("Not all required fields have data.");
                }
            },

            save_changes: function () {
                if ( !! this.questions.question_id ) {
                    this.question.question = this.$refs.question.innerHTML;
                    this.question.answer   = this.$refs.answer.innerHTML;
                    this.question.marked   = null;

                    this.$http.post( cntlr + "/save", this.question ).then( function (response) {
                        var question = response.body.question;

                        // delete question
                        // (code copied/duplicated for now for expediency; will refactor later)

                        delete this.questions.data
                            [ this.questions.book ][ this.questions.chapter ][ this.questions.question_id ];

                        if ( ! Object.keys(
                            this.questions.data[ this.questions.book ][ this.questions.chapter ]
                        ).length )
                            delete this.questions.data[ this.questions.book ][ this.questions.chapter ];

                        if ( ! Object.keys(
                            this.questions.data[ this.questions.book ]
                        ).length )
                            delete this.questions.data[ this.questions.book ];

                        if ( ! this.questions.data[ this.questions.book ] ) {
                            this.questions.books = Object.keys( this.questions.data ).sort();
                            if ( this.questions.books[0] ) {
                                this.questions.book = this.questions.books[0];
                            }
                            else {
                                this.questions.chapters = null;
                                this.questions.questions = null;
                            }
                        }
                        else if ( ! this.questions.data[ this.questions.book ][ this.questions.chapter ] ) {
                            this.questions.chapters = Object.keys( this.questions.data[ this.questions.book ] ).sort(
                                function ( a, b ) {
                                    return a - b;
                                }
                            );
                            this.questions.chapter = this.questions.chapters[0];
                        }
                        else {
                            var questions_hash = this.questions.data[ this.questions.book ][ this.questions.chapter ];
                            var keys = Object.keys(questions_hash);

                            var questions_array = new Array();
                            for ( var i = 0; i < keys.length; i++ ) {
                                questions_array.push( questions_hash[ keys[i] ] );
                            }

                            this.questions.questions = questions_array.sort( function ( a, b ) {
                                if ( a.verse < b.verse ) return -1;
                                if ( a.verse > b.verse ) return 1;
                                if ( a.type < b.type ) return -1;
                                if ( a.type > b.type ) return 1;
                                if ( a.used > b.used ) return -1;
                                if ( a.used < b.used ) return 1;
                                return 0;
                            } );
                        }

                        // create question
                        // (code copied/duplicated for now for expediency; will refactor later)

                        this.$nextTick( function () {
                            if ( ! this.questions.data[ question.book ] )
                                this.questions.data[ question.book ] = {};
                            if ( ! this.questions.data[ question.book ][ question.chapter ] )
                                this.questions.data[ question.book ][ question.chapter ] = {};

                            this.questions.data
                                [ question.book ][ question.chapter ][ question.question_id ] = question;

                            this.questions.books = Object.keys( this.questions.data ).sort();
                            this.questions.book = null;

                            this.$nextTick( function () {
                                this.questions.book = question.book;

                                this.$nextTick( function () {
                                    this.questions.chapter = question.chapter;
                                    this.questions.marked_questions = this.grep_marked_questions();
                                } );
                            } );

                            // this.clear_form();
                            // (don't clear form when saving a question)

                            this.$nextTick( function () {
                                this.question.book    = question.book;
                                this.question.chapter = question.chapter;
                                this.question.verse   = question.verse;

                                document.getElementById("verse").focus();
                                this.$nextTick( function () {
                                    document.getElementById("verse").select();
                                } );
                            } );
                        } );
                    } );
                }
                else {
                    alert("No previously saved question selected.");
                }
            },

            delete_question: function () {
                if ( !! this.questions.question_id ) {
                    this.$http.post(
                        cntlr + "/delete",
                        { question_id: this.questions.question_id }
                    ).then( function (response) {
                        if ( response.body.success ) {
                            delete this.questions.data
                                [ this.questions.book ][ this.questions.chapter ][ this.questions.question_id ];

                            if ( ! Object.keys(
                                this.questions.data[ this.questions.book ][ this.questions.chapter ]
                            ).length )
                                delete this.questions.data[ this.questions.book ][ this.questions.chapter ];

                            if ( ! Object.keys(
                                this.questions.data[ this.questions.book ]
                            ).length )
                                delete this.questions.data[ this.questions.book ];

                            if ( ! this.questions.data[ this.questions.book ] ) {
                                this.questions.books = Object.keys( this.questions.data ).sort();
                                if ( this.questions.books[0] ) {
                                    this.questions.book = this.questions.books[0];
                                }
                                else {
                                    this.questions.chapters = null;
                                    this.questions.questions = null;
                                }
                            }
                            else if ( ! this.questions.data[ this.questions.book ][ this.questions.chapter ] ) {
                                this.questions.chapters = Object.keys(
                                    this.questions.data[ this.questions.book ]
                                ).sort(
                                    function ( a, b ) {
                                        return a - b;
                                    }
                                );
                                this.questions.chapter = this.questions.chapters[0];
                            }
                            else {
                                var questions_hash = this.questions.data[ this.questions.book ][ this.questions.chapter ];
                                var keys = Object.keys(questions_hash);

                                var questions_array = new Array();
                                for ( var i = 0; i < keys.length; i++ ) {
                                    questions_array.push( questions_hash[ keys[i] ] );
                                }

                                this.questions.questions = questions_array.sort( function ( a, b ) {
                                    if ( a.verse < b.verse ) return -1;
                                    if ( a.verse > b.verse ) return 1;
                                    if ( a.type < b.type ) return -1;
                                    if ( a.type > b.type ) return 1;
                                    if ( a.used > b.used ) return -1;
                                    if ( a.used < b.used ) return 1;
                                    return 0;
                                } );
                            }

                            this.questions.marked_questions = this.grep_marked_questions();
                        }
                        else {
                            alert("There was an error deleting the question.");
                        }
                    } );
                }
                else {
                    alert("No question selected to delete.");
                }
            },

            clear_form: function () {
                this.questions.question_id = null;

                this.question.question_id = null;
                this.question.used        = null;
                this.question.book        = null;
                this.question.chapter     = null;
                this.question.verse       = null;
                this.question.question    = null;
                this.question.answer      = null;
                this.question.type        = null;
                this.question.marked      = null;

                this.$refs.question.innerHTML = '';
                this.$refs.answer.innerHTML   = '';

                document.getElementById("book").focus();
            },

            grep_marked_questions: function () {
                var marked_questions = [];

                for ( var book in this.questions.data ) {
                    for ( var chapter in this.questions.data[book] ) {
                        for ( var id in this.questions.data[book][chapter] ) {
                            if ( this.questions.data[book][chapter][id].marked ) {
                                marked_questions.push( this.questions.data[book][chapter][id] );
                            }
                        }
                    }
                }

                return marked_questions;
            },

            lookup_reference_change: function ( book, chapter, verse ) {
                this.lookup.book    = book;
                this.lookup.chapter = chapter;
                this.lookup.verse   = verse;
            },

            lookup_reference_click: function (verse) {
                this.questions.question_id = null;

                this.question.book     = verse.book;
                this.question.chapter  = verse.chapter;
                this.question.verse    = verse.verse;
                this.question.question = verse.text;
                this.question.answer   = verse.text;

                this.question.question_id = null;
                this.question.used        = null;
                this.question.type        = null;
                this.question.marked      = null;
            },

            search_reference_click: function (verse) {
                this.lookup.book    = verse.book;
                this.lookup.chapter = verse.chapter;
                this.lookup.verse   = verse.verse;
            }
        },

        computed: {
            verse_incomplete: function () {
                return (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0
                ) ? false : true;
            },

            no_saved_question: function () {
                return ! this.questions.question_id;
            },

            new_question_incomplete: function () {
                return (
                    !! this.question.book &&
                    parseInt( this.question.chapter ) > 0 &&
                    parseInt( this.question.verse ) > 0 &&
                    !! this.question.type
                ) ? false : true;
            },
        },

        watch: {
            "questions.book": function () {
                if ( !! this.questions.book ) {
                    var sort_by = this.questions.sort_by;
                    this.questions.chapters = Object.keys( this.questions.data[ this.questions.book ] ).sort(
                        function ( a, b ) {
                            return ( sort_by == "desc_ref" ) ? b - a : a - b;
                        }
                    );

                    this.questions.chapter = null;
                    this.$nextTick( function () {
                        this.questions.chapter = this.questions.chapters[0];
                    } );
                }
            },

            "questions.chapter": function () {
                if ( !! this.questions.chapter ) {
                    var questions_hash = this.questions.data[ this.questions.book ][ this.questions.chapter ];
                    var keys = Object.keys(questions_hash);

                    var questions_array = new Array();
                    for ( var i = 0; i < keys.length; i++ ) {
                        questions_array.push( questions_hash[ keys[i] ] );
                    }

                    var sort_by = this.questions.sort_by;
                    this.questions.questions = questions_array.sort( function ( a, b ) {
                        if ( sort_by == "desc_ref" ) {
                            if ( a.verse > b.verse ) return -1;
                            if ( a.verse < b.verse ) return 1;
                            if ( a.type < b.type ) return -1;
                            if ( a.type > b.type ) return 1;
                            if ( a.used > b.used ) return -1;
                            if ( a.used < b.used ) return 1;
                        }
                        else if ( sort_by == "ref" ) {
                            if ( a.verse < b.verse ) return -1;
                            if ( a.verse > b.verse ) return 1;
                            if ( a.type < b.type ) return -1;
                            if ( a.type > b.type ) return 1;
                            if ( a.used > b.used ) return -1;
                            if ( a.used < b.used ) return 1;
                        }
                        else if ( sort_by == "type" ) {
                            if ( a.type < b.type ) return -1;
                            if ( a.type > b.type ) return 1;
                            if ( a.verse < b.verse ) return -1;
                            if ( a.verse > b.verse ) return 1;
                            if ( a.used > b.used ) return -1;
                            if ( a.used < b.used ) return 1;
                        }
                        else if ( sort_by == "used" ) {
                            if ( a.used > b.used ) return -1;
                            if ( a.used < b.used ) return 1;
                            if ( a.type < b.type ) return -1;
                            if ( a.type > b.type ) return 1;
                            if ( a.verse < b.verse ) return -1;
                            if ( a.verse > b.verse ) return 1;
                        }

                        return 0;
                    } );
                }
            },

            "questions.question_id": function () {
                if ( !! this.questions.question_id ) {
                    var question = this.questions.data
                        [ this.questions.book ][ this.questions.chapter ][ this.questions.question_id ];

                    for ( var key in question ) {
                        this.question[key] = question[key];
                    }

                    var question_id = this.questions.question_id;
                    if (
                        this.questions.marked_questions.filter( function (question) {
                            return question.question_id == question_id;
                        } ).length > 0
                    ) {
                        this.questions.marked_question_id = this.questions.question_id;
                    }
                    else {
                        this.questions.marked_question_id = null;
                    }
                }
            },

            "questions.marked_question_id": function () {
                if (
                    !! this.questions.marked_question_id &&
                    (
                        ! this.questions.question_id ||
                        this.questions.marked_question_id != this.questions.question_id
                    )
                ) {
                    var questions = this.questions;
                    var marked_question = this.questions.marked_questions.filter( function (question) {
                        return question.question_id == questions.marked_question_id;
                    } ).shift();

                    this.questions.book = marked_question.book;
                    this.$nextTick( function () {
                        this.questions.chapter = marked_question.chapter;

                        this.$nextTick( function () {
                            this.questions.question_id = this.questions.marked_question_id;
                        } );
                    } );
                }
            },

            "questions.sort_by": function () {
                this.questions.book = null;
                this.$nextTick( function () {
                    this.questions.books = Object.keys( this.questions.data ).sort();
                    if ( this.questions.books[0] ) this.questions.book = this.questions.books[0];
                } );
            }
        },

        mounted: function () {
            this.questions.books = Object.keys( this.questions.data ).sort();
            if ( this.questions.books[0] ) this.questions.book = this.questions.books[0];

            this.questions.marked_questions = this.grep_marked_questions();
        }
    });

    document.addEventListener( "keyup", function(event) {
        event.preventDefault();

        // for Alt+V: Copy Verse
        if ( event.altKey && event.keyCode == 86 ) document.getElementById("copy_verse").click();

        // for Alt+G, F2: Lookup Verse
        if ( ( event.altKey && event.keyCode == 71 ) || event.keyCode == 113 )
            document.getElementById("lookup").click();

        // for Alt+Q: Reset Formatting
        if ( event.altKey && event.keyCode == 81 ) document.getElementById("format_reset").click();

        // for Alt+W, Ctrl+B: Global Unique
        if ( ( event.altKey && event.keyCode == 87 ) || ( event.ctrlKey && event.keyCode == 66 ) )
            document.getElementById("format_unique_word").click();

        // for Alt+E, Ctrl+I: Chapter Unique
        if ( ( event.altKey && event.keyCode == 69 ) || ( event.ctrlKey && event.keyCode == 73 ) )
            document.getElementById("format_unique_chapter").click();

        // for Alt+R, Ctrl+U: Unique Phrase
        if ( ( event.altKey && event.keyCode == 82 ) || ( event.ctrlKey && event.keyCode == 85 ) )
            document.getElementById("format_unique_phrase").click();

        // for Alt+A, F8: Save As New
        if ( ( event.altKey && event.keyCode == 65 ) || event.keyCode == 119 )
            document.getElementById("save_new").click();

        // for Alt+S, F9: Save Changes
        if ( ( event.altKey && event.keyCode == 83 ) || event.keyCode == 120 )
            document.getElementById("save_changes").click();

        // for Alt+X: Delete
        if ( event.altKey && event.keyCode == 88 ) document.getElementById("delete_question").click();

        // for Alt+C: Clear
        if ( event.altKey && event.keyCode == 67 ) document.getElementById("clear_form").click();

        // for Alt+T: Prompt for Reference
        if ( event.altKey && event.keyCode == 84 )
            vue_app.$refs.material_lookup.enter_reference();

        // for Alt+F, F4: Find Text
        if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
            vue_app.$refs.material_search.find();
    } );
} );
