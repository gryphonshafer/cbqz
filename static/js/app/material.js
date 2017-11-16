Vue.http.get( cntlr + "/material_data" ).then( function (response) {
    var vue_app = new Vue({
        el: '#material',
        data: {
            lookup: {
                book    : null,
                chapter : null,
                verse   : null
            },
            material: response.body.material
        },
        methods: {
            lookup_reference_change: function ( book, chapter, verse ) {
                this.lookup.book    = book;
                this.lookup.chapter = chapter;
                this.lookup.verse   = verse;
            },
            search_reference_click: function (verse) {
                this.lookup.book    = verse.book;
                this.lookup.chapter = verse.chapter;
                this.lookup.verse   = verse.verse;
            }
        }
    });

    document.addEventListener( "keyup", function(event) {
        event.preventDefault();

        // for Alt+F, F4: Find Text
        if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
            vue_app.$refs.material_search.find();

        // for Alt+R: Prompt for Reference
        if ( event.altKey && event.keyCode == 82 )
            vue_app.$refs.material_lookup.enter_reference();
    } );
});
