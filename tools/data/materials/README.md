# Materials Creation (Temporary Tools)

These are programs (intended to be temporary) for the creation of materials for
the CBQZ system and stand-alone documents.

*These tools work, but in the future they should be incorporated into the model layer. There may be a command-line tool to access that functionality, though.*

## Creation Process

The process to create materials is as follows:

    ./fetch.pl -b '1 Corinthians' -b '2 Corinthians'
    ./extract.pl -f '*' -o corinthians.csv
    ./markup.pl -i corinthians.csv -o corinthians_marked.csv

For each of these programs/steps, you can query the program for additional information as follows:

    ./fetch --help
    ./fetch --man

Once complete, you'll have a marked-up materials data file (CSV) which should be ready to load in the database via the `~/tools/data/material_load.pl` program. (See the documentation for that program for details.)

## HTML Reference Materials

You can also build a stand-alone reference material HTML document with:

    ./reference.pl -i corinthians_marked.csv -k kvl.csv -o ref.html
