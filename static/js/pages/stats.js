push_onload( function () {
    var quiz_table_rows = document.getElementsByClassName("quiz_table_row");
    var selected_count  = 0;
    var delete_button   = document.getElementById("delete_button");

    for ( var i = 0; i < quiz_table_rows.length; i++ ) {
        if ( quiz_table_rows.item(i).children.item(0).children.length ) {
            if ( quiz_table_rows.item(i).children.item(0).children.item(0).checked ) {
                quiz_table_rows.item(i).classList.add("selected");
                selected_count++;
                delete_button.disabled = false;
            }

            quiz_table_rows.item(i).children.item(0).children.item(0).onchange = function () {
                if ( this.checked ) {
                    this.parentNode.parentNode.classList.add("selected");
                    selected_count++;
                    delete_button.disabled = false;
                }
                else {
                    this.parentNode.parentNode.classList.remove("selected");
                    selected_count--;
                    if ( ! selected_count ) delete_button.disabled = true;
                }

                return true;
            };
        }
    }

    var sort_control = document.getElementsByClassName("sort_control");
    for ( var i = 0; i < sort_control.length; i++ ) {
        sort_control[i].onchange = function () {
            var url = document.createElement("a");
            url.href = document.location.href;
            url.search =
                "?sort_by=" + document.getElementById("sort_by").value +
                "&sort_order=" + document.getElementById("sort_order").value;

            var page = document.getElementById("page");
            if (page) url.search = url.search + "&page=" + page.value;

            document.location.href = url.href;
        }
    }
} );
