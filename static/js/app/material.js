Vue.http.get( cntlr + "/material_data" ).then( function (response) {
    var vue_app = new Vue({
        el: '#material',
        data: {
            material: response.body.material
        },
        methods: {
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
            }
        }
    });

    document.addEventListener( "keyup", function(event) {
        event.preventDefault();

        // for Alt+F, F4: Find Text
        if ( ( event.altKey && event.keyCode == 70 ) || event.keyCode == 115 )
            vue_app.$refs.material_search.find(true);

        // for Alt+T: Prompt for Reference
        if ( event.altKey && event.keyCode == 84 )
            vue_app.$refs.material_lookup.enter_reference();
    } );
});
