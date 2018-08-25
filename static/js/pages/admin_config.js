push_onload( function () {
    var reset_config_to_defaults = document.getElementById("reset_config_to_defaults");
    var admin_config = document.getElementById("admin_config");

    if ( reset_config_to_defaults && admin_config ) {
        reset_config_to_defaults.onclick = function () {
            if ( confirm(
                "Are you sure you want to reset the form data?\n" +
                "(No changes will be saved until you click the save button.)"
            ) ) {
                Object.keys(defaults).forEach( function (key) {
                    admin_config[key].value = defaults[key];
                } );
            }
        };
    }
} );
