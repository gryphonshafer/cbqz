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
} );
