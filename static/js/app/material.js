Vue.http.get( cntlr + "/material_data" ).then( function (response) {
    new Vue({
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
            reference_change: function ( book, chapter, verse ) {
                this.lookup.book    = book;
                this.lookup.chapter = chapter;
                this.lookup.verse   = verse;
            },
            reference_click: function (verse) {
                console.log(verse);
            }
        }
    });
});
