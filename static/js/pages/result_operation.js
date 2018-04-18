// input.
//     number  : Current question number (i.e. "16", "17A")
//     as      : Current question "as" value (i.e. "Standard", "Toss-Up", "Bonus")
//     form    : Type of event (enum: "question", "foul", "timeout", "sub-in", "sub-out", "challenge")
//     result  : Result of current answer (enum: "success", "failure", "none" )
//     quizzer : Text full name of quizzer
//     team    : Text full name of team
//     quiz    : Complex data structure of teams, quizzers, and scores

// output.
//     number  : Next question number (i.e. "16", "17A")
//     as      : Next question "as" value (i.e. "Standard", "Toss-Up", "Bonus")
//     quizzer : Quizzer incremental score value following result
//     team    : Team incremental score value following result
//     label   : Text for the quizzer/question cell scoresheet display
//     message : Optional alert message text (i.e. "Quiz Out")

if ( input.form == "question" ) {
    if ( input.result == "success" ) {
        output.as      = "Standard";
        output.number  = parseInt( input.number ) + 1;
        output.quizzer = 20;
        output.team    = 20;
        output.label   = 20;
    }
    else if ( input.result == "failure" ) {
        if ( input.as == "Standard" ) {
            output.as = "Toss-Up";

            if ( input.result == "success" ) {
                output.quizzer = 20;
                output.team    = 20;
                output.label   = 20;
            }
            else {
                output.quizzer = -10;
                output.team    = -10;
                output.label   = -10;
            }
        }
        else if ( input.as == "Toss-Up" ) {
            if ( input.result == "success" ) {
                output.quizzer = 20;
                output.team    = 20;
                output.label   = 20;
            }
            else {
                output.quizzer = -10;
                output.team    = -10;
                output.label   = -10;
            }

            output.as = "Bonus";
        }
        else if ( input.as == "Bonus" ) {
            if ( input.result == "success" ) {
                output.quizzer = 20;
                output.team    = 20;
                output.label   = "20B";
            }
            else {
                output.label = "BE";
            }

            output.as = "Standard";
        }

        if ( parseInt( input.number ) < 16 ) {
            output.number = parseInt( input.number ) + 1;
        }
        else if ( input.number == parseInt( input.number ) ) {
            output.number = parseInt( input.number ) + "A";
        }
        else if ( input.number == parseInt( input.number ) + "A" ) {
            output.number = parseInt( input.number ) + "B";
        }
        else if ( input.number == parseInt( input.number ) + "B" ) {
            output.number = parseInt( input.number ) + 1;
        }
    }
    else if ( input.result == "none" ) {
        output.as     = "Standard";
        output.number = parseInt( input.number ) + 1;
    }
}
else {
    output.number = input.number;
    output.as     = input.as;
}

if ( input.form == "challenge" ) {
    output.label = ( input.result == "failure" ) ? "C-/" + 100 : "C+";
}

// TODO: flush this out with full event coverage
