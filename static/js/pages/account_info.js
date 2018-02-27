function account_info( type, label, old_value ) {
    account_edit_clear();

    document.getElementById("edit_user_type").value = type;

    if ( type != "password" ) {
        document.getElementById("edit_user_value").value = old_value;
        document.getElementById("edit_user_legend").innerHTML = "Edit Account " + label;
    }

    document.getElementById(
        ( type == "password" ) ? "edit_user_password" : "edit_user_general"
    ).style.display = "initial";
    document.getElementById("edit_user").style.display = "block";

    document.getElementById(
        ( type == "password" ) ? "edit_user_password_old" : "edit_user_value"
    ).focus();
}

function account_edit_clear() {
    document.getElementById("edit_user").style.display = "none";
    document.getElementById("edit_user_general").style.display = "none";
    document.getElementById("edit_user_password").style.display = "none";
}
