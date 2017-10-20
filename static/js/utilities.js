function set_cookie( name, value, days ) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime( date.getTime() + ( days * 24 * 60 * 60 * 1000 ) );
        expires = "; expires=" + date.toGMTString();
    }
    document.cookie = name + "=" + value + expires + "; path=/";
    return value;
}

function get_cookie(name) {
    var name_eq = name + "=";
    var cookies = document.cookie.split(';');
    for ( var i = 0; i < cookies.length; i++ ) {
        var cookie = cookies[i];
        while ( cookie.charAt(0) == ' ' ) cookie = cookie.substring( 1, cookie.length );
        if ( cookie.indexOf(name_eq) == 0 ) return cookie.substring( name_eq.length, cookie.length );
    }
    return null;
}

function erase_cookie(name) {
    return set_cookie( name, "", -1 );
}

function set_json_cookie( name, value, days ) {
    return set_cookie( name, btoa( JSON.stringify(value) ), days );
}

function get_json_cookie(name) {
    return JSON.parse( atoa( get_cookie(name) ) );
}

// -----------------------------------------------------------------------------

function push_onload(function_reference) {
    if ( window.attachEvent ) {
        window.attachEvent( 'onload', function_reference );
    }
    else {
        if ( window.onload ) {
            var current_onload = window.onload;
            var new_onload = function(event) {
                current_onload(event);
                function_reference(event);
            };
            window.onload = new_onload;
        } else {
            window.onload = function_reference;
        }
    }
}
