if ( result == "success" ) {
    as     = "Standard";
    number = parseInt(number) + 1;
}
else if ( result == "failure" ) {
    if ( as == "Standard" ) {
        as = "Toss-Up";
    }
    else if ( as == "Toss-Up" ) {
        as = "Bonus";
    }
    else if ( as == "Bonus" ) {
        as = "Standard";
    }

    if ( parseInt(number) < 16 ) {
        number = parseInt(number) + 1;
    }
    else if ( number == parseInt(number) ) {
        number = parseInt(number) + "A";
    }
    else if ( number == parseInt(number) + "A" ) {
        number = parseInt(number) + "B";
    }
    else if ( number == parseInt(number) + "B" ) {
        number = parseInt(number) + 1;
    }
}
else if ( result == "none" ) {
    as     = "Standard";
    number = parseInt(number) + 1;
}
