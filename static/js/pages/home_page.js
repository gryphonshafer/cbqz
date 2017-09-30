function enable_submit() {
    document.getElementById("create_form_submit").disabled = false;
}

push_onload( function () {
    var create_form_submit = document.getElementById("create_form_submit");
    if (create_form_submit) {
        create_form_submit.onclick = function () {
            if (
                create_form_submit.form.name.value.length == 0 ||
                create_form_submit.form.passwd.value.length == 0 ||
                create_form_submit.form.email.value.length == 0
            ) {
                alert("Please fill out the form completely.");
                return false;
            }
        };
    }

    var select_sets = document.getElementById("select_sets");
    if (select_sets) {
        var inputs = select_sets.getElementsByTagName("input");
        for ( var i = 0; i < inputs.length; i++ ) {
            if ( inputs[i].type != "radio" ) next;

            var set_value = get_cookie( 'cbqz_sets_' + inputs[i].name );
            if ( ! set_value ) {
                set_cookie( 'cbqz_sets_' + inputs[i].name, inputs[i].value );
                set_value = inputs[i].value;
            }
            if ( set_value == inputs[i].value ) inputs[i].checked = true;

            inputs[i].onchange = function () {
                set_cookie( 'cbqz_sets_' + this.name, this.value );
            }
        }
    }
} );
