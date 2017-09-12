document.addEventListener( "keyup", function(event) {
    event.preventDefault();

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

    // for Alt+G, F2: Lookup Verse
    if ( ( event.altKey && event.keyCode == 71 ) || event.keyCode == 113 )
        document.getElementById("lookup").click();

    // for Alt+F, F8: Find Text
    if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 119 )
        document.getElementById("find").click();

    // for Alt+V: Copy Verse
    if ( event.altKey && event.keyCode == 86 ) document.getElementById("copy_verse").click();
} );

/*
    a: 65,   // for Alt+A:  Save As New
    s: 83,   // for Alt+S:  Save Changes
    f9: 120, // for F9:     Save Changes
    x: 88,   // for Alt+X:  Delete
    c: 67,   // for Alt+C:  Clear
*/

Vue.http.get( cntlr + '/data' ).then( function (response) {
    new Vue({
        el: "#editor",
        data: response.body,
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
                this.$http.post( cntlr + '/save', this.question ).then( function (response) {
                    this.question = response.body.question;
                } );
            },
            lookup: function () {
                if (
                    this.question.book.length > 0 &&
                    this.question.chapter.length > 0 &&
                    this.question.verse.length > 0
                ) {
                    this.material.book = this.question.book;
                    this.$nextTick( function () {
                        this.material.chapter = this.question.chapter;
                        this.$nextTick( function () {
                            this.material.verse = this.question.verse;
                        } );
                    } );
                }
            },
            find: function () {
                var selection = document.getSelection();
                if ( selection.rangeCount > 0 && selection.isCollapsed == 0 ) {
                    var search_text = '';
                    for ( var i = 0; i < selection.rangeCount; i++ ) {
                        search_text = search_text + selection.getRangeAt(i).toString();
                    }

                    this.material.search = search_text;
                }
            },
            copy_verse: function () {
                if (
                    this.question.book.length > 0 &&
                    this.question.chapter.length > 0 &&
                    this.question.verse.length > 0
                ) {
                    var verse = this.material.data[ this.question.book ][ this.question.chapter ][ this.question.verse ];
                    this.question.question = verse.text;
                    this.question.answer   = verse.text;
                }
            },
            copy_verse_from_lookup: function (verse) {
                this.question.book     = verse.book;
                this.question.chapter  = verse.chapter;
                this.question.verse    = verse.verse;
                this.question.question = verse.text;
                this.question.answer   = verse.text;
            },
            lookup_from_search: function (verse) {
                this.material.book = verse.book;
                this.$nextTick( function () {
                    this.material.chapter = verse.chapter;
                    this.$nextTick( function () {
                        this.material.verse = verse.verse;
                    } );
                } );
            }
        },
        watch: {
            'material.book': function () {
                this.material.chapters = Object.keys( this.material.data[ this.material.book ] ).sort(
                    function ( a, b ) {
                        return a - b;
                    }
                );
                this.material.chapter  = this.material.chapters[0];
            },
            'material.chapter': function () {
                this.material.verses = this.material.data[ this.material.book ][ this.material.chapter ];
                this.material.verse  = this.material.verses[0].verse;
            },
            'material.verse': function () {
                this.$nextTick( function () {
                    window.location.href = '#material_lookup_display_' + this.material.verse;
                } );
            },
            'material.search': function () {
                this.material.matched_verses = [];

                if ( this.material.search.length > 2 ) {
                    var search_term = this.material.search.toLowerCase().replace( /\W+/g, '' );

                    var books = Object.keys( this.material.data ).sort();
                    for ( var i = 0; i < books.length; i++ ) {
                        var chapters = Object.keys( this.material.data[ books[i] ] ).sort(
                            function ( a, b ) {
                                return a - b;
                            }
                        );

                        for ( var j = 0; j < chapters.length; j++ ) {
                            var verses = this.material.data[ books[i] ][ chapters[j] ];

                            for ( var k = 0; k < verses.length; k++ ) {
                                if ( verses[k].search.indexOf( search_term ) != -1 ) {
                                    this.material.matched_verses.push( verses[k] );
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
        }
    });
} );
