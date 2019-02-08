function question_set_create () {
    var name = prompt("Please enter a question set name:");
    if ( !! name ) document.location.href = cntlr + "/question_set_create" + "?name=" + encodeURI(name);
}

var checked_sets = new Array();

function checkbox_check_count_implications () {
    var checkboxes = document.getElementsByClassName("question_set_checkbox");

    checked_sets = new Array();
    for ( var i = 0; i < checkboxes.length; i++ ) {
        if ( checkboxes[i].checked ) checked_sets.push(
            {
                id   : checkboxes[i].value,
                name : checkboxes[i].parentNode.parentNode.children[1].textContent,
            }
        );
    }

    if ( checked_sets.length == 0 ) {
        document.getElementById("reset").disabled       = true;
        document.getElementById("rename").disabled      = true;
        document.getElementById("clone").disabled       = true;
        document.getElementById("publish").disabled     = true;
        document.getElementById("share").disabled       = true;
        document.getElementById("delete").disabled      = true;
        document.getElementById("export").disabled      = true;
        document.getElementById("export_intl").disabled = true;
        document.getElementById("merge").disabled       = true;
        document.getElementById("auto-kvl").disabled    = true;
    }
    else if ( checked_sets.length == 1 ) {
        document.getElementById("reset").disabled       = false;
        document.getElementById("rename").disabled      = false;
        document.getElementById("clone").disabled       = false;
        document.getElementById("publish").disabled     = false;
        document.getElementById("share").disabled       = false;
        document.getElementById("delete").disabled      = false;
        document.getElementById("export").disabled      = false;
        document.getElementById("export_intl").disabled = false;
        document.getElementById("merge").disabled       = true;
        document.getElementById("auto-kvl").disabled    = false;
    }
    else if ( checked_sets.length > 1 ) {
        document.getElementById("reset").disabled       = false;
        document.getElementById("rename").disabled      = true;
        document.getElementById("clone").disabled       = true;
        document.getElementById("publish").disabled     = true;
        document.getElementById("share").disabled       = true;
        document.getElementById("delete").disabled      = false;
        document.getElementById("export").disabled      = true;
        document.getElementById("export_intl").disabled = true;
        document.getElementById("merge").disabled       = false;
        document.getElementById("auto-kvl").disabled    = false;
    }
}

function publish_share_set ( question_set_id, type ) {
    document.location.href = cntlr + "/set_select_users" +
        "?question_set_id=" + question_set_id + "&type=" + type;
}

function clone_question_set ( question_set_id, original_name ) {
    var new_set_name;
    if (
        new_set_name = prompt(
            "This will clone (or copy) the selected question set. This can\n" +
            "take a very long time (>20 seconds) for full question sets.\n" +
            "Enter the name you would like for the clone of this question set:",
            original_name
        )
    ) {
        document.location.href = cntlr + "/clone_question_set" +
            "?question_set_id=" + question_set_id + "&new_set_name=" + encodeURI(new_set_name);
    }
}

push_onload( function () {
    var checkboxes = document.getElementsByClassName("question_set_checkbox");

    for ( var i = 0; i < checkboxes.length; i++ ) {
        if ( checkboxes[i].checked ) checkboxes[i].parentNode.parentNode.classList.add("selected");

        checkboxes[i].onchange = function () {
            if ( this.checked ) {
                this.parentNode.parentNode.classList.add("selected");
            }
            else {
                this.parentNode.parentNode.classList.remove("selected");
            }

            checkbox_check_count_implications();
        };
    }

    document.getElementById("reset").onclick = function () {
        if ( confirm(
            "Are you sure you want to reset the selected question set(s)?\n" +
            "This will set all questions to having been asked 0 times.\n" +
            "There's no undo."
        ) ) {
            document.location.href = cntlr + "/question_sets_reset?set_data=" +
                encodeURI( JSON.stringify(checked_sets) );
        }
    };

    document.getElementById("rename").onclick = function () {
        var name = prompt("Please enter a question set name:");
        if ( !! name ) document.location.href = cntlr + "/question_set_rename" +
            "?question_set_id=" + checked_sets[0].id + "&name=" + encodeURI(name);
    };

    document.getElementById("clone").onclick = function () {
        clone_question_set( checked_sets[0].id, checked_sets[0].name );
    };

    document.getElementById("publish").onclick = function () {
        publish_share_set( checked_sets[0].id, "publish" );
    };

    document.getElementById("share").onclick = function () {
        publish_share_set( checked_sets[0].id, "share" );
    };

    document.getElementById("delete").onclick = function () {
        if ( confirm("Are you sure you want to delete the selected question set(s)?") ) {
            if ( confirm("STOP! Are you really, really sure? (There's no undo.)") ) {
                document.location.href = cntlr + "/question_set_delete" +
                    "?set_data=" + encodeURI( JSON.stringify(checked_sets) );
            }
        }
    };

    document.getElementById("export").onclick = function () {
        document.location.href = cntlr + "/export_question_set?question_set_id=" + checked_sets[0].id;
    };
    document.getElementById("export_intl").onclick = function () {
        document.location.href = cntlr + "/export_question_set?question_set_id=" + checked_sets[0].id + "&style=intl";
    };

    document.getElementById("merge").onclick = function () {
        document.location.href = cntlr + "/merge_question_sets?set_data=" +
            encodeURI( JSON.stringify(checked_sets) );
    };

    document.getElementById("auto-kvl").onclick = function () {
        if ( confirm(
            "Are you sure you want to automatically replace all key-verse list type questions\n" +
            "with auto-written key-verse list type questions into the selected question set(s)?"
        ) ) {
            document.location.href = cntlr + "/auto_kvl?set_data=" +
                encodeURI( JSON.stringify(checked_sets) );
        }
    };

    checkbox_check_count_implications();
} );
