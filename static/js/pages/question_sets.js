function question_set_reset (question_set_id) {
    if ( confirm(
        "Are you sure you want to reset this question set?\n" +
        "This will set all questions to having been asked 0 times.\n" +
        "There's no undo."
    ) ) {
        document.location.href = cntlr + "/question_set_reset?question_set_id=" + question_set_id;
    }
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

function publish_share_set ( question_set_id, type ) {
    document.location.href = cntlr + "/set_select_users" +
        "?question_set_id=" + question_set_id + "&type=" + type;
}

function question_set_create () {
    var name = prompt("Please enter a question set name:");
    if ( !! name ) document.location.href = cntlr + "/question_set_create" + "?name=" + encodeURI(name);
}

function question_set_rename (question_set_id) {
    var name = prompt("Please enter a question set name:");
    if ( !! name ) document.location.href = cntlr + "/question_set_rename" +
        "?question_set_id=" + question_set_id + "&name=" + encodeURI(name);
}

function question_set_delete (question_set_id) {
    if ( confirm("Are you sure you want to delete the question set?") ) {
        if ( confirm("STOP! Are you really, really sure? (There's no undo.)") ) {
            document.location.href = cntlr + "/question_set_delete" + "?question_set_id=" + question_set_id;
        }
    }
}

function export_set (set_id) {
    document.location.href = "export_question_set?question_set_id=" + set_id;
}

function merge_sets () {
    document.location.href = "merge_question_sets";
}
