// input.
//     number   : Current question number (i.e. "16", "17A")
//     as       : Current question "as" value (i.e. "Standard", "Toss-Up", "Bonus")
//     form     : Type of event
//                (enum "question", "foul", "timeout", "sub-in", "sub-out", "challenge", "team_bonus")
//     result   : Result of current answer (enum "success", "failure", "none" )
//     quizzer  : Quizzer data object (of quizzer for the event)
//     quizzers : Array of quizzer data objects (of all quizzers in the team)
//     team     : Team data object
//     quiz     : Complex data structure of teams, quizzers, and scores

// output.
//     number      : Next question number (i.e. "16", "17A")
//     as          : Next question "as" value (i.e. "Standard", "Toss-Up", "Bonus")
//     quizzer     : Quizzer incremental score value following result
//     team        : Team incremental score value following result
//     label       : Text for the quizzer/question cell scoresheet display
//     skip_counts : Boolean; default false; if true, will skip quizzer counts incrementing
//     message     : Optional alert message text (i.e. "Quiz Out")

var int_number = parseInt( input.number );
output.number  = input.number;
output.as      = input.as;

if ( input.as == "Bonus" ) output.skip_counts = true;

if ( input.form == "question" ) {
    if ( input.result == "success" ) {
        output.as      = "Standard";
        output.number  = int_number + 1;
        output.quizzer = 20;
        output.team    = 20;
        output.label   = 20;

        if ( int_number >= 17 && input.as == "Bonus" ) {
            output.quizzer = 10;
            output.team    = 10;
            output.label   = 10;
        }

        if ( input.as == "Bonus" ) {
            output.label += "B";
        }
        else {
            var quizzers_with_corrects = input.quizzers.filter( function (value) {
                return value.correct > 0;
            } );
            if ( quizzers_with_corrects.length >= 2 && input.quizzer.correct == 0 ) {
                output.team  += 10;
                output.label += "+";
            }
        }
    }
    else if ( input.result == "failure" ) {
        // TODO: verify as good

        if ( input.as == "Standard" ) {
            output.as = "Toss-Up";

            output.quizzer = -10;
            output.team    = -10;
            output.label   = -10;
        }
        else if ( input.as == "Toss-Up" ) {
            output.as = "Bonus";

            output.quizzer = -10;
            output.team    = -10;
            output.label   = -10;
        }
        else if ( input.as == "Bonus" ) {
            output.label = "BE";
            output.as    = "Standard";
        }

        if ( int_number < 16 ) {
            output.number = int_number + 1;
        }
        else if ( input.number == int_number ) {
            output.number = int_number + "A";
        }
        else if ( input.number == int_number + "A" ) {
            output.number = int_number + "B";
        }
        else if ( input.number == int_number + "B" ) {
            output.number = int_number + 1;
        }
    }
    else if ( input.result == "none" ) {
        // TODO: verify as good

        output.as     = "Standard";
        output.number = int_number + 1;
    }
}

else if ( input.form == "foul" ) {
    // TODO: implement
}

else if ( input.form == "timeout" ) {
    // TODO: implement
}

else if ( input.form == "sub-in" ) {
    // TODO: implement
}

else if ( input.form == "sub-out" ) {
    // TODO: implement
}

else if ( input.form == "challenge" ) {
    output.label = ( input.result == "failure" ) ? "C-/" + 100 : "C+";
    // TODO: implement scoring and other?
}

else if ( input.form == "team_bonus" ) {
    // TODO: implement
}

// TODO: 2-team quizzing: initial conditions + OT
