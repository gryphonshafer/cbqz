#!/usr/bin/env perl
use exact;
use Config::App;
use Util::CommandLine qw( options pod2usage );
use Text::Unidecode 'unidecode';
use Text::CSV_XS 'csv';

my $settings = options( qw( input|i=s output|o=s ) );

pod2usage( -message => 'No input file specified' ) unless ( $settings->{input} );
pod2usage( -message => 'No output file specified' ) unless ( $settings->{output} );

die "Unable to read input file\n" unless ( -r $settings->{input} );

my $csv = csv( in => $settings->{input} );
my @headers = map { ucfirst lc unidecode( $_ || '_' ) } @{ shift @$csv };

csv(
    out => $settings->{output},
    in  => [
        map {
            [ @$_{ qw( Type Book Chapter Verse Question Answer ) } ]
        }
        grep {
            $_->{Book} and
            $_->{Chapter} and
            $_->{Verse} and
            $_->{Question}
        }
        map {
            my $row;
            @$row{@headers} = map {
                my $text = unidecode($_);

                $text =~ s/>>//g;
                $text =~ s/&nbsp;/ /g;
                $text =~ s/\s{2,}/ /g;
                $text =~ s/(^\s+|\s+$)//g;

                $text;
            } @$_;
            delete $row->{_};
            $row;
        }
        @$csv
    ],
);

=head1 NAME

csv_clean.pl - "Clean" CSV files prior to import or other uses

=head1 SYNOPSIS

    csv_clean.pl OPTIONS
        -i|input
        -o|output
        -h|help
        -m|man

=head1 DESCRIPTION

This program will "clean" CSV files prior to import or other uses. It does this
by processing the CSV to replace non-ASCII characters and output a
column-correct CSV ready for import or other uses.

Input files should have a CSV header row with the following columns:
Book, Chapter, Verse, Question, Answer, Type.

Output files will not have a CSV header, and their rows will be the following
columns: type, book, chapter, verse, question, answer.
