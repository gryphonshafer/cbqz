// input.
//     number  : Current question number (i.e. "16", "17A")
//     as      : Current question "as" value (i.e. "Standard", "Toss-Up", "Bonus")
//     result  : Result of current answer (enum: "success", "failure", "none" )
//     quizzer : Text full name of quizzer
//     team    : Text full name of team
//     quiz    : Complex data structure of teams, quizzers, and scores

// output.
//     form    : Type of event (enum: "question", "foul", "timeout", "sub-in", "sub-out", "challenge")
//     number  : Next question number (i.e. "16", "17A")
//     as      : Next question "as" value (i.e. "Standard", "Toss-Up", "Bonus")
//     quizzer : Quizzer incremental score value following result
//     team    : Team incremental score value following result
//     message : Optional alert message text (i.e. "Quiz Out")

if ( input.result == "success" ) {
    output.as     = "Standard";
    output.number = parseInt( input.number ) + 1;
}
else if ( input.result == "failure" ) {
    if ( input.as == "Standard" ) {
        output.as = "Toss-Up";
    }
    else if ( input.as == "Toss-Up" ) {
        output.as = "Bonus";
    }
    else if ( input.as == "Bonus" ) {
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
