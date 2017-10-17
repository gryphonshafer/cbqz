Vue.http.get( cntlr + "/data" ).then( function (response) {
    new Vue({
        el: "#main",
        data: response.body,
        watch: {
            question_set_id: function () {
                var question_set_id = this.question_set_id;

                var question_set = this.question_sets.find( function(set) {
                    return question_set_id == set.question_set_id;
                } );

                this.question_set = question_set;
            }
        }
    });
});
