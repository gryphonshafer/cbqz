push_onload( function () {
    var login_form_submit = document.getElementById("login_form_submit");
    if (login_form_submit) {
        login_form_submit.onclick = function () {
            if (
                login_form_submit.form.username.value.length == 0 ||
                login_form_submit.form.passwd.value.length == 0
            ) {
                alert("Please fill out the login form completely.");
                return false;
            }
        };
    }
} );
